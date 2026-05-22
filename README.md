# 🏝️ Habitster

> A gamified, AI-driven habit tracking platform that turns your daily routines into a thriving virtual island.

**Habitster** solves the common problem of user churn in traditional productivity apps by combining **Positive Reinforcement Gamification** with **AI-Driven Personalization**. Instead of merely checking off lists, users are rewarded with tangible virtual progress and receive personalized feedback from an integrated AI counselor.

---

## 🌟 Key Features

*   **🏝️ Procedural Virtual Island (Gamification Engine):** Your habits physically manifest! As you complete tasks, your dynamic 2.5D island procedurally expands, adding trees and houses. If you ignore your habits, a decay mechanic withers your island until you get back on track.
*   **🤖 Context-Aware AI Counselor:** Not just a chatbot. The integrated AI (powered by Groq/Llama) automatically reads your database records (missed tasks, current mood, current streaks) to give you highly personalized, contextual accountability and motivation.
*   **📈 Progress Analytics & Mood Tracking:** Daily mood logging with visual charts showing habit consistency and mood correlation.
*   **🔄 Advanced Recurrence Engine:** Supports complex date mathematics for habits (daily, specific days, every X days) handling all calendar edge cases seamlessly.
*   **🔐 Dual Authentication:** Secure Email/Password login alongside seamless Google OAuth with deep linking directly back into the mobile app.

---

## 🏗️ Architecture & Technology Stack

Habitster utilizes a robust, enterprise-grade **Decoupled Client-Server Architecture**:

### 📱 Frontend (Mobile App)
*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Local Storage**: `Hive` (NoSQL caching) & `flutter_secure_storage` (JWT tokens)
*   **UI/UX**: Custom `Matrix4` transformations for 3D isometric rendering, `flutter_animate`, and `fl_chart`.

### ⚙️ Backend (API Server)
*   **Runtime**: Node.js with Express.js
*   **Authentication**: Passport.js (Google OAuth 2.0), JSON Web Tokens (JWT)
*   **Database Integration**: Appwrite BaaS (`node-appwrite` SDK)
*   **AI Integration**: Groq Cloud API (Llama 3.3 70B, Mixtral 8x7B) using a custom ReAct Agent Framework.
*   **Deployment**: Render (Cloud Application Hosting)

### 🗄️ Database (Appwrite)
*   Stores Users, Tasks, Habits, Gamification Profiles, Moods, and Island States.

---

## 🧠 Core AI Methodologies

Habitster's AI engine is built for reliability and genuine helpfulness:
1.  **Agentic Function Calling (ReAct):** The AI actively identifies user intent, automatically triggers backend functions (like completing a habit on the user's behalf), and generates responses based on the executed action.
2.  **Contextual Data Injection:** Before the AI ever sees your prompt, the backend injects your habit IDs, streak statuses, and recent moods directly into the system prompt. 
3.  **Hallucination Mitigation:** We enforce strict JSON-schema function calls to prevent the AI from generating invalid habits or corrupting database entries.
4.  **Proactive Interventions:** The system monitors activity logs and autonomously sends encouragement or motivation when it detects a streak break.

---

## 🎨 Technical Highlight: 2.5D Isometric Rendering

Instead of relying on heavy, battery-draining 3D game engines like Unity, the Habitster Virtual Island is built entirely from scratch using mathematical matrix transformations. 

By applying `Matrix4.identity()..rotateX(0.9)..rotateZ(-0.6)` to a standard Flutter `GridView`, we tilt a flat 2D grid into a perfect 3D isometric perspective. The backend procedurally calculates expansion using the formula `floor(trees / 25) + floor(houses / 5) + floor(completions / 10)`, allowing the island to organically grow with your real-world progress!

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Node.js](https://nodejs.org/en/download/)
- An [Appwrite](https://appwrite.io/) instance (Cloud or Self-Hosted)

### Local Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Sourav-6/habitster.git
   ```
2. Navigate to the frontend directory and install dependencies:
   ```bash
   cd habitster/Frontend
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
