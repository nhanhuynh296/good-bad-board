# Good Bad Board Club Management System
#### User Stories:

1. **Player Search:**
    - **As a club manager**, I want to search for players efficiently so I can quickly find and manage player information.
    - **Acceptance Criteria:**
        - The search function must return accurate player information within 2 seconds of entering a name or ID.
        - The search results should include players' full names, IDs, and ELO ratings.

2. **Game Timer:**
    - **As a club manager**, I want to use a game timer for both time-based (e.g., 12 minutes per game) and game-based match management to ensure games run smoothly.
    - **Acceptance Criteria:**
        - The timer must have options to set specific game durations (e.g., 12 minutes).
        - The timer must have a start, pause, and reset functionality.
        - For game-based matches, the timer should reset after each match ends and notify the next players to start.

3. **Import/Export Players:**
    - **As a club manager**, I want to import and export player data to easily update and backup information.
    - **Acceptance Criteria:**
        - The import function must support CSV and Excel formats.
        - The export function must allow downloading player data in CSV and Excel formats.
        - Imported data should be validated and display errors for any invalid entries.

4. **Export Game:**
    - **As a club manager**, I want to export game details for record-keeping and analysis.
    - **Acceptance Criteria:**
        - Game exports must include player participation, game duration, and type.
        - The export file should be in CSV or Excel format.
        - The export should be completed within 3 seconds.

5. **Paying Tracker:**
    - **As a club manager**, I want to track payments to ensure all players' dues are managed correctly.
    - **Acceptance Criteria:**
        - The payment tracker should log all payments with player details and amounts.
        - It must have a report generation feature to display unpaid dues and payment histories.
        - The payment data should be exportable in CSV or Excel formats.

6. **Persistent Settings:**
    - **As a club manager**, I want to have persistent settings to maintain my preferences and configurations across sessions.
    - **Acceptance Criteria:**
        - Settings should be saved automatically and loaded on each login.
        - Changes to settings should be reflected immediately.
        - A clear indication must be shown when settings are saved successfully.

7. **Click to Move, Highlight:**
    - **As a club manager**, I want to click to move and highlight players, making it easy to manage and organize player rosters and game assignments dynamically.
    - **Acceptance Criteria:**
        - Clicking a player should highlight and allow them to be moved to different rosters or games.
        - The highlighted state should be visually distinct.
        - Changes should be saved dynamically without page reloads.

8. **Add All Players:**
    - **As a club manager**, I want to add players to the game, including an option to add all players at once, saving time during setup.
    - **Acceptance Criteria:**
        - An “Add All Players” button should be available to add all active players to a game.
        - The addition should take effect immediately and show all players in the game roster.

9. **Remove Player (Marking Unavailable):**
    - **As a club manager**, I want to remove or mark players as unavailable when needed, ensuring game rosters are up-to-date.
    - **Acceptance Criteria:**
        - Players can be marked as unavailable by clicking a button next to their name.
        - Unavailable players should visually differentiate from available players.
        - Changes in player availability should update immediately.

10. **Statistics Page:**
    - **As a club manager**, I want to view detailed statistics to analyze player and game activities.
    - **Acceptance Criteria:**
        - The page should show the number of games each player has participated in.
        - It should display the average number of games played per player.
        - ELO rating distribution should be shown in bar or pie charts.
        - An activity timeline should graph the number of games played and player sign-ups over time.
        - Total number of players and new registrations over specified periods should be shown.
        - Game frequency and distribution should be displayed.
        - Top active players based on participation should be listed.

#### Additional System Requirements:
1. **Data Points Inclusion:**
    - Player's full name, combining first and last names.
    - Date of birth (if available).
    - Game metadata, including game duration and type.

2. **Visualization Tools:**
    - Use bar and pie charts for ELO distribution, game frequencies, and player participation.
    - Line charts for trends over sign-ups and games played over time.
    - Tables for top active players and detailed participation stats.

3. **User-friendly Interface:**
    - The interface should be clean and intuitive, with tooltips and legends in charts.

4. **Filtering Options:**
    - Allow users to view data based on specific time frames, ELO ratings, and other criteria.

5. **Export Data Functionality:**
    - Allow exporting of data in CSV or Excel formats for offline analysis.

#### Low Priority Features:
1. **White-Labeled Solutions:**
    - Customizable themes, logos, and colors.
    - Unique URL and app store listing for the club.
