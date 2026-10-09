const https = require("https");
const projectId = "sw-gyanmitra-finall2-426-dcc41";

["skillwinner_users", "users"].forEach(col => {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${col}?pageSize=100`;
  https.get(url, res => {
    let data = "";
    res.on("data", chunk => data += chunk);
    res.on("end", () => {
      try {
        const json = JSON.parse(data);
        const docs = json.documents || [];
        console.log(`[COLLECTION: ${col}] Remaining count: ${docs.length}`);
        docs.forEach(d => {
          const uid = d.name.split("/").pop();
          const email = d.fields && d.fields.email ? d.fields.email.stringValue : "no email";
          const role = d.fields && d.fields.role ? d.fields.role.stringValue : "user";
          console.log(` - ${uid} (${email}) [Role: ${role}]`);
        });
      } catch (e) {
        console.error(e);
      }
    });
  });
});
