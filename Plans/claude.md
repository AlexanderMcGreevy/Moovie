# Moovie - Claude Development Notes

## Project Overview
Moovie is an iOS movie ranking app that allows users to rank movies based on multiple criteria including universal aspects (enjoyment, story, acting, etc.) and genre-specific attributes.

## Recent Changes

### Friend Sharing - Phase 1 Complete (2026-04-06)

#### Foundation & Friend Management Implemented
Completed Phase 1 of the friend sharing feature with full friend management infrastructure.

**New Models Created:**
1. `Moovie/Models/Friend.swift` - Friend connection model
2. `Moovie/Models/FriendRequest.swift` - Friend request model
3. `Moovie/Models/SharedRanking.swift` - Shared movie ranking model

**New Views Created:**
1. `Moovie/Views/Friends/AddFriendView.swift` - Add friends via friend code
2. `Moovie/Views/Friends/FriendRequestsView.swift` - Manage incoming requests

**Updated Files:**
1. `Moovie/Models/UserProfile.swift` - Added sharing settings (isPublic, shareRankings, allowFriendRequests)
2. `Moovie/MoovieApp.swift` - Added new models to container
3. `Moovie/Views/Friends/FriendsView.swift` - Complete friend list with preview data

**Phase 1 Features:**

**Friend Management:**
- View list of accepted friends
- See how many movies each friend has ranked
- Delete friends (swipe to delete)
- Friend requests badge when pending requests exist

**Add Friend Flow:**
- Share your unique Friend Code (first 8 chars of UUID)
- Copy code to clipboard with one tap
- Enter friend's username and code
- Optional message with request
- Validation (can't add self, duplicate checks)

**Friend Requests:**
- View all pending incoming requests
- See requester's username and message
- Accept/Decline with visual buttons
- Creates reciprocal friendship on accept
- Shows "sent X ago" timestamp

**Data Models:**

```swift
@Model class Friend {
    var userId: UUID              // Owner
    var friendUserId: UUID         // Friend's ID
    var friendUsername: String
    var status: FriendStatus       // pending/accepted/declined/blocked
    var dateAdded: Date
}

@Model class FriendRequest {
    var fromUserId: UUID
    var toUserId: UUID
    var fromUsername: String
    var message: String?
    var status: FriendRequestStatus
    var dateSent: Date
}

@Model class SharedRanking {
    var friendId: UUID
    var movieId: Int
    // All UserMovieRanking fields mirrored
    var genreScores: [String: Int]
}
```

**User Experience:**

1. **Empty State**: "No Friends Yet" → Big Add Friend button
2. **Friend List**: Shows friends with ranking counts
3. **Requests Badge**: Notification when new requests arrive
4. **Add Friend**: Simple code-based system (no server needed for MVP)

**Preview Data:**
- 2 test friends (Sarah with 1 ranking, Mike with 0)
- 1 pending request from Jessica
- Full preview container setup

See complete roadmap in `FRIEND_SHARING_PLAN.md`

### Friend Sharing - Phase 2 Complete (2026-04-06)

#### Profile Viewing & Ranking Comparison Implemented
Completed Phase 2 with full friend profile viewing and ranking comparison features.

**New Views Created:**
1. `Moovie/Views/Friends/FriendProfileView.swift` - View friend's profile
2. `Moovie/Views/Friends/FriendRankingsView.swift` - Browse friend's rankings
3. `Moovie/Views/Friends/CompareRankingsView.swift` - Side-by-side comparison

**Updated Files:**
1. `Moovie/Views/Friends/FriendsView.swift` - Added navigation to friend profiles

**Phase 2 Features:**

**Friend Profile View:**
- Profile header with avatar, username, bio
- Stats: movies rated, friends since date
- Favorite movie section (highest-rated)
- "View All Rankings" button
- Top movies by genre (same layout as user profile)
- All movies tappable to DetailedMovieView

**Friend Rankings List:**
- View all friend's rankings
- Sort by overall score or genre (same options as MyRankingView)
- Position badges (#1, #2, #3, etc.)
- Score pills showing enjoyment, story, acting
- **"You ranked it" indicator** - Blue badge showing your score
- **Swipe to Compare** - Swipe left on movies you both ranked

**Compare Rankings View:**
- Side-by-side comparison of your ranking vs friend's
- Movie poster and title at top
- **Overall scores** with difference indicator
- **Detailed scores** for all 5 universal aspects:
  - Visual bars showing relative scores
  - Difference badges (+5, -3, etc.)
  - Color-coded (blue for you, green for friend)
- **Genre scores** - Shows all genre scores you both have
- Clear indicators of who rated higher

**Navigation Flow:**
1. Friends tab → Tap friend → Friend profile
2. Friend profile → "View All Rankings" → Friend rankings list
3. Friend rankings → Swipe movie you both ranked → Compare
4. Any movie → Tap → DetailedMovieView

**User Experience Highlights:**

1. **You Ranked It Badge**: Movies you both ranked show blue pill with your score
2. **Compare Button**: Only appears in swipe actions for mutually ranked movies
3. **Visual Comparison**: Horizontal bars make score differences immediately visible
4. **Genre-Specific**: Compare genre scores like scariness, funniness, etc.
5. **Difference Calc**: Shows who rated higher and by how much

**Preview Data:**
- FriendProfileView: 3 sample rankings (The Shining, Grand Budapest, Interstellar)
- FriendRankingsView: 3 movies, 1 shared (The Shining) for compare demo
- CompareRankingsView: Complete comparison with 13-point difference

**Next Steps (Phase 3 - Optional):**
- Export/import ranking data (JSON/AirDrop)
- Privacy settings view
- Block/unfriend management
- CloudKit sync (production version)

### Profile Tab with Sign in with Apple (2026-04-06)

#### Added User Profile Feature with Authentication
Created a new Profile tab with Sign in with Apple integration that displays user information and personalized movie statistics.

**New Files Created:**
1. `Moovie/Models/UserProfile.swift` - Data model for user profile
2. `Moovie/Views/Profile/ProfileView.swift` - Main profile view with stats and top movies

**Files Modified:**
1. `Moovie/ContentView.swift` - Added Profile tab to TabView
2. `Moovie/MoovieApp.swift` - Added UserProfile to model container
3. `Moovie/Views/Friends/ProfileView.swift` → Renamed to `FriendProfilePlaceholder.swift` (resolved duplicate filename conflict)

**Authentication Features:**

**Sign in with Apple:**
- Full integration with AuthenticationServices
- Sign in button on first launch
- Captures user's Apple ID, email, and name
- Stores authentication in UserProfile model
- Sign out option in profile menu

**Sign-In Flow:**
1. User opens Profile tab → sees welcome screen with Sign in with Apple button
2. Taps button → Apple authentication sheet appears
3. User authenticates → Profile created with their name and email
4. Profile view displays with personalized data

**Signed-In Profile Features:**

**Header Section:**
- Profile picture placeholder (circular with person icon)
- Username (from Apple ID or editable)
- Bio/description (editable)
- Settings menu (⋯) with Edit Profile and Sign Out options

**Stats Section:**
- Movies Rated count (from UserMovieRanking query)
- Member Since date (formatted as "MMM yyyy")

**Favorite Movie Section:**
- Shows highest-rated movie (first in finalScore sort)
- Prominently displayed with dividers above and below
- Positioned above genre sections for emphasis
- Displays poster, title, release date, and score out of 10
- Tappable to navigate to DetailedMovieView

**Top Movies by Genre:**
- Shows top-rated movie for each genre category
- Genres included: Horror 💀, Comedy 🤣, Action 💥, Sci-Fi 🌌, Drama 💔, Romance 💖, Thriller 😱
- Each row shows: poster thumbnail, title, release date, genre-specific score
- Only shows genres where user has rated movies
- All movies tappable to navigate to DetailedMovieView

**Components:**
- `StatCard` - Displays stat title and value
- `GenreTopMovieRow` - Displays top movie for a specific genre
- `EditProfileView` - Sheet for editing username and bio

**Data Model - UserProfile:**
```swift
@Model class UserProfile {
    var id: UUID
    var username: String
    var profileImageName: String?
    var bio: String
    var dateJoined: Date
    var appleUserID: String?  // Apple ID for authentication
    var email: String?        // User's email from Apple
}
```

**Authentication Handler:**
- `handleSignInWithApple()` - Processes Apple authentication result
- Creates profile with user's name and email
- Stores Apple user ID for persistence
- `signOut()` - Clears authentication data (keeps profile but removes Apple ID)

**Preview Configuration:**

The preview bypasses Apple authentication for easy testing:
- Profile created with `appleUserID: "preview-user-id"` (bypasses sign-in screen)
- 10 diverse test movies covering all genres:
  - **Favorite**: Parasite (9800 - highest score)
  - **Horror**: The Shining (scariness: 98)
  - **Comedy**: The Grand Budapest Hotel (funniness: 85)
  - **Action**: Mad Max: Fury Road (actionIntensity: 99)
  - **Sci-Fi**: Interstellar (mindBending: 96)
  - **Romance**: La La Land (romanceLevel: 92)
  - **Thriller**: Se7en (suspense: 97)
  - **Drama**: The Shawshank Redemption (emotionalDepth: 98)
  - Plus Inception and Pulp Fiction for variety
- Shows full profile with stats: 10 movies rated, member since current date

**Important Setup Requirements:**

To enable Sign in with Apple in Xcode:
1. Open project in Xcode
2. Select the Moovie target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Sign in with Apple"
6. Ensure you have a valid Team selected in Signing

**Friend Sharing Feature:**
See detailed implementation plan in `FRIEND_SHARING_PLAN.md`

**Future Enhancements:**
- iCloud sync using Apple ID
- Upload custom profile pictures
- Add more stats (average score, genre preferences, etc.)
- Leaderboards and achievements
- Automatic sign-in on app launch if previously authenticated

### Navigation Update - MyRankingView (2026-04-06)

#### Changed Movie Tap Behavior
Updated MyRankingView so tapping a movie navigates to the detailed movie view instead of opening the edit ranking sheet.

**Changes Made:**
- **Tap behavior**: Now uses `NavigationLink` to navigate to `DetailedMovieView`
- **Edit functionality**: Moved exclusively to swipe action (swipe left → Edit button)
- **State management**:
  - Removed `selectedRanking` and `showingEditSheet`
  - Added `rankingToEdit` for sheet presentation
  - Sheet now only opens from swipe action's Edit button

**User Flow:**
1. **Tap a movie** → Navigate to DetailedMovieView (see full info, cast, etc.)
2. **Swipe left → Edit** → Open RankingView sheet (edit scores)
3. **Swipe left → Delete** → Show delete confirmation alert

**File Modified:**
- `Moovie/Views/Rankings/MyRankingView.swift` (lines 65, 143, 189-206)

This creates a more intuitive navigation pattern where tapping shows details (like everywhere else in the app), and editing requires a deliberate swipe action.

### Preview Test Data (2026-04-06)

#### Added Test Movies to Preview
Created comprehensive preview data with 10 diverse movies to test sorting functionality:

**Horror Movies:**
- The Shining (1980) - scariness: 95, suspense: 90
- Get Out (2017) - scariness: 70, suspense: 85, mysteryIntrigue: 80
- Hereditary (2018) - scariness: 88, emotionalDepth: 75

**Comedy Movies:**
- Superbad (2007) - funniness: 92
- The Grand Budapest Hotel (2014) - funniness: 75, visualCreativity: 95

**Action Movies:**
- Mad Max: Fury Road (2015) - actionIntensity: 98, adventureScale: 90
- John Wick (2014) - actionIntensity: 95, suspense: 75

**Sci-Fi:**
- Interstellar (2014) - mindBending: 88, emotionalDepth: 85, adventureScale: 92

**Romance:**
- La La Land (2016) - romanceLevel: 85, soundtrackQuality: 98, emotionalDepth: 78

**Drama:**
- Parasite (2019) - emotionalDepth: 92, suspense: 88, mysteryIntrigue: 85

This allows easy testing of:
- Overall score sorting (shows all 10 movies)
- Horror sorting (shows The Shining, Hereditary, Get Out)
- Comedy sorting (shows Superbad, Grand Budapest)
- Action sorting (shows Mad Max, John Wick)
- Other genre filters

### Genre-Based Sorting Feature (2026-04-06)

#### What Was Added
Added the ability to sort movie rankings by genre-specific criteria (Horror, Comedy, Action, etc.) in addition to the default overall score sorting.

#### Files Modified
- `Moovie/Views/Rankings/MyRankingView.swift`

#### Changes Made

1. **RankingSortOption Enum** (lines 12-59)
   - Created enum with 19 sort options:
     - Overall Score (default)
     - 18 genre-specific options: Action 💥, Comedy 🤣, Horror 💀, Romance 💖, Sci-Fi 🌌, Thriller 😱, Drama 💔, Animation ✨, Fantasy 🌟, Mystery 🕵️, Documentary 🧠, Adventure 🚀, Music 🎼, War 🔥, Western 🐎, History ⏳, Family 🎉, TV Movie 🎬
   - Added `genreScoreKey` property to map sort options to the corresponding keys in `UserMovieRanking.genreScores` dictionary

2. **Sort State** (line 69)
   - Added `@State private var sortOption: RankingSortOption = .overall`

3. **Sorting Logic** (lines 71-88)
   - Implemented `sortedRankings` computed property:
     - When `sortOption == .overall`: sorts all rankings by `finalScore` (descending)
     - When genre-specific: filters rankings that have the selected genre score, then sorts by that score (descending)
   - Only shows movies with the relevant genre score when sorting by genre

4. **Sort Picker UI** (lines 95-111)
   - Added toolbar with Menu containing Picker for sort selection
   - Label shows "Sort" for overall, or just the emoji for genre-specific sorts
   - All 19 sort options available in dropdown menu

5. **Updated List View** (line 189)
   - Changed from `rankings` to `sortedRankings`
   - Passes `sortOption` to `RankingRow` component

6. **RankingRow Updates** (lines 234-326)
   - Added `sortOption` parameter
   - Conditionally displays scores:
     - Overall mode: shows enjoyment 😍, story 📖, acting 🎭
     - Genre mode: shows highlighted genre score + enjoyment + story
   - Genre-specific scores have blue highlight with border
   - Added `getGenreEmoji()` helper function to map sort options to emojis

7. **ScorePill Enhancement** (lines 359-381)
   - Added optional `highlighted` parameter (default: false)
   - Highlighted pills have blue background with border
   - Normal pills keep gray background

8. **Helper Property** (lines 90-113)
   - Added `sortOptionShortName` to extract emoji from sort option for compact display

#### How It Works

**User Flow:**
1. User opens Rankings tab
2. Taps sort button (arrow icon) in top-right
3. Selects a genre from menu (e.g., "Horror 💀")
4. List updates to show only movies with horror scores, sorted by scariness
5. Each row highlights the horror score pill in blue
6. User can switch back to "Overall Score" to see all movies

**Technical Flow:**
1. `sortOption` state changes
2. `sortedRankings` recomputes:
   - Filters rankings with non-nil value for `genreScores[sortOption.genreScoreKey]`
   - Sorts filtered list by that score value
3. UI updates:
   - List shows filtered/sorted rankings
   - `RankingRow` conditionally shows appropriate score pills
   - Sort button label updates to show current sort emoji

#### Data Model Reference

**UserMovieRanking:**
- `finalScore: Int` - Overall score (0-10000) used for default sorting
- `genreScores: [String: Int]` - Dictionary of genre-specific scores (0-100)
  - Keys match `SliderQuestion.id` values
  - Examples: "scariness", "funniness", "actionIntensity"

**SliderQuestion:**
- 5 universal questions (all movies get these)
- 18 genre-specific questions (based on movie genres)
- Each has unique `id` used as key in `genreScores` dictionary

#### Genre Score Keys Mapping
| Sort Option | Dictionary Key | Genre ID(s) |
|------------|----------------|-------------|
| Action 💥 | actionIntensity | 28 |
| Comedy 🤣 | funniness | 35 |
| Horror 💀 | scariness | 27 |
| Romance 💖 | romanceLevel | 10749 |
| Sci-Fi 🌌 | mindBending | 878 |
| Thriller 😱 | suspense | 53 |
| Drama 💔 | emotionalDepth | 18 |
| Animation ✨ | visualCreativity | 16 |
| Fantasy 🌟 | worldBuilding | 14 |
| Mystery 🕵️ | mysteryIntrigue | 80, 9648 |
| Documentary 🧠 | educationalValue | 99 |
| Adventure 🚀 | adventureScale | 12 |
| Music 🎼 | soundtrackQuality | 10402 |
| War 🔥 | warIntensity | 10752 |
| Western 🐎 | westernVibes | 37 |
| History ⏳ | historicalAccuracy | 36 |
| Family 🎉 | familyFriendly | 10751 |
| TV Movie 🎬 | tvProduction | 10770 |

## Architecture Notes

### Navigation Structure
- Tab-based app with 5 tabs:
  1. Rankings (MyRankingView) - Shows all ranked movies
  2. Add (AddMovieView) - Search and add movies to rank
  3. Movies (TopMoviesView) - Browse popular movies
  4. Friends (FriendsView) - Social features
  5. Profile (ProfileView) - User profile with stats and top movies by genre

### Ranking System
- **4-step ranking process:**
  1. Universal questions (5 sliders: enjoyment, story, acting, soundtrack, rewatchability)
  2. Genre-specific questions (based on movie's genres)
  3. Comparative ranking (compare against existing movies)
  4. Confirmation (show final position)

- **Score calculation:**
  - Universal scores weighted: enjoyment (35%), story (25%), acting (15%), soundtrack (15%), rewatchability (10%)
  - Final score: 0-10000 scale
  - Genre scores: 0-100 scale (stored separately)

### Data Storage
- SwiftData for persistence
- `@Query` for reactive data fetching
- **Data Models:**
  - `UserMovieRanking` - Stores movie rankings with scores
  - `UserProfile` - Stores user profile information
- Genre scores stored as JSON in `genreScoresData`, decoded to dictionary

## Future Enhancements

### Potential Features
1. **Multi-sort/Filter:**
   - Combine genre sorting with additional filters (year, date ranked, etc.)
   - Save favorite sort configurations

2. **Genre Score Visualization:**
   - Show radar chart of genre scores
   - Compare genre scores across multiple movies

3. **Smart Genre Detection:**
   - Auto-highlight dominant genres for each movie
   - Suggest which genre sort to use based on user's viewing history

4. **Export/Share:**
   - Share top movies by genre
   - Export genre-specific rankings as lists

5. **Statistics:**
   - Show average scores per genre
   - Identify favorite genres based on high scores
   - Trends over time per genre

## Development Notes

### Building the Project
- Requires Xcode (not just Command Line Tools)
- iOS Simulator target: iPhone 15
- Scheme: Moovie

### Key Dependencies
- SwiftUI for UI
- SwiftData for persistence
- Kingfisher for image loading (movie posters)

### Code Style
- Clear separation of concerns with MARK comments
- Computed properties for derived data
- State management with @State and @Query
- Reusable components (RankingRow, ScorePill)

---

**Last Updated:** 2026-04-06
**Last Modified By:** Claude Code
