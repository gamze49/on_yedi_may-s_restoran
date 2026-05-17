const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createUserAccount = onCall(
{ region: "us-central1" },

async (request) => {

const data = request.data;

const ad = data.ad;
const role = data.role;
const email = data.email;
const sifre = data.sifre;

try {

const userRecord = await admin.auth().createUser({
email: email,
password: sifre
});

await admin.firestore()
.collection("kullanici")
.doc(userRecord.uid)
.set({
ad: ad,
role: role,
email: email,
uid: userRecord.uid,
olusturmaTarihi: admin.firestore.FieldValue.serverTimestamp()
});

return {
message:"Personel eklendi"
};

}
catch(error){

console.error(error);

throw new HttpsError(
"internal",
error.message
);

}

}
);

exports.deleteUserAccount = onCall(
{ region:"us-central1" },

async (request) => {

const targetUid = request.data.uid;

try {

await admin.auth().deleteUser(targetUid);

await admin.firestore()
.collection("kullanici")
.doc(targetUid)
.delete();

return {
message:"Başarıyla silindi"
};

}
catch(error){

console.error(error);

throw new HttpsError(
"internal",
error.message
);

}

}
);