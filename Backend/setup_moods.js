require("dotenv").config();
const Appwrite = require("node-appwrite");

const client = new Appwrite.Client();
client
    .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Check your endpoint
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Appwrite.Databases(client);

const DATABASE_ID = "68f3c29000072cae03e0";
const MOODS_COLLECTION = "user_moods";

async function setupMoodsSchema() {
    try {
        console.log("🚀 Starting Mood Schema Setup...");

        // --- 1. Create user_moods Collection ---
        try {
            console.log(`Creating collection: ${MOODS_COLLECTION}`);
            await databases.createCollection(
                DATABASE_ID,
                MOODS_COLLECTION,
                "User Moods"
            );
            console.log("✅ Collection created!");
        } catch (e) {
            if (e.code === 409) console.log("⚠️ Collection already exists, skipping creation.");
            else throw e;
        }

        // Add Attributes to user_moods
        console.log(`Adding attributes to ${MOODS_COLLECTION}...`);
        const moodAttributes = [
            () => databases.createStringAttribute(DATABASE_ID, MOODS_COLLECTION, "userId", 255, true),
            () => databases.createStringAttribute(DATABASE_ID, MOODS_COLLECTION, "mood", 255, true), // 'Great', 'Good', 'Okay', 'Not Great', 'Bad'
            () => databases.createStringAttribute(DATABASE_ID, MOODS_COLLECTION, "date", 255, true), // 'YYYY-MM-DD' String
        ];

        for (const addAttr of moodAttributes) {
            try {
                await addAttr();
                console.log("   Added an attribute.");
            } catch (e) {
                if (e.code === 409) console.log("   Attribute already exists.");
                else console.error("   Error adding attribute:", e.message);
            }
        }

        console.log("\n✅ Mood Schema Setup Complete!");

    } catch (error) {
        console.error("❌ Setup failed:", error);
    }
}

setupMoodsSchema();
