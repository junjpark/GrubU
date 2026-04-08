const admin = require("firebase-admin");
admin.initializeApp();

const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

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
