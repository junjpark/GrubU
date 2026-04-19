const admin = require("firebase-admin");
admin.initializeApp();

const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

exports.validateEduEmail = beforeUserCreated((event) => {
    const user = event.data;
    const email = user.email || '';

    if (!email.endsWith('.edu')) {
        throw new HttpsError(
            'invalid-argument',
            'GrubU requires a valid .edu university email address.'
        );
    }
});

exports.sendOrderNotifications = onDocumentUpdated("orders/{orderId}", async (event) => {
    
    const previousData = event.data.before.data();
    const newData = event.data.after.data();

    if (previousData.status === newData.status) {
        return null;
    }

    const newStatus = newData.status;
    const requesterId = newData.requesterId;
    const fulfillerId = newData.fulfillerId;
    const restaurant = newData.restaurantName;

    let targetUserId = "";
    let title = "";
    let body = "";

    if (newStatus === "ordered") {
        targetUserId = requesterId;
        title = "Food is Ordered!";
        body = `Your fulfiller just placed your order for ${restaurant}.`;
        
    } else if (newStatus === "delivered") {
        targetUserId = requesterId;
        title = "Food has Arrived!";
        body = `Your ${restaurant} order is at the drop-off location. Check the app for the photo!`;
        
    } else if (newStatus === "completed") {
        targetUserId = fulfillerId;
        title = "Order Confirmed!";
        body = `The requester confirmed they received the food. Great job!`;

        if (fulfillerId) {
            const bounty = newData.bountyAmount || 0;
            await admin.firestore().collection("users").doc(fulfillerId).update({
                completedOrders: admin.firestore.FieldValue.increment(1),
                usdBalance: admin.firestore.FieldValue.increment(bounty),
            });
        }
    } else {
        return null;
    }

    try {
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        
        if (!userDoc.exists) {
            console.log(`User ${targetUserId} does not exist in the database.`);
            return null;
        }

        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) {
            console.log(`No push token for user ${targetUserId}, aborting.`);
            return null;
        }

        const payload = {
            notification: {
                title: title,
                body: body,
            },
            token: fcmToken
        };

        await admin.messaging().send(payload);
        console.log("Notification sent successfully to", targetUserId);

    } catch (error) {
        console.error("Error sending notification:", error);
    }
    
    return null;
});

//Stripe setup
exports.createStripeCustomer = onCall(
    { secrets: [stripeSecretKey] },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Must be signed in.");
        }

        const stripe = require("stripe")(stripeSecretKey.value());
        const uid = request.auth.uid;
        const email = request.auth.token.email;

        const customer = await stripe.customers.create({
            email,
            metadata: { firebaseUID: uid },
        });

        await admin.firestore().collection("users").doc(uid).update({
            stripeCustomerId: customer.id,
        });

        return { customerId: customer.id };
    }
);

exports.createConnectAccount = onCall(
    { secrets: [stripeSecretKey] },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Must be signed in.");
        }

        const stripe = require("stripe")(stripeSecretKey.value());
        const uid = request.auth.uid;
        const email = request.auth.token.email;

        const account = await stripe.accounts.create({
            type: "express",
            email,
            metadata: { firebaseUID: uid },
            capabilities: {
                transfers: { requested: true },
            },
        });

        await admin.firestore().collection("users").doc(uid).update({
            stripeConnectAccountId: account.id,
        });

        const accountLink = await stripe.accountLinks.create({
            account: account.id,
            refresh_url: "https://grubu-5710a.web.app/stripe-refresh",
            return_url: "https://grubu-5710a.web.app/stripe-return",
            type: "account_onboarding",
        });

        return { url: accountLink.url, accountId: account.id };
    }
);

exports.createPaymentIntent = onCall(
    { secrets: [stripeSecretKey] },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Must be signed in.");
        }

        const stripe = require("stripe")(stripeSecretKey.value());
        const uid = request.auth.uid;
        const { amount } = request.data;

        if (!amount || amount <= 0) {
            throw new HttpsError("invalid-argument", "Amount must be a positive integer (cents).");
        }

        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", "User document not found.");
        }

        let stripeCustomerId = userDoc.data().stripeCustomerId;

        if (!stripeCustomerId) {
            const customer = await stripe.customers.create({
                email: request.auth.token.email,
                metadata: { firebaseUID: uid },
            });
            stripeCustomerId = customer.id;
            await admin.firestore().collection("users").doc(uid).update({ stripeCustomerId });
        }

        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: stripeCustomerId },
            { apiVersion: "2025-03-31.basil" }
        );

        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency: "usd",
            customer: stripeCustomerId,
            automatic_payment_methods: { enabled: true },
            metadata: { requesterId: uid },
        });

        return {
            paymentIntent: paymentIntent.client_secret,
            ephemeralKey: ephemeralKey.secret,
            customer: stripeCustomerId,
            publishableKey: "pk_test_51TMtPm2NiUAopVrwVBwS1YzVD61cskrrKFtfwLSfeVB5vPANUAbLU8KvZ3F1OWy9eOEblnZ8tEhhHvdqOqt4UNMY00YP4KSM41",
        };
    }
);

exports.payoutFulfiller = onCall(
    { secrets: [stripeSecretKey] },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Must be signed in.");
        }

        const stripe = require("stripe")(stripeSecretKey.value());
        const { orderId } = request.data;

        if (!orderId) {
            throw new HttpsError("invalid-argument", "orderId is required.");
        }

        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
            throw new HttpsError("not-found", "Order not found.");
        }

        const order = orderDoc.data();

        if (order.requesterId !== request.auth.uid) {
            throw new HttpsError("permission-denied", "Only the requester can trigger payout.");
        }

        if (!order.fulfillerId) {
            throw new HttpsError("failed-precondition", "No fulfiller assigned to this order.");
        }

        const fulfillerDoc = await admin.firestore()
            .collection("users").doc(order.fulfillerId).get();

        if (!fulfillerDoc.exists) {
            throw new HttpsError("not-found", "Fulfiller user not found.");
        }

        const connectAccountId = fulfillerDoc.data().stripeConnectAccountId;
        if (!connectAccountId) {
            throw new HttpsError("failed-precondition", "Fulfiller has no connected Stripe account.");
        }

        const bountyInCents = Math.round(order.bountyAmount * 100);

        const transfer = await stripe.transfers.create({
            amount: bountyInCents,
            currency: "usd",
            destination: connectAccountId,
            metadata: { orderId },
        });

        return { transferId: transfer.id };
    }
);
