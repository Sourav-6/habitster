require("dotenv").config();
const Appwrite = require("node-appwrite");

const client = new Appwrite.Client();
client
    .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Check your endpoint
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Appwrite.Databases(client);

const DATABASE_ID = "68f3c29000072cae03e0";
// Collection IDs we want to create
const COLLECTIONS = {
    USER_PROFILES: "user_profiles",
    USER_BADGES: "user_badges",
};
const EXISTING_COLLECTIONS = {
    HABITS: "habits-storage"
}

async function setupGamificationSchema() {
    try {
        console.log("🚀 Starting Gamification Schema Setup...");

        // --- 1. Create user_profiles Collection ---
        try {
            console.log(`Creating collection: ${COLLECTIONS.USER_PROFILES}`);
            await databases.createCollection(
                DATABASE_ID,
                COLLECTIONS.USER_PROFILES,
                "User Profiles"
            );
            console.log("✅ Collection created!");
        } catch (e) {
            if (e.code === 409) console.log("⚠️ Collection already exists, skipping creation.");
            else throw e;
        }

        // Add Attributes to user_profiles
        console.log(`Adding attributes to ${COLLECTIONS.USER_PROFILES}...`);
        const profileAttributes = [
            () => databases.createStringAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "userId", 255, true),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "xp", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "level", false, 1, 1000, 1),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "streakFreezeTokens", false, 0, 1000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "avatarEnergy", false, 0, 100, 100),
            // Skill Tree
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "healthXp", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "productivityXp", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "mindfulnessXp", false, 0, 1000000, 0),
            () => databases.createIntegerAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "learningXp", false, 0, 1000000, 0),
            () => databases.createStringAttribute(DATABASE_ID, COLLECTIONS.USER_PROFILES, "equippedAvatar", 255, false, "default_avatar"),
        ];

        for (const addAttr of profileAttributes) {
            try {
                await addAttr();
                console.log("   Added an attribute.");
            } catch (e) {
                if (e.code === 409) console.log("   Attribute already exists.");
                else console.error("   Error adding attribute:", e.message);
            }
        }

        // --- 2. Create user_badges Collection ---
        try {
            console.log(`\nCreating collection: ${COLLECTIONS.USER_BADGES}`);
            await databases.createCollection(
                DATABASE_ID,
                COLLECTIONS.USER_BADGES,
                "User Badges"
            );
            console.log("✅ Collection created!");
        } catch (e) {
            if (e.code === 409) console.log("⚠️ Collection already exists, skipping creation.");
            else throw e;
        }

        console.log(`Adding attributes to ${COLLECTIONS.USER_BADGES}...`);
        const badgeAttributes = [
            () => databases.createStringAttribute(DATABASE_ID, COLLECTIONS.USER_BADGES, "userId", 255, true),
            () => databases.createStringAttribute(DATABASE_ID, COLLECTIONS.USER_BADGES, "badgeId", 255, true),
            () => databases.createStringAttribute(DATABASE_ID, COLLECTIONS.USER_BADGES, "badgeName", 255, true),
            () => databases.createDatetimeAttribute(DATABASE_ID, COLLECTIONS.USER_BADGES, "dateEarned", true),
        ];

        for (const addAttr of badgeAttributes) {
            try {
                await addAttr();
                console.log("   Added an attribute.");
            } catch (e) {
                if (e.code === 409) console.log("   Attribute already exists.");
                else console.error("   Error adding attribute:", e.message);
            }
        }

        // --- 3. Update habits-storage Collection ---
        console.log(`\nAdding gamification attributes to existing collection: ${EXISTING_COLLECTIONS.HABITS}...`);
        const habitAttributes = [
            () => databases.createStringAttribute(DATABASE_ID, EXISTING_COLLECTIONS.HABITS, "difficulty", 255, false, "Medium"),
            () => databases.createStringAttribute(DATABASE_ID, EXISTING_COLLECTIONS.HABITS, "category", 255, false, "Productivity"),
        ];

        for (const addAttr of habitAttributes) {
            try {
                await addAttr();
                console.log("   Added an attribute.");
            } catch (e) {
                if (e.code === 409) console.log("   Attribute already exists.");
                else console.error("   Error adding attribute:", e.message);
            }
        }


        console.log("\n✅ Gamification Schema Setup Complete!");
        console.log("Wait approximately 30-60 seconds for Appwrite to fully provision the attributes before starting the backend.");

    } catch (error) {
        console.error("❌ Setup failed:", error);
    }
}

setupGamificationSchema();
