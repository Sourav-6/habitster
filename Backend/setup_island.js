require("dotenv").config();
const Appwrite = require("node-appwrite");

const client = new Appwrite.Client();
client
    .setEndpoint("https://nyc.cloud.appwrite.io/v1")
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Appwrite.Databases(client);

const DATABASE_ID = "68f3c29000072cae03e0";
const ISLAND_COLLECTION = "user_islands";

async function setupIslandSchema() {
    try {
        console.log("🚀 Starting Island Schema Setup...");

        // --- 1. Create user_islands Collection ---
        try {
            console.log(`Creating collection: \${ISLAND_COLLECTION}`);
            await databases.createCollection(
                DATABASE_ID,
                ISLAND_COLLECTION,
                "User Islands"
            );
            console.log("✅ Collection created!");
        } catch (e) {
            if (e.code === 409) console.log("⚠️ Collection already exists, skipping creation.");
            else throw e;
        }

        // Add Attributes
        console.log(`Adding attributes to \${ISLAND_COLLECTION}...`);
        const islandAttributes = [
            () => databases.createStringAttribute(DATABASE_ID, ISLAND_COLLECTION, "userId", 255, true),
            () => databases.createIntegerAttribute(DATABASE_ID, ISLAND_COLLECTION, "trees", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, ISLAND_COLLECTION, "houses", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, ISLAND_COLLECTION, "unlockedAreas", false, 0, 100, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, ISLAND_COLLECTION, "decayLevel", false, 0, 100, 0),
        ];

        for (const addAttr of islandAttributes) {
            try {
                await addAttr();
                console.log("   Added an attribute.");
            } catch (e) {
                if (e.code === 409) console.log("   Attribute already exists.");
                else console.error("   Error adding attribute:", e.message);
            }
        }

        console.log("\\n✅ Island Schema Setup Complete!");

    } catch (error) {
        console.error("❌ Setup failed:", error);
    }
}

setupIslandSchema();
