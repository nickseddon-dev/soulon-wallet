# Tasks

- [x] Task 1: Refactor "Create Wallet" Flow: Implement a multi-step Backpack-style creation process.
  - [x] SubTask 1.1: Create "Warning" Screen: Explain risks (BIP39 offline storage) and get confirmation.
  - [x] SubTask 1.2: Create "Mnemonic View" Screen: Display generated 12/24 words in a grid, with copy button.
  - [x] SubTask 1.3: Create "Verify Phrase" Screen: Prompt user to verify specific words (e.g., word #3 and #7).
  - [x] SubTask 1.4: Create "Success" Screen: Final confirmation and navigation to Home.

- [x] Task 2: Refactor "Import Wallet" Flow: Implement a clean Backpack-style import interface.
  - [x] SubTask 2.1: Create "Input Phrase" Screen: Text area for 12/24 words with real-time validation.
  - [x] SubTask 2.2: Implement "Account Discovery" Simulation: Mock loading state for account derivation.
  - [x] SubTask 2.3: Create "Success" Feedback: Toast or transition to Home upon success.

- [x] Task 3: Polish Onboarding Entry Point: Ensure smooth transitions and consistent styling.
  - [x] SubTask 3.1: Review `ReplicaOnboardingEntryPage` for any missing Backpack details (e.g., logo, spacing).

# Task Dependencies
- [Task 1] depends on [Task 3] (partially, but can be parallel)
- [Task 2] depends on [Task 3] (partially, but can be parallel)
