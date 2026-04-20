const admin = require("firebase-admin");
admin.initializeApp();

const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
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

        const db = admin.firestore();

        const bumpCompleted = async (uid) => {
            if (!uid || typeof uid !== "string" || uid.length === 0) return;
            try {
                await db.collection("users").doc(uid).set(
                    { completedOrders: admin.firestore.FieldValue.increment(1) },
                    { merge: true }
                );
            } catch (e) {
                console.error("bumpCompleted failed for", uid, e);
            }
        };

        const rid = typeof requesterId === "string" && requesterId.length > 0 ? requesterId : null;
        const fid = typeof fulfillerId === "string" && fulfillerId.length > 0 ? fulfillerId : null;

        if (rid && fid && rid === fid) {
            await bumpCompleted(rid);
        } else {
            if (rid) await bumpCompleted(rid);
            if (fid && fid !== rid) await bumpCompleted(fid);
        }
    } else {
        return null;
    }

    try {
        if (!targetUserId || typeof targetUserId !== "string" || targetUserId.length === 0) {
            console.log("sendOrderNotifications: missing targetUserId, skipping push.");
            return null;
        }

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

/**
 * Requesters can update fulfillerRating on their order, but Firestore rules
 * typically block them from writing another user's profile. Aggregate here.
 */
exports.syncFulfillerRatingFromOrder = onDocumentUpdated("orders/{orderId}", async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const prevRating = before.fulfillerRating;
    const nextRating = after.fulfillerRating;

    if (nextRating === undefined || nextRating === null) {
        return null;
    }
    if (prevRating === nextRating) {
        return null;
    }

    const fulfillerId = after.fulfillerId;
    if (!fulfillerId || typeof fulfillerId !== "string" || fulfillerId.length === 0) {
        return null;
    }

    const toNumber = (v) => {
        if (typeof v === "number" && !Number.isNaN(v)) return v;
        if (typeof v === "string" && v.trim() !== "" && !Number.isNaN(Number(v))) return Number(v);
        return null;
    };

    const db = admin.firestore();
    const userRef = db.collection("users").doc(fulfillerId);

    try {
        const qs = await db.collection("orders")
            .where("fulfillerId", "==", fulfillerId)
            .get();

        let sum = 0;
        let count = 0;
        qs.forEach((doc) => {
            const r = doc.data().fulfillerRating;
            if (r === undefined || r === null) return;
            const n = toNumber(r);
            if (n === null || Number.isNaN(n)) return;
            sum += n;
            count += 1;
        });

        if (count === 0) {
            await userRef.set(
                {
                    rating: admin.firestore.FieldValue.delete(),
                    totalRatingsReceived: 0,
                },
                { merge: true }
            );
        } else {
            await userRef.set(
                {
                    rating: sum / count,
                    totalRatingsReceived: count,
                },
                { merge: true }
            );
        }
    } catch (e) {
        console.error("syncFulfillerRatingFromOrder:", e);
    }

    return null;
});

/**
 * Fires every time the app writes a new support ticket to `issueReports`.
 * Today it just logs a structured summary (visible in Firebase Functions
 * logs) so the team has an easy feed to monitor; extend this to push to
 * Slack, email via SendGrid, or the Firebase "Trigger Email" extension.
 */
exports.onIssueReportCreated = onDocumentCreated("issueReports/{reportId}", async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const report = snap.data() || {};
    const reportId = event.params.reportId;

    console.log("New GrubU issue report:", {
        reportId,
        orderId: report.orderId,
        reporterUid: report.reporterUid,
        reporterRole: report.reporterRole,
        reporterEmail: report.reporterEmail,
        orderStatusAtReport: report.orderStatusAtReport,
        description: report.description,
    });

    // TODO: wire outbound notification of your choice, e.g.:
    //
    //   await fetch(SLACK_WEBHOOK, {
    //     method: "POST",
    //     body: JSON.stringify({
    //       text: `:rotating_light: New GrubU issue on order ${report.orderId}\n${report.description}`
    //     })
    //   });
    //
    // or write to the "Trigger Email" extension's `mail` collection:
    //
    //   await admin.firestore().collection("mail").add({
    //     to: "support@grubu.app",
    //     message: {
    //       subject: `New GrubU issue on order ${report.orderId}`,
    //       text: report.description,
    //     },
    //   });

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
