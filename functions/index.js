const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { HttpsError } = require("firebase-functions/v2/https");

exports.validateEduEmail = beforeUserCreated((event) => {
    // In V2, the user data is attached to event.data
    const user = event.data;
    const email = user.email || '';

    // Require .edu
    if (!email.endsWith('.edu')) {
        throw new HttpsError(
            'invalid-argument',
            'GrubU requires a valid .edu university email address.'
        );
    }
});