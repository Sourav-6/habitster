require("dotenv").config();
const Appwrite = require("node-appwrite");

const client = new Appwrite.Client();
client
    .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Check your endpoint
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Appwrite.Databases(client);

const DATABASE_ID = "68f3c29000072cae03e0";
const HABITS_COLLECTION_ID = "habits-storage";

async function setupFavoriteSchema() {
    try {
        console.log("🚀 Starting Favorite Schema Setup...");

        // Add Attribute
        console.log(`Adding isFavorite to ${HABITS_COLLECTION_ID}...`);

        try {
            await databases.createBooleanAttribute(
                DATABASE_ID,
                HABITS_COLLECTION_ID,
                "isFavorite",
                false, // Required?
                false // Default
            );
            console.log("✅ Added isFavorite attribute.");
        } catch (e) {
            if (e.code === 409) console.log("✅ Attribute isFavorite already exists.");
            else console.error("❌ Error adding attribute:", e.message);
        }

        console.log("\n✅ Favorite Schema Setup Complete. Please wait ~5-10 seconds for Appwrite to provision the attribute before testing in the app.");

    } catch (error) {
        console.error("❌ Setup failed:", error);
    }
}

setupFavoriteSchema();
