# Omi - Voice Memory Assistant

**Version:** 1.0.0  
**Platform:** Flutter (Android/iOS)  
**Architecture:** Clean Architecture with Riverpod

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Architecture](#architecture)
5. [Data Models](#data-models)
6. [Database Schema](#database-schema)
7. [Authentication System](#authentication-system)
8. [Core Services](#core-services)
9. [Memory Extraction](#memory-extraction)
10. [Reminder System](#reminder-system)
11. [UI Screens](#ui-screens)
12. [Navigation Flow](#navigation-flow)
13. [API Integration](#api-integration)
14. [Security](#security)
15. [Error Handling](#error-handling)
16. [Build & Deployment](#build--deployment)
17. [Project Structure](#project-structure)

---

## 1. Overview

Omi is a voice-powered memory assistant that transforms how you capture and remember important information. Instead of manually typing notes or creating reminders, you simply speak naturally, and the app intelligently processes your voice input to extract structured memories and schedule reminders automatically.

### 1.1 What Omi Does

Imagine saying "Remind me to call Mom tomorrow at 9am" and having Omi automatically create a reminder for exactly that time. Or during an important meeting, let Omi listen and automatically extract key facts, tasks, and commitments discussed. This is the core experience Omi delivers.

### 1.2 How It Works

The application follows a simple but powerful flow:

1. **Capture** - You speak or record audio containing important information
2. **Transcribe** - Your speech is converted to text in real-time
3. **Extract** - AI analyzes the transcript to identify memories, tasks, and schedules
4. **Schedule** - Dates and times mentioned are converted into actual reminders
5. **Notify** - You receive timely notifications when reminders are due

### 1.3 Key Capabilities

| Capability | Description |
|------------|-------------|
| Voice Transcription | Real-time speech-to-text conversion |
| AI Memory Extraction | Intelligent categorization using Google Gemini |
| Smart Reminders | Automatic scheduling from natural language |
| Session Tracking | Monitor your usage patterns |
| Local Authentication | Secure offline login without cloud dependencies |

---

## 2. Features

### 2.1 Authentication

The authentication system provides a secure, offline-first approach to user management. All user data stays on the device.

**Signup Process:**
- Users enter their email address and create a password
- Email validation ensures proper format before submission
- Password must be at least 6 characters for security
- Password confirmation ensures no typing mistakes
- Passwords are hashed using SHA-256 before storage

**Login Process:**
- Users enter their registered email and password
- The system compares the hashed password against stored records
- Successful login restores the previous session

**Session Management:**
- After successful login, the user session is saved locally
- When the app restarts, it automatically restores the session
- Users can logout, which clears the saved session
- No internet connection is required for authentication

### 2.2 Voice Recording

The voice recording system captures speech input and converts it to text for processing.

**Recording Features:**
- Real-time speech recognition starts when you tap the microphone
- Audio levels are visualized as a waveform indicator
- Transcripts appear live on screen as you speak
- Recording sessions are tracked with duration and chunk counts
- Background noise is filtered to improve accuracy

**How Voice Capture Works:**
1. User taps the microphone button to start recording
2. The app listens to audio input continuously
3. Each segment of speech is transcribed in real-time
4. The transcript updates live on the screen
5. Tapping stop finalizes the transcript for processing

### 2.3 Memory Management

Memories are the core data unit in Omi. Every piece of information extracted from your speech becomes a memory.

**Memory Types:**
| Type | Description | Example |
|------|-------------|---------|
| reminder | Time-based notification | "Call mom tomorrow at 9am" |
| task | Action item to complete | "Send the report by Friday" |
| fact | Personal fact or information | "John is my manager" |
| note | General note or thought | "Interesting article about AI" |
| event | Scheduled event or meeting | "Team meeting Monday 3pm" |

**Memory Properties:**
- **Importance** - A score from 1-5 indicating significance (5 being most important)
- **Content** - The cleaned, human-readable text of the memory
- **Type** - Which category this memory belongs to
- **DateTime** - When applicable, the parsed date/time information

**Memory Operations:**
- **Create** - Memories are automatically created from voice transcripts
- **Read** - Browse all memories in the Memories screen
- **Update** - Edit memory content or type
- **Delete** - Remove unwanted memories
- **Search** - Find memories by content or filter by type

### 2.4 Reminder System

The reminder system converts extracted schedule information into actionable notifications.

**Automatic Scheduling:**
- When a memory with a datetime is created, a reminder is automatically scheduled
- The AI extracts date/time information from natural language
- Examples: "in 5 minutes", "tomorrow at 5pm", "next Monday"

**Notification Features:**
- Exact alarm timing using Android's alarm manager
- Alarms persist even when the app is closed
- Full-screen alarm display when reminder triggers
- Snooze option adds 5 minutes to the reminder
- Stop button dismisses the alarm completely

**Reminder Lifecycle:**
1. Memory created with date/time information
2. Reminder record generated and saved
3. System schedules exact notification time
4. At scheduled time, alarm triggers
5. User can snooze (delay 5 min) or stop (dismiss)

### 2.5 Session Tracking

Recording sessions help you understand your usage patterns and revisit past conversations.

**Session Data:**
- Start and end timestamps
- Duration of recording
- Transcript snippet (first 500 characters)
- Count of memories extracted during the session
- Historical list of all past sessions

**Session Flow:**
1. Session starts when recording begins
2. Active session tracks all transcripts
3. Session ends when recording stops
4. Memories created during session are linked to it
5. Session summary is saved for history

### 2.6 Settings

The settings screen provides control over app behavior and appearance.

**Available Settings:**
- **Theme Toggle** - Switch between light and dark mode
- **Notifications** - Enable or disable reminder notifications
- **Offline Retry** - Configure retry attempts when offline
- **Onboarding Status** - Track if initial setup is complete
- **Permissions** - Manage microphone and notification access

---

## 3. Technology Stack

The application uses modern Flutter packages to deliver a reliable, performant experience.

### 3.1 Core Framework

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Framework | Flutter | 3.9+ | Cross-platform mobile framework |
| State Management | Riverpod | 2.5+ | Reactive state management |
| Navigation | GoRouter | 14+ | Declarative routing |
| Database | Drift | 2.18+ | Type-safe SQLite ORM |

### 3.2 Speech & Audio

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Speech Recognition | speech_to_text | 7.0+ | Convert speech to text |
| Audio Playback | audioplayers | 6.0+ | Play alarm sounds |

### 3.3 AI & Notifications

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| AI Processing | Google Gemini API | - | Memory extraction |
| Notifications | flutter_local_notifications | 17.2+ | Local push notifications |
| Alarm Manager | android_alarm_manager_plus | 3.0+ | Exact alarm scheduling |
| Timezone | timezone + flutter_timezone | - | Accurate time handling |

### 3.4 Utilities

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| HTTP Client | http | 1.2+ | API calls to Gemini |
| Security | crypto | 3.0+ | Password hashing |
| Preferences | shared_preferences | 2.3+ | Session storage |
| Fonts | google_fonts | 6.2+ | Typography |

---

## 4. Architecture

### 4.1 Clean Architecture Layers

The application follows Clean Architecture principles with three distinct layers:

**Presentation Layer**
- UI widgets and screens that users interact with
- Riverpod providers that manage UI state
- No business logic directly in UI components

**Domain Layer**
- Business logic lives in services
- Memory extraction and reminder scheduling logic
- Date/time parsing and validation

**Data Layer**
- Data models that represent business entities
- Database tables defined using Drift
- Repository pattern for data access

### 4.2 Directory Structure

```
lib/
├── main.dart                    # App entry point, initialization
├── app.dart                     # MaterialApp configuration, routing, theme
├── core/
│   ├── theme/                   # Light and dark theme definitions
│   ├── services/                # NotificationService, AlarmService
│   ├── utils/                   # DateTimeParser, helpers
│   └── widgets/                 # Reusable UI components (GlassCard)
├── data/
│   ├── models/                  # UserRecord, MemoryRecord, ReminderRecord, SessionRecord
│   ├── local/                   # Drift database (AppDatabase)
│   └── repositories/            # Data access layer
└── features/
    ├── auth/                    # Authentication (login, signup, session)
    ├── memory/                  # Memory extraction and storage
    ├── reminder/                # Reminder scheduling and management
    ├── transcription/           # Speech-to-text functionality
    ├── sessions/                # Session tracking
    ├── audio/                   # Audio recording and processing
    ├── alarm/                   # Alarm display screen
    ├── settings/                # App settings
    └── ui/screens/              # All application screens
```

---

## 5. Data Models

### 5.1 UserRecord

Represents a registered user in the system.

```
UserRecord {
  id: String          // Unique identifier (UUID v4)
  email: String       // User's email address (must be unique)
  password: String    // SHA-256 hashed password
  createdAt: DateTime // Account creation timestamp
}
```

### 5.2 MemoryRecord

Represents a single memory extracted from voice input.

```
MemoryRecord {
  id: String          // Unique identifier (UUID v4)
  type: String        // Category: reminder, task, fact, note, event
  content: String     // Cleaned, human-readable memory text
  datetimeRaw: String? // Raw date/time string from AI (e.g., "tomorrow at 5pm")
  importance: int     // Importance score from 1 to 5
  createdAt: DateTime // When the memory was created
}
```

### 5.3 ReminderRecord

Represents a scheduled notification linked to a memory.

```
ReminderRecord {
  id: String              // Unique identifier (UUID v4)
  memoryId: String        // Foreign key to the source memory
  scheduledTime: DateTime // When the reminder should trigger
  status: String          // pending, adjusted, done, expired
  notificationId: int     // Unique ID for the notification
}
```

### 5.4 SessionRecord

Represents a voice recording session.

```
SessionRecord {
  id: String              // Unique identifier (UUID v4)
  startedAt: DateTime    // Session start time
  endedAt: DateTime?     // Session end time (null if active)
  transcriptSnippet: String? // First 500 characters of transcript
  memoryCount: int        // Number of memories created
  durationSeconds: int?  // Total recording duration
}
```

---

## 6. Database Schema

### 6.1 Users Table

Stores registered user accounts.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### 6.2 Memories Table

Stores all extracted memories.

```sql
CREATE TABLE memories (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  datetime_raw TEXT,
  importance INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
```

### 6.3 Reminders Table

Stores scheduled reminders linked to memories.

```sql
CREATE TABLE reminders (
  id TEXT PRIMARY KEY,
  memory_id TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY(memory_id) REFERENCES memories(id) ON DELETE CASCADE
);
```

### 6.4 Sessions Table

Stores voice recording session history.

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  transcript_snippet TEXT,
  memory_count INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER
);
```

---

## 7. Authentication System

### 7.1 Security Approach

The authentication system prioritizes security while keeping the app fully functional offline.

**Password Security:**
- Passwords are never stored in plain text
- SHA-256 hashing creates a one-way irreversible hash
- When logging in, the input password is hashed and compared
- Even if the database is compromised, actual passwords cannot be retrieved

**Session Security:**
- Session data is stored locally using SharedPreferences
- The user's ID and email are persisted after login
- On app restart, the system checks for an existing session
- Logout clears all session data immediately

### 7.2 Signup Flow

When a new user creates an account:

```
1. User enters email and password
   ↓
2. Validate email format (must be valid email pattern)
   ↓
3. Validate password length (minimum 6 characters)
   ↓
4. Check if email is already registered
   ↓
5. Hash the password using SHA-256
   ↓
6. Create new user record in database
   ↓
7. Start user session automatically
   ↓
8. Navigate to Home screen
```

### 7.3 Login Flow

When an existing user logs in:

```
1. User enters email and password
   ↓
2. Find user record by email
   ↓
3. If not found, show "No account found" error
   ↓
4. If found, compare hashed password
   ↓
5. If password doesn't match, show "Incorrect password" error
   ↓
6. If password matches, save session to SharedPreferences
   ↓
7. Navigate to Home screen
```

### 7.4 Auto-Login Flow

When the app starts:

```
1. App launches
   ↓
2. Check SharedPreferences for logged_in_user_id
   ↓
3. If session exists, load user from database
   ↓
4. If user found, navigate directly to Home
   ↓
5. If no session or user not found, navigate to Login
```

---

## 8. Core Services

### 8.1 NotificationService

Handles all local notification operations for reminders.

**Initialization:**
```dart
class NotificationService {
  // Called once in main.dart to set up notification channels
  Future<void> init()
  
  // Request permissions on Android 13+ and iOS
  Future<void> requestPermissions()
}
```

**Scheduling Reminders:**
```dart
class NotificationService {
  // Schedule a reminder with exact timing
  Future<bool> scheduleReminder(ReminderRecord, String content)
  
  // Cancel a specific reminder
  Future<void> cancelReminder(String reminderId)
  
  // Cancel all scheduled reminders
  Future<void> cancelAllReminders()
}
```

**Notification Channels:**
- **reminders** - High importance channel for regular reminders
- **alarms** - Maximum priority channel for alarm-like notifications

**Features:**
- Uses `zonedSchedule` for exact alarm timing
- Full-screen intent enabled for wake-up alerts
- Sound, vibration, and LED lights configured
- Timezone-aware scheduling using IANA timezone database

### 8.2 DateTimeParser

Extracts and converts natural language dates and times into DateTime objects.

**Main Methods:**
```dart
class DateTimeParser {
  // Parse from AI-extracted datetime_raw field
  static DateParseResult parse(String? raw)
  
  // Fallback: extract datetime from raw text directly
  static DateTime? parseFromText(String text)
}
```

**Supported Patterns:**
| Pattern | Example Input | Parsed Result |
|---------|--------------|----------------|
| Relative minutes | "after 5 minutes" | now + 5 minutes |
| Relative hours | "in 2 hours" | now + 2 hours |
| Tomorrow specific | "tomorrow at 5pm" | tomorrow 17:00 |
| Day of week | "next Monday" | upcoming Monday |
| Time only | "at 3:30 pm" | today 15:30 |
| ISO format | "2024-04-15T14:30:00" | exact datetime |

---

## 9. Memory Extraction

### 9.1 Gemini Service

The Gemini service handles AI-powered memory extraction from voice transcripts.

**Main Extraction Method:**
```dart
class GeminiService {
  // Main method to extract memories from transcript
  Future<MemoryExtractionResult> extractMemory(String transcript)
  
  // Fallback when API is unavailable
  MemoryExtractionResult _fallbackFromTranscript(String transcript)
}
```

### 9.2 AI Response Format

When Gemini successfully processes a transcript, it returns structured JSON:

```json
{
  "type": "reminder",
  "content": "Call mom",
  "datetime_raw": "after 5 minutes",
  "importance": 4
}
```

### 9.3 Fallback Extraction

When the Gemini API is unavailable (no API key, network error, or timeout), the app uses a keyword-based fallback parser.

**Type Detection:**
| Keywords Detected | Memory Type |
|------------------|-------------|
| remember, remind, tell me to | reminder |
| meeting, call, meet, appointment | event |
| must, todo, need to, should | task |
| fact about, knows that | fact |
| default | note |

**Importance Scoring:**
| Indicator | Importance |
|-----------|------------|
| urgent, important, critical | 5 |
| tomorrow, today, soon | 4 |
| this week, sometime | 3 |
| default | 2 |

**DateTime Extraction (Fallback):**
- "tomorrow at 5pm" → tomorrow 17:00
- "today at 3pm" → today 15:00
- "in 30 minutes" → now + 30 minutes
- "next Monday" → upcoming Monday 09:00

### 9.4 Memory Processing Flow

```
1. User speaks voice input
   ↓
2. TranscriptionService converts speech to text
   ↓
3. Call GeminiService.extractMemory(transcript)
   ↓
4. If GEMINI_API_KEY exists and network available:
   → Use Gemini AI for extraction
   Otherwise:
   → Use keyword-based fallback parser
   ↓
5. Create MemoryRecord with extracted data
   ↓
6. Save MemoryRecord to database
   ↓
7. If type is "reminder", call ReminderManager
   ↓
8. Update UI via Riverpod providers
```

---

## 10. Reminder System

### 10.1 ReminderManager

The reminder manager coordinates between memory creation and notification scheduling.

**Core Methods:**
```dart
class ReminderManager {
  // Process a memory and create scheduled reminder
  Future<bool> processMemoryForReminder(MemoryRecord memory)
  
  // Reschedule all pending reminders (called on app restart)
  Future<void> rescheduleAllReminders()
  
  // Cancel reminder when memory is deleted
  Future<void> cancelReminderForMemory(String memoryId)
}
```

### 10.2 Reminder Scheduling Flow

```
1. Memory created with type "reminder"
   ↓
2. Extract datetime_raw from memory
   ↓
3. If datetime_raw is null:
   → Try to parse datetime from memory content using fallback parser
   ↓
4. Parse datetime_raw to DateTime
   ↓
5. Check for existing reminder (prevent duplicates)
   → If exists, skip creation
   ↓
6. Create ReminderRecord in database
   ↓
7. Call NotificationService.scheduleReminder()
   ↓
8. Invalidate reminderListProvider
   ↓
9. UI updates to show new reminder
```

### 10.3 Alarm Behavior

When a reminder triggers:

| Feature | Description |
|---------|-------------|
| Trigger Condition | Exact scheduled time reached |
| Persistence | Works even when app is killed |
| Display | Full-screen alarm screen |
| Sound | Looping alarm sound plays continuously |
| Actions | STOP (dismiss) or SNOOZE (add 5 minutes) |

### 10.4 Boot Receiver

When the device restarts, the system:

1. Receives BOOT_COMPLETED broadcast
2. Queries database for all pending reminders
3. Reschedules each reminder with NotificationService
4. Ensures no reminders are lost after restart

---

## 11. UI Screens

### 11.1 Loading Screen (`/`)

The loading screen appears briefly while checking for existing sessions.

**Purpose:**
- Check SharedPreferences for saved session
- Load user data if session exists
- Determine navigation destination (Login or Home)

### 11.2 Login Screen (`/login`)

The login screen authenticates returning users.

**Components:**
- Email input field with validation
- Password input with visibility toggle
- Sign In button (disabled until valid input)
- Link to signup for new users
- Error messages for failed login attempts

### 11.3 Signup Screen (`/signup`)

The signup screen creates new user accounts.

**Components:**
- Email input with validation
- Password input (minimum 6 characters)
- Confirm password input (must match)
- Sign Up button (validates all fields)
- Link back to login for existing users

### 11.4 Onboarding Screen (`/onboarding`)

The onboarding screen guides new users through initial setup.

**Purpose:**
- Welcome message introducing Omi features
- Request microphone permission for voice capture
- Request notification permission for reminders
- Get Started button to proceed to Home

### 11.5 Home Screen (`/home`)

The home screen is the main interaction point for voice capture.

**Components:**
| Component | Description |
|-----------|-------------|
| Voice Button | Large circular button to start/stop recording |
| Transcript Display | Live text showing what you said |
| Session Stats | Number of chunks, memories, reminders |
| Audio Level | Visual indicator of microphone input |
| Session Status | Shows if recording is active |

### 11.6 Memories Screen (`/memories`)

The memories screen displays all extracted memories.

**Features:**
- Scrollable list of all memories
- Filter chips by memory type
- Tap to view memory details
- Search by content
- Swipe to delete

### 11.7 Memory Detail Screen (`/memory/:id`)

The memory detail screen shows complete information about a memory.

**Components:**
- Full memory content display
- Type badge and importance indicator
- Created date and time
- Edit button to modify content
- Delete button to remove memory
- Related reminder information (if applicable)

### 11.8 Reminders Screen (`/reminders`)

The reminders screen lists all scheduled reminders.

**Components:**
- List of pending and past reminders
- Status indicator (pending, adjusted, done, expired)
- Scheduled time display
- Source memory content preview
- Snooze button (adds 5 minutes)
- Dismiss button (marks as expired)

### 11.9 Sessions Screen (`/sessions`)

The sessions screen shows history of recording sessions.

**Components:**
- List of past sessions sorted by date
- Session duration display
- Memory count per session
- Transcript snippet preview
- Tap to view session details

### 11.10 Settings Screen (`/settings`)

The settings screen provides app configuration options.

**Components:**
| Setting | Description |
|---------|-------------|
| Theme | Toggle between light and dark mode |
| Notifications | Enable/disable reminder notifications |
| Account | View logged-in email |
| Logout | Sign out and clear session |

### 11.11 Alarm Screen (`/alarm`)

The alarm screen displays when a reminder triggers.

**Visual Design:**
- Dark background (#0A0E1A)
- Large pulsing alarm icon animation
- "ALARM" title with "Time to wake up!" subtitle
- Large red STOP button to dismiss
- Orange SNOOZE button (+5 minutes)

---

## 12. Navigation Flow

### 12.1 Initial Launch

When a new user opens the app for the first time:

```
/ → /login (no session exists)
```

### 12.2 Returning User (Auto-Login)

When a user with existing session opens the app:

```
/ → /home (session restored)
```

### 12.3 After Login

```
/login → /onboarding (first time) → /home
       → /home (if onboarding completed)
```

### 12.4 Route Categories

**Auth Routes (No Bottom Navigation):**
| Route | Screen | Purpose |
|-------|--------|---------|
| `/login` | Login Screen | User authentication |
| `/signup` | Signup Screen | Account creation |
| `/onboarding` | Onboarding Screen | Initial setup |
| `/alarm` | Alarm Screen | Reminder display |

**Shell Routes (Bottom Navigation):**
| Route | Screen | Tab |
|-------|--------|-----|
| `/home` | Home Screen | Home (index 0) |
| `/memories` | Memories Screen | Memories (index 1) |
| `/reminders` | Reminders Screen | Reminders (index 2) |
| `/sessions` | Sessions Screen | Sessions (index 3) |
| `/settings` | Settings Screen | Settings (index 4) |

### 12.5 Bottom Navigation Structure

The app uses a bottom navigation bar with 5 tabs for main navigation. Each tab shows a different feature area while maintaining the navigation bar at the bottom.

---

## 13. API Integration

### 13.1 Gemini API

The app uses Google Gemini for AI-powered memory extraction.

**Endpoint:**
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
```

**API Key Configuration:**
The API key is stored in a `.env` file and loaded at runtime:
```
GEMINI_API_KEY=your_api_key_here
```

**Request Format:**
```json
{
  "contents": [{
    "parts": [{
      "text": "You are a memory extraction engine..."
    }]
  }],
  "generationConfig": {
    "temperature": 0.2,
    "responseMimeType": "application/json",
    "responseJsonSchema": {...}
  }
}
```

### 13.2 Error Handling Strategy

| Error Condition | Handling |
|-----------------|----------|
| No API key configured | Use keyword-based fallback parser |
| API timeout (18 seconds) | Retry up to 3 times, then fallback |
| Network unavailable | Use fallback parser |
| JSON parsing fails | Use fallback parser |
| Invalid response format | Use fallback parser |

---

## 14. Security

### 14.1 Password Security

| Practice | Implementation |
|----------|----------------|
| Hashing algorithm | SHA-256 (one-way, irreversible) |
| Storage | Hashed password only, never plain text |
| Verification | Compare hashes, not plain text |

### 14.2 API Key Security

| Practice | Implementation |
|----------|----------------|
| Storage | `.env` file, not in source code |
| Loading | Runtime only via flutter_dotenv |
| Access | Environment variable, not hardcoded |

### 14.3 Session Security

| Practice | Implementation |
|----------|----------------|
| Storage | SharedPreferences (device-local) |
| Session data | User ID and email only |
| Logout | Clear all session data immediately |

### 14.4 Data Storage Security

| Practice | Implementation |
|----------|----------------|
| Database | SQLite stored in app documents directory |
| Access | Protected by OS file permissions |
| Root/Jailbreak | Data not encrypted (device-level security) |

---

## 15. Error Handling

### 15.1 Global Error Fallback

When an unhandled error occurs in the app:

```dart
ErrorWidget.builder = (details) => _ErrorFallback(error: details.exception);
```

**Error Fallback Screen:**
- Displays error icon
- Shows "Something went wrong" message
- Provides "Go Back" button to recover

### 15.2 Navigation Errors

For invalid routes, GoRouter displays a custom error page:

- Shows "Page not found" message
- Provides button to navigate home
- Logs error for debugging

### 15.3 Service Errors

All external calls are wrapped in try-catch blocks:

| Service | Error Handling |
|---------|----------------|
| Database | Return empty list on query failure |
| Gemini API | Fallback to keyword parser |
| Notifications | Log error, don't crash app |
| Transcription | Show error message, allow retry |

---

## 16. Build & Deployment

### 16.1 Development Build

To build a debug version for testing:

```bash
flutter build apk --debug
```

### 16.2 Release Build

To build a production release:

```bash
flutter build apk --release
```

### 16.3 APK Location

After building, the APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 16.4 Android Configuration

**Minimum SDK:** 21 (Android 5.0)  
**Target SDK:** 34 (Android 14)

**Required Permissions:**
| Permission | Purpose |
|------------|---------|
| RECORD_AUDIO | Voice recording |
| POST_NOTIFICATIONS | Show notifications |
| SCHEDULE_EXACT_ALARM | Exact alarm timing |
| USE_EXACT_ALARM | Use exact alarm feature |
| RECEIVE_BOOT_COMPLETED | Reschedule after restart |
| VIBRATE | Vibration on notification |
| WAKE_LOCK | Keep device awake for alarms |
| FOREGROUND_SERVICE | Background notification service |
| FOREGROUND_SERVICE_MEDIA_PLAYBACK | Play alarm sounds |

---

## 17. Project Structure

```
omi/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # App configuration, routing, theme
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Light and dark themes
│   │   ├── services/
│   │   │   └── notifications_services.dart  # Notification handling
│   │   ├── utils/
│   │   │   └── date_time_parser.dart # Date/time extraction
│   │   └── widgets/
│   │       └── glass_card.dart       # Glass morphism card widget
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_record.dart      # User data model
│   │   │   ├── memory_record.dart    # Memory data model
│   │   │   ├── reminder_record.dart   # Reminder data model
│   │   │   └── session_record.dart   # Session data model
│   │   └── local/
│   │       └── app_database.dart      # Drift database definition
│   └── features/
│       ├── auth/
│       │   ├── services/
│       │   │   ├── auth_service.dart   # Authentication logic
│       │   │   └── session_helper.dart  # Session management
│       │   ├── providers/
│       │   │   └── auth_provider.dart   # Auth state provider
│       │   └── screens/
│       │       ├── login_screen.dart    # Login UI
│       │       └── signup_screen.dart   # Signup UI
│       ├── memory/
│       │   ├── services/
│       │   │   └── gemini_service.dart  # AI extraction service
│       │   └── providers/
│       │       └── memory_provider.dart # Memory state provider
│       ├── reminder/
│       │   ├── services/
│       │   │   └── reminder_manager.dart # Reminder scheduling
│       │   └── providers/
│       │       └── reminder_provider.dart # Reminder state
│       ├── alarm/
│       │   └── screens/
│       │       └── alarm_screen.dart     # Alarm display UI
│       ├── transcription/
│       │   ├── services/
│       │   │   └── transcription_service.dart # Speech-to-text
│       │   └── providers/
│       │       └── transcription_provider.dart # Transcription state
│       ├── sessions/
│       │   └── providers/
│       │       └── session_provider.dart # Session state
│       ├── audio/
│       │   ├── services/
│       │   │   └── audio_services.dart   # Audio recording
│       │   └── providers/
│       │       └── audio_provider.dart   # Audio state
│       ├── settings/
│       │   └── providers/
│       │       └── settings_provider.dart # Settings state
│       └── ui/
│           └── screens/
│               ├── home_screen.dart           # Main dashboard
│               ├── memory_list_screen.dart    # Memory browser
│               ├── memory_detail_screen.dart  # Memory view/edit
│               ├── reminders_screen.dart       # Reminder list
│               ├── sessions_screen.dart        # Session history
│               ├── settings_screen.dart        # App settings
│               └── onboarding_screen.dart      # First-time setup
├── pubspec.yaml                    # Dependencies
├── .env                           # Environment variables
├── android/                       # Android configuration
└── ios/                          # iOS configuration
```

---

## Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1        # State management
  flutter_dotenv: ^5.2.1          # Environment variables
  drift: ^2.18.0                  # SQLite ORM
  sqlite3_flutter_libs: ^0.5.24   # SQLite native libraries
  go_router: ^14.0.0              # Navigation
  speech_to_text: ^7.0.0          # Speech recognition
  flutter_local_notifications: ^17.2.2  # Notifications
  android_alarm_manager_plus: ^3.0.2    # Alarm manager
  audioplayers: ^6.0.0            # Audio playback
  flutter_timezone: ^4.1.1        # Timezone handling
  timezone: ^0.9.4                # Timezone database
  http: ^1.2.1                    # HTTP client
  crypto: ^3.0.3                  # Password hashing
  shared_preferences: ^2.3.2      # Local storage
  google_fonts: ^6.2.1             # Typography
  uuid: ^4.4.0                     # Unique IDs
  permission_handler: ^11.3.1      # Permissions
  intl: ^0.19.0                   # Date formatting
```

---

## Environment Variables (.env)

```env
# Gemini API Key - Get from https://aistudio.google.com/app/apikey
GEMINI_API_KEY=your_api_key_here
```

**Getting an API Key:**
1. Visit https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key
5. Paste it in the `.env` file

---

## Testing

### Manual Test Cases

#### 1. Signup Flow
- [ ] Enter invalid email → Show validation error
- [ ] Enter short password → Show length requirement error
- [ ] Enter mismatching passwords → Show confirmation error
- [ ] Valid input → Create account → Navigate to Home

#### 2. Login Flow
- [ ] Wrong email → Show "No account found"
- [ ] Wrong password → Show "Incorrect password"
- [ ] Valid credentials → Navigate to Home

#### 3. Auto-Login
- [ ] Close app, reopen → Should stay logged in
- [ ] Logout → Close app, reopen → Should show Login

#### 4. Voice Recording
- [ ] Tap mic → Start recording with visual feedback
- [ ] Speak → See live transcript on screen
- [ ] Tap stop → Process and save transcript

#### 5. Memory Creation
- [ ] Say "Remind me to call mom after 5 minutes"
- [ ] See memory appear in Memories list
- [ ] See reminder appear in Reminders list
- [ ] Wait for reminder to trigger

#### 6. Reminder Notification
- [ ] Wait for scheduled time
- [ ] See alarm screen appear
- [ ] Tap STOP → Dismiss and go home
- [ ] Or tap SNOOZE → Delay 5 minutes

#### 7. Theme Toggle
- [ ] Go to Settings
- [ ] Toggle theme switch
- [ ] See UI colors change immediately

---

## Known Limitations

| Limitation | Description |
|------------|-------------|
| Offline AI | Without API key, uses basic keyword parsing |
| No Cloud Sync | All data stored locally only |
| Android Only Features | Exact alarms, boot receiver (Android specific) |
| iOS Background | Limited notification handling on iOS |

---

## Future Enhancements

Potential improvements for future versions:

- [ ] Cloud backup using Firebase or Supabase
- [ ] Multi-user account support
- [ ] Share memories with others
- [ ] Export/Import data functionality
- [ ] Home screen widget
- [ ] Wearable device support (smartwatch)
- [ ] TV app version
- [ ] Web platform support

---

## License

This project is proprietary and confidential.

---

## Support

For issues or questions, please refer to the repository or contact the development team.
