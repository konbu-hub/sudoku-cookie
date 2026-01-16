# Sudoku Project Roadmap [DONE]

## Phase 4-10: Complete [DONE]
- [x] Blue Aesthetic & True Transparency
- [x] Mascot Interaction Gimmick
- [x] Game UI & NumberPad Redesign
- [x] Audio Overhaul (Assets & Mapping)

## Phase 16: BGM Persistence Fix [DONE]
- [x] Configure `AudioContext` in `AudioController` to allow mixing
- [x] Verify BGM continues during Title -> Ranking transition
- [x] Verify BGM continues during Title -> Settings transition
- [x] Verify SFX (click) does not stop BGM

## Phase 17: Taunt, Tracking & UI Polish [DONE]
- [x] UI: Fix Taunt Bubble overflow (Keep text readable on zoom)
- [x] Feature: Track "Chickened Out" (Run Away) count
- [x] UI: Display "Run Away" count in Ranking/My Summary
- [x] Feature: Add Taunt/Run Away logic to Title Screen Difficulty Dialog

## Phase 18: Title Screen Redesign [DONE]
- [x] Remove "クボゲー Vol.1" text
- [x] Style "おしゃべりクッキーのSUDOKU" (Dark/Evil aesthetic)
- [x] Apply typography enhancements (Shadows, Colors, Size)
- [x] Add version text ("Ver 1.0.0") to bottom right

## Phase 11: BGM Transition Continuity [DONE]
- [x] Persist Title BGM through all menu screens (Robustness keep-alive)
- [x] Ensure BGM switches to Main only at game start
- [x] Resume Title BGM seamlessly upon returning to title
- [x] Verify seamless transition (Debug logs enabled)
