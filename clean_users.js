const https = require("https");
const projectId = "sw-gyanmitra-finall2-426-dcc41";

async function fetchUsers() {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/skillwinner_users?pageSize=100`;
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on("error", reject);
  });
}

function deleteDoc(docPath) {
  const url = `https://firestore.googleapis.com/v1/${docPath}`;
  return new Promise((resolve, reject) => {
    const req = https.request(url, { method: "DELETE" }, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => resolve({ status: res.statusCode, body: data }));
    });
    req.on("error", reject);
    req.end();
  });
}

function updateAdminRole(uid) {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/skillwinner_users/${uid}?updateMask.fieldPaths=role`;
  const body = JSON.stringify({
    fields: {
      role: { stringValue: "admin" }
    }
  });
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body)
      }
    }, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => resolve({ status: res.statusCode, body: data }));
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

async function run() {
  const result = await fetchUsers();
  const docs = result.documents || [];
  
  for (const d of docs) {
    const docPath = d.name;
    const uid = docPath.split("/").pop();
    const fields = d.fields || {};
    const email = fields.email ? (fields.email.stringValue || "") : "";
    
    if (email.toLowerCase() === "swgayanbhumi@swgayanbhumi.in" || uid === "VaIWQoaTJKSxEC39rCVXKZYmpa22") {
      console.log(`Setting role: admin for ${email} (${uid})...`);
      await updateAdminRole(uid);
      console.log(`Admin role updated!`);
      continue;
    }
    
    if (email.toLowerCase() === "samashermaurya9935@gmail.com" || uid === "IejDwJjjrnQZl6Fey430YFgtIiI3") {
      console.log(`Keeping admin: ${email}`);
      continue;
    }
    
    console.log(`Deleting user: ${uid} (${email})...`);
    await deleteDoc(docPath);
  }
  
  console.log("Done!");
}

run().catch(console.error);
