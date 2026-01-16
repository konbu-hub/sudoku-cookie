# Phase 2 Implementation Plan: Global Ranking & Points

## Goal Description
Implement a robust Point System based on difficulty and a "Global/National" Ranking system using Cloud Firestore. This allows players to compete with others and track their total accumulated points.

## User Actions Required
> [!IMPORTANT]
> **Firebase Setup Required**: To enable Global Ranking, you must create a Firebase Project, add an Android app (com.kubogame.sudoku_cookie), and place the `google-services.json` file in `android/app/`.

## Proposed Changes

### 1. Point System Logic
#### [MODIFY] [game_provider.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/providers/game_provider.dart)
- Implement point calculation logic:
  - **Easy**: 100 Points
  - **Normal**: 200 Points
  - **Hard**: 300 Points
  - **Daily Bonus**: x1.5 (Optional, future consideration)
- Calculate points upon Game Clear.

### 2. Data Models & Database
#### [NEW] [score_model.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/models/score_model.dart)
- Fields: `uid`, `username`, `difficulty`, `points`, `clearTime`, `createdAt`.

#### [NEW] [ranking_repository.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/repositories/ranking_repository.dart)
- Abstract interface for ranking operations.
- **Local Implementation (Sqflite)**: Stores personal play history.
- **Remote Implementation (Firestore)**:
  - `addScore(Score score)`: Uploads score to 'global_scores' collection.
  - `fetchGlobalRanking(limit: 50)`: Gets top players by total points or time.
  - `fetchUserRank(uid)`: Gets specific user rank.

### 3. UI Implementation
#### [NEW] [ranking_screen.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/screens/ranking_screen.dart)
- **Tabs**:
  1. **Global Ranking (Points)**: "National Ranking" - Sorted by Total Points.
  2. **My History**: Local play history.
- **Components**:
  - `RankingListItem`: Shows Rank #, Username, Avatar (Cookie), Score.
  - `MyRankIndicator`: Sticky footer showing user's current rank.

#### [MODIFY] [pubspec.yaml](file:///c:/Users/konbu/sudoku_cookie_flutter/pubspec.yaml)
- Add `cloud_firestore`, `firebase_core`. Note: User must configure Android build files if they want it to run.
- *Fallback*: If Firebase is not configured, show "Offline Mode" mock data or local only.

## Verification Plan
1. **Point Calculation**: Clear Normal game -> Verify 200 pts added.
2. **Global View**: Open Ranking Screen -> Verify list loads (or shows error if no Firebase).
3. **Mock Data (if offline)**: Verify UI handles empty/error states gracefully.
