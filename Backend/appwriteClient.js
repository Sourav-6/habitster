const Appwrite = require("node-appwrite");

const client = new Appwrite.Client();

client
  .setEndpoint("https://nyc.cloud.appwrite.io/v1")
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

module.exports = client;
