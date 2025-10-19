const express = require("express");
const app = express();
const PORT = 3000;
const jwt = require("jsonwebtoken");
const authMiddleware = require("./middleware/authMiddleware");
// NEW: Import dotenv to read .env file
require("dotenv").config();

// NEW: Import Appwrite SDK
const Appwrite = require("node-appwrite");

// NEW: Initialize the Appwrite Client
const client = new Appwrite.Client();
client
  .setEndpoint("https://nyc.cloud.appwrite.io/v1") // Appwrite Endpoint
  .setProject(process.env.APPWRITE_PROJECT_ID) // Your Project ID from .env
  .setKey(process.env.APPWRITE_API_KEY); // Your API Key from .env
// NEW: Create an instance of the Users API
const account = new Appwrite.Account(client);
const { nanoid } = require("nanoid");

const databases = new Appwrite.Databases(client);

// NEW: Store your Database and Collection IDs (Get these from Appwrite!)
const DATABASE_ID = "68f3c29000072cae03e0";
const TASKS_COLLECTION_ID = "tasks-storage";

// --- Middleware ---
app.use(express.json());

// --- Routes ---
app.get("/", (req, res) => {
  res.send("Habitster backend is running!");
});

// --- API Endpoints ---
// We will update these next to use Appwrite
app.post("/api/auth/register", async (req, res) => {
  // Added 'async'
  try {
    const { email, password } = req.body;

    // 1. Create a unique ID for the new user
    const userId = nanoid();

    // 2. Call Appwrite to create the user
    // Appwrite Users.create signature is (userId, email, password, name?)
    const newUser = await users.create(
      userId,
      email,
      null, // name (optional)
      password
    );

    console.log("Successfully created user:", newUser);

    // 3. Send a success response back to Flutter
    res.status(201).json({
      message: "User registered successfully!",
      userId: newUser.$id,
    });
  } catch (error) {
    console.error("Error creating user:", error); // Keep logging the full error to the console
    res.status(500).json({
      message: "Failed to register user",
      // NEW: Send back the full error details as a string
      error: JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

// UPDATED Login Endpoint
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
    // --- TEMPORARY USER ID FOR TESTING ---
    // Replace this with the SAME user ID you used for creating tasks
    const userId = req.userId;
    // --- END TEMPORARY ---

    // 1. Fetch documents from Appwrite
    const response = await databases.listDocuments(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      [Appwrite.Query.equal("userId", userId)]
    );

    console.log("Successfully fetched tasks for user:", userId);
    // 3. Send the list of documents (tasks) back
    res.status(200).json(response.documents);
  } catch (error) {
    console.error("Error fetching tasks:", error);
    res.status(500).json({
      message: "Failed to fetch tasks",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
    });
  }
});

app.delete("/api/tasks/:taskId", authMiddleware, async (req, res) => {
  try {
    const { taskId } = req.params; // Get task ID from URL parameter

    const userId = req.userId; // Get user ID from middleware

    // --- IMPORTANT: Verify task ownership ---
    const task = await databases.getDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      taskId
    );
    if (task.userId !== userId) {
      console.warn(
        `User ${userId} attempted to delete task ${taskId} owned by ${task.userId}`
      );
      return res
        .status(403)
        .json({ message: "Forbidden: You do not own this task" });
    }

    await databases.deleteDocument(DATABASE_ID, TASKS_COLLECTION_ID, taskId);

    console.log("Successfully deleted task:", taskId);
    res.status(204).send(); // 204 No Content is standard for successful delete
  } catch (error) {
    console.error("Error deleting task:", error);
    res.status(500).json({
      message: "Failed to delete task",
      error:
        error.message ||
        JSON.stringify(error, Object.getOwnPropertyNames(error)),
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
// --- Start Server ---
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
