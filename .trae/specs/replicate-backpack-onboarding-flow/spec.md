# Replicate Backpack Onboarding Flow Spec

## Why
The current "Create Wallet" and "Import Wallet" pages in the Flutter app are low-fidelity test pages. To provide a production-grade user experience that matches the Backpack wallet, we need to implement "pixel-perfect" replicas of these onboarding flows, including precise UI layout, interaction steps, and security warnings.

## What Changes
- **Refactor `CreateWalletPage`**:
  - Implement a multi-step flow matching Backpack's UX:
    1.  **Recovery Phrase Warning**: Explicit risk acknowledgment before generation.
    2.  **Mnemonic Display**: Clear, numbered grid layout for 12/24 words. Support copying to clipboard with visual feedback.
    3.  **Mnemonic Verification**: Interactive verification step (e.g., select specific words or full verification) to ensure user backup.
    4.  **Success/Name**: Set wallet name and finish.
  - Remove the generic "Step 1/2/3" stepper UI and replace with a focused, single-purpose view for each stage.
  - Apply Backpack design tokens (colors, typography, spacing).

- **Refactor `ReplicaImportWalletPage`**:
  - Implement a clean import interface:
    1.  **Input Area**: Large text area for mnemonic input with auto-trim and validation.
    2.  **Word Count Validation**: Real-time validation of word count (12/24) and BIP39 word validity.
    3.  **Account Discovery**: (Optional/Mock) Simulate finding accounts.
    4.  **Success State**: Clear feedback upon successful import.
  - Match Backpack's visual style for inputs and buttons.

- **Refactor `ReplicaOnboardingEntryPage`**:
  - Ensure the entry point aligns with the new flows (already partially done, but verify transitions).

## Impact
- Affected specs: `replicate-backpack-multi-platform-ui`
- Affected code:
  - `lib/pages/create_wallet_page.dart`
  - `lib/pages/replica_import_wallet_page.dart`
  - `lib/pages/replica_onboarding_entry_page.dart`
  - `lib/widgets/inputs/wallet_text_field.dart` (if updates needed)

## ADDED Requirements
### Requirement: Backpack-style Create Wallet Flow
The system SHALL provide a "Create Wallet" flow that mimics Backpack's steps:
1.  **Warning Screen**: Users MUST acknowledge that they are responsible for their recovery phrase.
2.  **Phrase Generation**: Users SHALL see a 12-word (default) or 24-word recovery phrase in a secure, obscured-by-default or clear grid layout.
3.  **Phrase Verification**: Users SHALL verify their phrase (e.g., by selecting the correct word for a given index) to confirm backup.

#### Scenario: User creates a new wallet
- **WHEN** user selects "Create new wallet"
- **THEN** they are guided through warning -> view phrase -> verify phrase -> name wallet -> success.

### Requirement: Backpack-style Import Wallet Flow
The system SHALL provide an "Import Wallet" flow that mimics Backpack's interface:
1.  **Secret Phrase Input**: A dedicated input area that accepts 12 or 24 words.
2.  **Validation**: The system SHALL validate the mnemonic checksum and word validity.
3.  **Import Action**: Upon valid input, the system imports the wallet and navigates to the home screen.

#### Scenario: User imports a wallet
- **WHEN** user enters a valid 12-word mnemonic
- **THEN** the "Import" button becomes active, and clicking it imports the wallet.

## MODIFIED Requirements
### Requirement: UI Polish
All onboarding pages SHALL use `AppColorTokens` and `AppTypographyTokens` to strictly match the Backpack dark mode aesthetic (Background `#0E0F14`, Surface `#14151B`, Primary `#FFFFFF`, etc.).
