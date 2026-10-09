const https = require("https");
const projectId = "sw-gyanmitra-finall2-426-dcc41";
const uid = "stywvieND2f2PfbpMG2MvAC2Ook2";

const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/skillwinner_users/${uid}`;

https.get(url, res => {
  let data = "";
  res.on("data", chunk => data += chunk);
  res.on("end", () => {
    console.log("Status:", res.statusCode);
    console.log("Data:", data);
  });
}).on("error", console.error);
