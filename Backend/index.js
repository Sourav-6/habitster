const express = require("express");
const cookieParser = require("cookie-parser");
const app = express();
app.use(cookieParser());
const passport = require("passport");
const GoogleStrategy = require("passport-google-oauth20").Strategy;
const PORT = process.env.PORT || 3000;
const jwt = require("jsonwebtoken");
app.use(passport.initialize());
const authMiddleware = require("./middleware/authMiddleware");
// NEW: Import dotenv to read .env file
require("dotenv").config();

// NEW: Import Appwrite SDK
const Appwrite = require("node-appwrite");
const habitAgent = require("./agent/habitAgent");

// NEW: Initialize the Appwrite Client
const client = new Appwrite.Client();
client
  .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Appwrite Endpoint
  .setProject(process.env.APPWRITE_PROJECT_ID) // Your Project ID from .env
  .setKey(process.env.APPWRITE_API_KEY); // Your API Key from .env
// NEW: Create an instance of the Users API
const account = new Appwrite.Account(client);
const users = new Appwrite.Users(client);
const { nanoid } = require("nanoid");

const databases = new Appwrite.Databases(client);

function calculateNextDueDate(lastDueDate, frequencyType, frequencyValue) {
  let nextDate = new Date(lastDueDate); // Start from the last due date
  // Set time to beginning of the day for consistent calculation
  nextDate.setUTCHours(0, 0, 0, 0);

  switch (frequencyType) {
    case "daily":
      nextDate.setUTCDate(nextDate.getUTCDate() + 1);
      break;
    case "every_x_days":
      const daysToAdd = parseInt(frequencyValue, 10);
      if (!isNaN(daysToAdd) && daysToAdd > 0) {
        nextDate.setUTCDate(nextDate.getUTCDate() + daysToAdd);
      } else {
        nextDate.setUTCDate(nextDate.getUTCDate() + 1); // Fallback
      }
      break;
    case "specific_days":
      try {
        // Parse the JSON array like "[1,3,5]"
        const scheduledWeekdays = JSON.parse(frequencyValue || "[]").map(
          Number
        );
        if (scheduledWeekdays.length === 0) {
          nextDate.setUTCDate(nextDate.getUTCDate() + 1); // Fallback if no days selected
          break;
        }
        // Sort the selected days [1, 2, 3, 4, 5, 6, 7] (JS Sunday=0, Monday=1...)
        // Appwrite/Dart use Monday=1..Sunday=7. JS uses Sunday=0..Saturday=6. Adjust!
        const scheduledJsWeekdays = scheduledWeekdays
          .map((d) => d % 7)
          .sort((a, b) => a - b); // Convert 7 (Sun) to 0

        let currentJsWeekday = nextDate.getUTCDay(); // Sunday=0, Saturday=6

        // Start checking from the *day after* the last due date
        nextDate.setUTCDate(nextDate.getUTCDate() + 1);
        currentJsWeekday = nextDate.getUTCDay();

        // Loop until we find the next scheduled day
        while (true) {
          if (scheduledJsWeekdays.includes(currentJsWeekday)) {
            break; // Found the next scheduled day
          }
          // Advance to the next day
          nextDate.setUTCDate(nextDate.getUTCDate() + 1);
          currentJsWeekday = nextDate.getUTCDay();
        }
      } catch (e) {
        console.error("Error calculating next specific day:", e);
        nextDate.setUTCDate(nextDate.getUTCDate() + 1); // Fallback
      }
      break;
    default:
      nextDate.setUTCDate(nextDate.getUTCDate() + 1); // Fallback
  }
  return nextDate;
}
// --- End Helper Function ---

// --- Passport Google OAuth Setup ---

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: "http://localhost:3000/auth/google/callback",
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails[0].value;
        const name = profile.displayName;
        let userId;

        // 1. Check if user exists in Appwrite
        try {
          const userList = await users.list([Appwrite.Query.equal("email", email)]);
          if (userList.total > 0) {
            userId = userList.users[0].$id;
            console.log("Found existing Google user in Appwrite:", userId);
          } else {
            // 2. Create new user if not found
            const newUser = await users.create(
              Appwrite.ID.unique(),
              email,
              undefined,
              undefined, // Password not needed for OAuth
              name
            );
            userId = newUser.$id;
            console.log("Created new Google user in Appwrite:", userId);
          }
        } catch (authErr) {
          console.error("Appwrite Auth error during Google login:", authErr);
          return done(authErr);
        }

        // 3. Ensure User Profile exists
        try {
          await databases.getDocument(DATABASE_ID, USER_PROFILES_COLLECTION_ID, userId);
        } catch (profileErr) {
          if (profileErr.code === 404) {
            console.log("Creating new profile for Google user:", userId);
            try {
              const todayStr = new Date().toISOString().split('T')[0];
              await databases.createDocument(
                DATABASE_ID,
                USER_PROFILES_COLLECTION_ID,
                userId,
                {
                  userId: userId,
                  name: name,
                  xp: 0,
                  level: 1,
                  streakFreezeTokens: 0,
                  avatarEnergy: 100,
                  lastHabitCompletionDate: todayStr,
                  healthXp: 0,
                  productivityXp: 0,
                  mindfulnessXp: 0,
                  learningXp: 0,
                  equippedAvatar: "default_avatar"
                }
              );
            } catch (createErr) {
              console.error("Failed to create profile for Google user:", createErr);
            }
          }
        }

        const user = {
          userId: userId,
          email: email,
          name: name,
        };
        done(null, user);
      } catch (e) {
        console.error("Google Strategy Error:", e);
        done(e);
      }
    }
  )
);

// NEW: Store your Database and Collection IDs (Get these from Appwrite!)
const DATABASE_ID = "68f3c29000072cae03e0";
const TASKS_COLLECTION_ID = "tasks-storage";
const HABITS_COLLECTION_ID = "habits-storage";
const SUBTASKS_COLLECTION_ID = "subtasks-storage";
const HABIT_HISTORY_COLLECTION_ID = "habithistory";
// GAMIFICATION
const USER_PROFILES_COLLECTION_ID = "user_profiles_";
const USER_BADGES_COLLECTION_ID = "user_badges";


// --- Middleware ---
app.use(express.json());

// --- Routes ---
app.get("/", (req, res) => {
  res.send("Habitster API is running 🚀");
});

// --- API Endpoints ---
// We will update these next to use Appwrite
app.post("/api/auth/register", async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required." });
    }

    // 1. Create user in Appwrite Auth (userId, email, phone, password, name)
    const newUser = await users.create(
      Appwrite.ID.unique(), // Let Appwrite generate a proper unique ID
      email,
      undefined, // phone (not used)
      password,
      name || email.split('@')[0], // Use name or fallback to email prefix
    );

    console.log("Successfully created user:", newUser.$id);

    // 2. Initialize the gamification profile using the userId as document ID
    // This is CRITICAL: must match what getDocument(userId) looks up later
    const todayStr = new Date().toISOString().split('T')[0];
    await databases.createDocument(
      DATABASE_ID,
      USER_PROFILES_COLLECTION_ID,
      newUser.$id,  // ← FIXED: Use userId as document ID, not a random ID
      {
        userId: newUser.$id,
        xp: 0,
        level: 1,
        streakFreezeTokens: 0,
        avatarEnergy: 100,
        lastHabitCompletionDate: todayStr, // Prevent immediate energy drain
        healthXp: 0,
        productivityXp: 0,
        mindfulnessXp: 0,
        learningXp: 0,
        equippedAvatar: "default_avatar"
      }
    );
    console.log("Successfully initialized user profile for:", newUser.$id);

    res.status(201).json({
      message: "User registered successfully!",
      userId: newUser.$id,
    });
  } catch (error) {
    console.error("Error creating user/profile:", error);
    // Provide user-friendly error messages
    let message = "Failed to register user";
    if (error.code === 409) message = "An account with this email already exists.";
    else if (error.code === 400) message = "Invalid email or password format.";
    res.status(error.code === 409 ? 409 : 500).json({
      message,
      error: error.message,
    });
  }
});

// AI Agent chat Endpoints....

app.post("/api/agent/chat", authMiddleware, async (req, res) => {
  console.log("AI CHAT HIT:", req.body);
  try {
    const { message } = req.body;
    const reply = await habitAgent.processMessage(req.userId, message);
    res.status(200).json({ reply });
  } catch (e) {
    console.error("AGENT ERROR:", e);
    res.status(500).json({
      message: "Agent error",
      error: e.message,
    });
  }
});

// Proactive intervention endpoint...

app.get("/api/agent/proactive", authMiddleware, async (req, res) => {
  try {
    const msg = await habitAgent.autoIntervene(req.userId);
    if (!msg) return res.status(204).send();
    res.json({ message: msg });
  } catch (e) {
    res.status(500).json({ message: "Proactive agent error" });
  }
});

// UPDATED Login Endpoint (Generates JWT)
app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Create Appwrite session (verify credentials)
    const session = await account.createEmailPasswordSession(email, password);
    console.log("Successfully created Appwrite session:", session.$id);

    // 2. Prepare JWT Payload (data to store in the token)
    const payload = {
      userId: session.userId, // Store the Appwrite User ID
      // You could add other non-sensitive info like email if needed
    };

    // 3. Generate the JWT
    const token = jwt.sign(
      payload,
      process.env.JWT_SECRET, // Use the secret from .env
      { expiresIn: "1d" } // Token expiration time (e.g., 1 day, '7d', '1h')
    );

    console.log("Generated JWT for user:", session.userId);

    // 4. Send the JWT back to the Flutter app
    res.status(200).json({
      message: "User logged in successfully!",
      token: token, // Send the token
      userId: session.userId, // Still useful to send userId directly too
    });
  } catch (error) {
    console.error("Error logging in:", error);
    const statusCode = error.code === 401 ? 401 : 500;
    res.status(statusCode).json({
      message: "Failed to log in",
      error: error.message || "Invalid email or password",
    });
  }
});

// Google OAuth Routes

app.get(
  "/auth/google",
  passport.authenticate("google", { scope: ["profile", "email"] })
);

// Google OAuth Callback Route

app.get(
  "/auth/google/callback",
  passport.authenticate("google", { session: false }),
  (req, res) => {
    const token = jwt.sign(
      {
        userId: req.user.userId,
        email: req.user.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    // 🔥 Redirect back to Flutter app
    res.redirect(`habitster://auth?token=${token}`);
  }
);

// Check Google Auth Status Endpoint
app.get("/auth/google/success", (req, res) => {
  const token = req.cookies?.habitster_token;

  if (!token) {
    return res.status(200).json({ loggedIn: false });
  }

  res.status(200).json({
    loggedIn: true,
    token,
  });
});


// NEW: Create Task Endpoint
app.post("/api/tasks", authMiddleware, async (req, res) => {
  try {
    // We'll need the user ID later to link the task
    // For now, let's assume we get it from the request (e.g., after verifying a token)
    // const userId = req.user.id; // Placeholder for authenticated user ID

    // --- TEMPORARY USER ID FOR TESTING ---
    // Replace this with a real user ID from your Appwrite Auth dashboard
    const userId = req.userId;
    // --- END TEMPORARY ---

    const {
      taskName,
      note,
      dueDate,
      priority,
      label,
      isRecurring,
      recurrenceDays,
    } = req.body;

    // Basic validation
    if (!taskName || !dueDate) {
      return res
        .status(400)
        .json({ message: "Task name and due date are required." });
    }

    const newTaskDocument = await databases.createDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      Appwrite.ID.unique(), // Let Appwrite generate a unique ID for the task document
      {
        taskName,
        note: note ?? null, // Use null if not provided
        dueDate: new Date(dueDate).toISOString(), // Ensure it's in ISO format
        priority: priority ?? 0,
        label: label ?? null,
        isRecurring: isRecurring ?? false,
        recurrenceDays: recurrenceDays ?? null,
        userId: userId, // Link to the user
      }
    );

    console.log("Successfully created task:", newTaskDocument);
    res.status(201).json(newTaskDocument); // Send the created task back
  } catch (error) {
    console.error("Error creating task:", error);
    res.status(500).json({
      message: "Failed to create task",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// NEW: Get Tasks Endpoint
app.get("/api/tasks", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    // Return ALL tasks for the user — active/completed split is handled client-side
    // (avoids needing an Appwrite index on isCompleted)
    const response = await databases.listDocuments(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.orderDesc("$createdAt"),
      ]
    );

    console.log("Successfully fetched tasks for user:", userId);
    res.status(200).json(response.documents);
  } catch (error) {
    console.error("Error fetching tasks:", error);
    res.status(500).json({
      message: "Failed to fetch tasks",
      error: error.message || JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});


app.delete("/api/tasks/:taskId", authMiddleware, async (req, res) => {
  try {
    const { taskId } = req.params;
    const userId = req.userId;

    // Verify task ownership
    const task = await databases.getDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      taskId
    );
    if (task.userId !== userId) {
      return res.status(403).json({ message: "Forbidden: You do not own this task" });
    }

    // Mark as completed instead of deleting (so it persists in the completed section)
    await databases.updateDocument(DATABASE_ID, TASKS_COLLECTION_ID, taskId, {
      isCompleted: true,
    });

    console.log("Task marked as completed:", taskId);
    res.status(204).send();
  } catch (error) {
    console.error("Error completing task:", error);
    res.status(500).json({
      message: "Failed to complete task",
      error: error.message || JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});


// NEW: Update Task Endpoint (for completing recurring tasks)
app.put("/api/tasks/:taskId", authMiddleware, async (req, res) => {
  try {
    const { taskId } = req.params;
    const updateData = req.body;
    const userId = req.userId; // Get updates from request body (e.g., new dueDate)

    const task = await databases.getDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      taskId
    );
    if (task.userId !== userId) {
      console.warn(
        `User ${userId} attempted to update task ${taskId} owned by ${task.userId}`
      );
      return res
        .status(403)
        .json({ message: "Forbidden: You do not own this task" });
    }

    // We only expect specific fields for updates (like dueDate for recurrence)
    // You might want more validation here in a real app
    if (!updateData.dueDate) {
      return res.status(400).json({
        message: "Only dueDate updates are currently supported for recurrence.",
      });
    }

    const updatedDocument = await databases.updateDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      taskId,
      {
        // Only send the fields we want to update
        dueDate: new Date(updateData.dueDate).toISOString(),
      }
    );

    console.log("Successfully updated task:", taskId);
    res.status(200).json(updatedDocument);
  } catch (error) {
    console.error("Error updating task:", error);
    res.status(500).json({
      message: "Failed to update task",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// Create Habit Endpoint
app.post("/api/habits", authMiddleware, async (req, res) => {
  // Use authMiddleware
  try {
    const userId = req.userId; // Get user ID from authenticated token
    const {
      habitName,
      startDate, // Expect ISO 8601 string e.g., "2025-10-20T00:00:00.000Z"
      durationValue, // e.g., 3
      durationUnit, // e.g., "months"
      frequencyType, // e.g., "every_x_days"
      frequencyValue, // e.g., "2" or "[1,3,5]"
      // GAMIFICATION
      difficulty,
      category
    } = req.body;

    // Basic Validation
    if (
      !habitName ||
      !startDate ||
      !durationValue ||
      !durationUnit ||
      !frequencyType
    ) {
      return res
        .status(400)
        .json({ message: "Missing required habit fields." });
    }
    // Add more specific validation later if needed (e.g., durationUnit, frequencyType)

    // Calculate initial nextDueDate based on startDate and frequency
    let initialNextDueDate = new Date(startDate);
    // Add logic here later if frequency isn't daily (e.g., for 'every_x_days')

    const newHabitDocument = await databases.createDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      Appwrite.ID.unique(), // Let Appwrite generate document ID
      {
        userId,
        habitName,
        startDate: new Date(startDate).toISOString(),
        durationValue,
        durationUnit,
        frequencyType,
        frequencyValue: frequencyValue ?? null, // Store as string or null
        currentStreak: 0, // Initialize streaks
        longestStreak: 0,
        lastCompletedDate: null,
        nextDueDate: initialNextDueDate.toISOString(), // Set initial due date
        isHidden: false, // Default
        // GAMIFICATION
        difficulty: difficulty || "Medium",
        category: category || "Productivity"
      }
    );

    console.log("Successfully created habit:", newHabitDocument["$id"]);
    res.status(201).json(newHabitDocument); // Send the created habit back
  } catch (error) {
    console.error("Error creating habit:", error);
    res.status(500).json({
      message: "Failed to create habit",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// ENHANCED: Get Habits Endpoint (Handles overdue AND auto-unhides)
app.get("/api/habits", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    // Get today's date boundaries
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart);
    tomorrowStart.setUTCDate(tomorrowStart.getUTCDate() + 1);
    const tomorrowStartISO = tomorrowStart.toISOString();
    const todayStartISO = todayStart.toISOString(); // For checking completion date

    // --- Step 1: Process Overdue Habits & Auto-Unhide ---
    // Fetch habits due BEFORE today (including hidden) to reset streaks/unhide
    const overdueResponse = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.lessThan("nextDueDate", todayStartISO), // Strictly before today
      ]
    );

    const updatePromises = [];
    for (const habit of overdueResponse.documents) {
      console.log(`Habit "${habit.habitName}" (${habit["$id"]}) is overdue.`);
      const nextScheduledDate = calculateNextDueDate(
        habit.nextDueDate,
        habit.frequencyType,
        habit.frequencyValue
      );
      const updateData = {
        currentStreak: 0,
        nextDueDate: nextScheduledDate.toISOString(),
      };
      if (habit.isHidden) {
        // Auto-unhide if overdue
        updateData.isHidden = false;
        console.log(` -> Auto-unhiding overdue habit ${habit["$id"]}.`);
      }
      updatePromises.push(
        databases.updateDocument(
          DATABASE_ID,
          HABITS_COLLECTION_ID,
          habit["$id"],
          updateData
        )
      );
    }

    // Fetch hidden habits due exactly today to auto-unhide them
    const hiddenTodayResponse = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.equal("isHidden", true),
        Appwrite.Query.greaterThanEqual("nextDueDate", todayStartISO), // Due today or later
        Appwrite.Query.lessThan("nextDueDate", tomorrowStartISO), // Due before tomorrow
      ]
    );
    for (const habit of hiddenTodayResponse.documents) {
      console.log(
        `Habit "${habit.habitName}" (${habit["$id"]}) was hidden but is due today. Auto-unhiding.`
      );
      updatePromises.push(
        databases.updateDocument(
          DATABASE_ID,
          HABITS_COLLECTION_ID,
          habit["$id"],
          { isHidden: false }
        )
      );
    }

    // Execute all updates if any
    if (updatePromises.length > 0) {
      await Promise.all(updatePromises);
      console.log(
        `Performed ${updatePromises.length} updates for overdue/hidden habits.`
      );
      // Add a small delay to allow DB changes to propagate before the final fetch
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
    // --- End Step 1 ---

    // --- Step 2: Fetch Habits to Display on Main Screen ---
    // Now fetch ONLY non-hidden habits
    const displayResponse = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.equal("isHidden", false), // Only get visible habits
        // Add sorting if desired, e.g., by name or due date
        Appwrite.Query.orderAsc("habitName"),
      ]
    );

    console.log(
      `Sending ${displayResponse.documents.length} visible habits for user: ${userId}`
    );
    res.status(200).json(displayResponse.documents); // Send the list to display
  } catch (error) {
    console.error("Error fetching/processing habits:", error);
    res.status(500).json({
      message: "Failed to fetch habits",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// NEW: Create Subtask Endpoint
app.post("/api/subtasks", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId; // Get user ID from authenticated token
    const {
      habitId, // ID of the habit this subtask belongs to
      subtaskName,
      isRequired, // Optional, defaults to true in Appwrite schema
      optionGroupName, // Optional, for grouping OR tasks
    } = req.body;

    // --- Validation ---
    if (!habitId || !subtaskName) {
      return res
        .status(400)
        .json({ message: "habitId and subtaskName are required." });
    }

    // Verify the habit belongs to the user
    const habit = await databases.getDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId
    );
    if (habit.userId !== userId) {
      return res
        .status(403)
        .json({ message: "Forbidden: Habit does not belong to user" });
    }
    // --- End Validation ---

    const newSubtaskDocument = await databases.createDocument(
      DATABASE_ID,
      SUBTASKS_COLLECTION_ID,
      Appwrite.ID.unique(), // Let Appwrite generate document ID for the subtask
      {
        habitId,
        subtaskName,
        // Use provided value or rely on Appwrite's default (which we set to true)
        isRequired: typeof isRequired === "boolean" ? isRequired : undefined,
        optionGroupName: optionGroupName || null, // Store null if empty/not provided
      }
    );

    console.log(
      `Successfully created subtask "${subtaskName}" for habit: ${habitId}`
    );
    res.status(201).json(newSubtaskDocument); // Send the created subtask back
  } catch (error) {
    console.error("Error creating subtask:", error);
    // Handle specific errors like habit not found (error.code === 404) if needed
    res.status(500).json({
      message: "Failed to create subtask",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

app.get("/api/habits/:habitId/subtasks", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId; // From authenticated token
    const { habitId } = req.params; // Get habitId from URL parameter

    // Optional: Verify the habit belongs to the user first
    // const habit = await databases.getDocument(DATABASE_ID, HABITS_COLLECTION_ID, habitId);
    // if (habit.userId !== userId) {
    //   return res.status(403).json({ message: 'Forbidden: Habit does not belong to user' });
    // }

    // Fetch subtasks linked to the given habitId
    const response = await databases.listDocuments(
      DATABASE_ID,
      SUBTASKS_COLLECTION_ID,
      [
        Appwrite.Query.equal("habitId", habitId),
        // Optionally add sorting if needed, e.g., by name or creation order
        // Appwrite.Query.orderAsc('subtaskName')
      ]
    );

    console.log(
      `Successfully fetched ${response.documents.length} subtasks for habit: ${habitId}`
    );
    res.status(200).json(response.documents); // Send the list of subtask documents
  } catch (error) {
    console.error(
      `Error fetching subtasks for habit ${req.params.habitId}:`,
      error
    );
    res.status(500).json({
      message: "Failed to fetch subtasks",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

app.post("/api/habits/:habitId/complete", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { habitId } = req.params;
    const { completedSubtaskIds, notes } = req.body; // Expect an array of IDs and optional notes

    if (!Array.isArray(completedSubtaskIds)) {
      return res
        .status(400)
        .json({ message: "completedSubtaskIds must be an array." });
    }

    // --- 1. Fetch Habit and its Subtasks ---
    const habit = await databases.getDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId
    );
    // Basic ownership check
    if (habit.userId !== userId) {
      return res
        .status(403)
        .json({ message: "Forbidden: Habit does not belong to user" });
    }

    const subtasksResponse = await databases.listDocuments(
      DATABASE_ID,
      SUBTASKS_COLLECTION_ID,
      [Appwrite.Query.equal("habitId", habitId), Appwrite.Query.limit(100)] // Limit subtasks per habit?
    );
    const allSubtasks = subtasksResponse.documents;

    // --- 2. Validate Completion Logic ---
    let isValidCompletion = true;
    const requiredSubtasks = allSubtasks.filter(
      (st) => st.isRequired && !st.optionGroupName
    );
    const optionalGroups = {}; // Group optional subtasks by name
    allSubtasks.forEach((st) => {
      if (st.optionGroupName) {
        if (!optionalGroups[st.optionGroupName]) {
          optionalGroups[st.optionGroupName] = [];
        }
        optionalGroups[st.optionGroupName].push(st["$id"]);
      }
    });

    // Check if all required subtasks are completed
    for (const reqSubtask of requiredSubtasks) {
      if (!completedSubtaskIds.includes(reqSubtask["$id"])) {
        isValidCompletion = false;
        console.log(
          `Validation failed: Required subtask ${reqSubtask["$id"]} not completed.`
        );
        break;
      }
    }

    // Check if at least one from each optional group is completed
    if (isValidCompletion) {
      for (const groupName in optionalGroups) {
        const groupSubtaskIds = optionalGroups[groupName];
        const completedInGroup = groupSubtaskIds.some((subtaskId) =>
          completedSubtaskIds.includes(subtaskId)
        );
        if (!completedInGroup) {
          isValidCompletion = false;
          console.log(
            `Validation failed: No subtask completed for optional group ${groupName}.`
          );
          break;
        }
      }
    }

    if (!isValidCompletion) {
      return res.status(400).json({
        message:
          "Completion requirements not met. Check required tasks and options.",
      });
    }

    // --- 3. If Valid: Update Habit & Create History ---
    const today = new Date();
    const nextDueDate = calculateNextDueDate(
      // Use the helper function
      habit.nextDueDate, // Calculate based on the current due date being completed
      habit.frequencyType,
      habit.frequencyValue
    );
    const newStreak = (habit.currentStreak || 0) + 1;
    const newLongestStreak = Math.max(habit.longestStreak || 0, newStreak);

    // --- GAMIFICATION: Update Profile ---
    let profileToUpdate = null;
    let newLevel = 1;
    let xpGained = 0;
    let variableRewardMsg = null;

    try {
      const profile = await databases.getDocument(
        DATABASE_ID,
        USER_PROFILES_COLLECTION_ID,
        userId
      );

      // Calculate XP based on difficulty
      const diff = (habit.difficulty || "Medium").toLowerCase();
      if (diff === "hard") xpGained = 30;
      else if (diff === "small") xpGained = 10;
      else xpGained = 20;

      let newXp = profile.xp + xpGained;
      newLevel = profile.level;

      // Level up formula: every 100 XP is a level
      const xpNeeded = profile.level * 100;
      if (newXp >= xpNeeded) {
        newLevel += 1;
      }

      // Add to specific category
      const category = (habit.category || "Productivity").toLowerCase();
      let healthXp = profile.healthXp;
      let productivityXp = profile.productivityXp;
      let mindfulnessXp = profile.mindfulnessXp;
      let learningXp = profile.learningXp;

      if (category === "health") healthXp += xpGained;
      else if (category === "mindfulness") mindfulnessXp += xpGained;
      else if (category === "learning") learningXp += xpGained;
      else productivityXp += xpGained; // default

      // Apply Variable Rewards (10% chance)
      let freezeTokens = profile.streakFreezeTokens;
      // ⚡ Completing any habit restores +10 energy (Duolingo-style)
      let newEnergy = Math.min(100, (profile.avatarEnergy ?? 100) + 10);
      if (Math.random() < 0.1) {
        if (Math.random() < 0.5) {
          freezeTokens += 1;
          variableRewardMsg = "Surprise! You found a Streak Freeze Token!";
        } else {
          newEnergy = Math.min(100, newEnergy + 10); // Extra +10 bonus
          variableRewardMsg = "Avatar Energy boost! +10 Bonus Energy!";
        }
      }

      // Mark today as last activity date (used for drain calculation)
      const todayDate = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"

      profileToUpdate = databases.updateDocument(
        DATABASE_ID,
        USER_PROFILES_COLLECTION_ID,
        userId,
        {
          xp: newXp,
          level: newLevel,
          healthXp,
          productivityXp,
          mindfulnessXp,
          learningXp,
          streakFreezeTokens: freezeTokens,
          avatarEnergy: newEnergy,
          lastHabitCompletionDate: todayDate, // ← saves today's date to prevent drain tomorrow
        }
      );
    } catch (e) {
      console.log("No profile found to update or error:", e.message);
    }

    // Create history entry (run in parallel with habit update)
    const historyPromise = databases.createDocument(
      DATABASE_ID,
      HABIT_HISTORY_COLLECTION_ID,
      Appwrite.ID.unique(),
      {
        habitId,
        completionDate: today.toISOString(),
        userId,
        completedSubtaskIds, // Save the actual completed IDs
        notes: notes || null,
      }
    );

    // Update the habit document
    const habitUpdatePromise = databases.updateDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId,
      {
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastCompletedDate: today.toISOString(),
        nextDueDate: nextDueDate.toISOString(),
      }
    );

    // Wait for all operations to complete
    const promisesToWait = [habitUpdatePromise, historyPromise];
    if (profileToUpdate) promisesToWait.push(profileToUpdate);

    const results = await Promise.all(promisesToWait);
    const updatedHabit = results[0];

    // Inject gamification response
    updatedHabit.gamification = {
      xpGained,
      newLevel,
      variableRewardMsg
    };

    console.log(
      `Habit ${habitId} completed. Streak: ${newStreak}. Next due: ${nextDueDate.toISOString()}.`
    );
    res.status(200).json(updatedHabit); // Send back the updated habit
  } catch (error) {
    console.error(`Error completing habit ${req.params.habitId}:`, error);
    res.status(500).json({
      message: "Failed to complete habit",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});
// NEW: Hide Habit Endpoint
app.put("/api/habits/:habitId/hide", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { habitId } = req.params;

    // Verify ownership
    const habit = await databases.getDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId
    );
    if (habit.userId !== userId) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const updatedHabit = await databases.updateDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId,
      { isHidden: true } // Set isHidden to true
    );
    console.log(`Habit ${habitId} hidden.`);
    res.status(200).json(updatedHabit);
  } catch (error) {
    console.error(`Error hiding habit ${req.params.habitId}:`, error);
    res
      .status(500)
      .json({ message: "Failed to hide habit", error: error.message });
  }
});

// NEW: Show (Unhide) Habit Endpoint
app.put("/api/habits/:habitId/show", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { habitId } = req.params;

    // Verify ownership
    const habit = await databases.getDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId
    );
    if (habit.userId !== userId) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const updatedHabit = await databases.updateDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      habitId,
      { isHidden: false } // Set isHidden to false
    );
    console.log(`Habit ${habitId} shown (unhidden).`);
    res.status(200).json(updatedHabit);
  } catch (error) {
    console.error(`Error showing habit ${req.params.habitId}:`, error);
    res
      .status(500)
      .json({ message: "Failed to show habit", error: error.message });
  }
});

// NEW: Get Hidden Habits Endpoint
app.get("/api/habits/hidden", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const response = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.equal("isHidden", true), // Fetch only hidden habits
        // Optionally add sorting, e.g., by name
        Appwrite.Query.orderAsc("habitName"),
      ]
    );
    console.log(
      `Sending ${response.documents.length} hidden habits for user: ${userId}`
    );
    res.status(200).json(response.documents);
  } catch (error) {
    console.error("Error fetching hidden habits:", error);
    res
      .status(500)
      .json({ message: "Failed to fetch hidden habits", error: error.message });
  }
});

// NEW: Get Today's Habit History Entry for a Specific Habit
app.get(
  "/api/habits/:habitId/history/today",
  authMiddleware,
  async (req, res) => {
    try {
      const userId = req.userId;
      const { habitId } = req.params;

      // Get today's date boundaries (start and end) in UTC
      const todayStart = new Date();
      todayStart.setUTCHours(0, 0, 0, 0);
      const tomorrowStart = new Date(todayStart);
      tomorrowStart.setUTCDate(tomorrowStart.getUTCDate() + 1);

      // Find history entry for this habit completed today
      const response = await databases.listDocuments(
        DATABASE_ID,
        HABIT_HISTORY_COLLECTION_ID,
        [
          Appwrite.Query.equal("userId", userId),
          Appwrite.Query.equal("habitId", habitId),
          Appwrite.Query.greaterThanEqual(
            "completionDate",
            todayStart.toISOString()
          ),
          Appwrite.Query.lessThan(
            "completionDate",
            tomorrowStart.toISOString()
          ),
          Appwrite.Query.limit(1), // Should only be one entry per day
        ]
      );

      if (response.documents.length > 0) {
        res.status(200).json(response.documents[0]); // Return the single entry found
      } else {
        res
          .status(404)
          .json({ message: "No completion history found for today." });
      }
    } catch (error) {
      console.error(
        `Error fetching today's history for habit ${req.params.habitId}:`,
        error
      );
      res
        .status(500)
        .json({ message: "Failed to fetch history", error: error.message });
    }
  }
);

app.get("/api/habits/:habitId/history", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { habitId } = req.params;

    // Optional: Verify the main habit belongs to the user first
    // const habit = await databases.getDocument(DATABASE_ID, HABITS_COLLECTION_ID, habitId);
    // if (habit.userId !== userId) {
    //   return res.status(403).json({ message: 'Forbidden' });
    // }

    // Fetch all history entries for this habit and user, ordered by date
    const response = await databases.listDocuments(
      DATABASE_ID,
      HABIT_HISTORY_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.equal("habitId", habitId),
        Appwrite.Query.orderDesc("completionDate"), // Get newest first
        Appwrite.Query.limit(500), // Adjust limit as needed, consider pagination later
      ]
    );

    console.log(
      `Successfully fetched ${response.documents.length} history entries for habit: ${habitId}`
    );
    res.status(200).json(response.documents); // Send the list of history documents
  } catch (error) {
    console.error(
      `Error fetching history for habit ${req.params.habitId}:`,
      error
    );
    res.status(500).json({
      message: "Failed to fetch habit history",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// --- GAMIFICATION ENDPOINTS ---

// Get User Profile (Gamification Stats)
app.get("/api/profile", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    let profileData = null;
    try {
      profileData = await databases.getDocument(
        DATABASE_ID,
        USER_PROFILES_COLLECTION_ID,
        userId
      );
    } catch (e) {
      if (e.code === 404) {
        // Auto-initialize profile for existing users
        profileData = await databases.createDocument(
          DATABASE_ID,
          USER_PROFILES_COLLECTION_ID,
          userId, // Use userId as the document ID
          {
            userId: userId,
            xp: 0,
            level: 1,
            streakFreezeTokens: 0,
            avatarEnergy: 100,
            healthXp: 0,
            productivityXp: 0,
            mindfulnessXp: 0,
            learningXp: 0,
            equippedAvatar: "default_avatar"
          }
        );
      } else {
        throw e;
      }
    }

    // Attempt to fetch the user's registered name
    let userName = "Habitster User";
    try {
      const userRecord = await users.get(userId);
      if (userRecord && userRecord.name) {
        userName = userRecord.name;
      } else if (userRecord && userRecord.email) {
        // Fallback to email prefix if no name is set
        userName = userRecord.email.split('@')[0];
        // Capitalize the first letter for aesthetics
        userName = userName.charAt(0).toUpperCase() + userName.slice(1);
      }
    } catch (err) {
      console.log("Warning: Could not fetch user name for profile:", err.message);
    }

    // Compute the best active streak across all user habits
    let bestStreak = 0;
    try {
      const habitsResponse = await databases.listDocuments(
        DATABASE_ID,
        HABITS_COLLECTION_ID,
        [
          Appwrite.Query.equal("userId", userId),
          Appwrite.Query.limit(100),
        ]
      );
      if (habitsResponse.documents.length > 0) {
        bestStreak = Math.max(...habitsResponse.documents.map(h => h.currentStreak || 0));
      }
    } catch (err) {
      console.log("Warning: Could not compute streak:", err.message);
    }

    // --- Duolingo-style ENERGY DRAIN ---
    // Compute days since last habit completion and drain energy
    const todayStr = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
    const lastActivity = profileData.lastHabitCompletionDate || null;
    let currentEnergy = profileData.avatarEnergy ?? 100;

    if (lastActivity && lastActivity !== todayStr) {
      // Count missed days
      const lastDate = new Date(lastActivity);
      const today = new Date(todayStr);
      const diffMs = today - lastDate;
      const missedDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

      if (missedDays > 0) {
        const drainAmount = missedDays * 10; // -10 per missed day
        currentEnergy = Math.max(0, currentEnergy - drainAmount);

        // Save drained energy back so it doesn't drain again on next refresh
        try {
          await databases.updateDocument(
            DATABASE_ID, USER_PROFILES_COLLECTION_ID, userId,
            { avatarEnergy: currentEnergy }
          );
          profileData = { ...profileData, avatarEnergy: currentEnergy };
          console.log(`Energy drained ${drainAmount} for user ${userId}. Missed ${missedDays} day(s). New energy: ${currentEnergy}`);
        } catch (drainErr) {
          console.log("Warning: Could not save drained energy:", drainErr.message);
        }
      }
    } else if (!lastActivity) {
      // Brand new user - set today as last activity so energy doesn't drain immediately
      try {
        await databases.updateDocument(
          DATABASE_ID, USER_PROFILES_COLLECTION_ID, userId,
          { lastHabitCompletionDate: todayStr }
        );
      } catch (e) { /* ignore */ }
    }

    res.status(200).json({
      ...profileData,
      avatarEnergy: currentEnergy,
      name: userName,
      bestStreak,
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    res.status(500).json({ message: "Failed to fetch profile", error: error.message });
  }
});

// Get Leaderboard (Top 10 by XP)
app.get("/api/leaderboard", authMiddleware, async (req, res) => {
  try {
    const response = await databases.listDocuments(
      DATABASE_ID,
      USER_PROFILES_COLLECTION_ID,
      [
        Appwrite.Query.orderDesc("xp"),
        Appwrite.Query.limit(10)
      ]
    );

    res.status(200).json(response.documents);
  } catch (error) {
    console.error("Error fetching leaderboard:", error);
    res.status(500).json({ message: "Failed to fetch leaderboard", error: error.message });
  }
});

// Get Activity Stats (Last 30 days)
app.get("/api/stats/activity", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    thirtyDaysAgo.setUTCHours(0, 0, 0, 0);

    const response = await databases.listDocuments(
      DATABASE_ID,
      HABIT_HISTORY_COLLECTION_ID,
      [
        Appwrite.Query.equal("userId", userId),
        Appwrite.Query.greaterThanEqual("completionDate", thirtyDaysAgo.toISOString()),
        Appwrite.Query.orderDesc("completionDate"),
        Appwrite.Query.limit(1000), // Assuming reasonable daily completions
      ]
    );

    // Aggregate by date
    const activityMap = {};
    response.documents.forEach(doc => {
      const dateKey = doc.completionDate.split('T')[0];
      activityMap[dateKey] = (activityMap[dateKey] || 0) + 1;
    });

    res.status(200).json(activityMap);
  } catch (error) {
    console.error("Error fetching activity stats:", error);
    res.status(500).json({ message: "Failed to fetch activity stats", error: error.message });
  }
});

// Update Equipped Avatar
app.put("/api/profile/avatar", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { avatarId } = req.body;

    if (!avatarId) {
      return res.status(400).json({ message: "Avatar ID is required" });
    }

    // 1. Fetch user profile
    try {
      await databases.getDocument(
        DATABASE_ID,
        USER_PROFILES_COLLECTION_ID,
        userId
      );
    } catch (e) {
      if (e.code === 404) {
        return res.status(404).json({ message: "Profile not found" });
      } else {
        throw e;
      }
    }

    // 2. Update equipped avatar
    const updatedProfile = await databases.updateDocument(
      DATABASE_ID,
      USER_PROFILES_COLLECTION_ID,
      userId,
      {
        equippedAvatar: avatarId
      }
    );

    res.status(200).json(updatedProfile);
  } catch (error) {
    console.error("Error updating avatar:", error);
    res.status(500).json({ message: "Failed to update avatar", error: error.message });
  }
});

// --- Start Server ---
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
