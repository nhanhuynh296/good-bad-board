# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter desktop (Windows) badminton board organizer — player registration, automated matchmaking with Elo-skill balancing, game timer, and player statistics.

## Communication style
Use ASD-STE-100 skill when you speak to the operator.

## Agent skills

### Issue tracker

GitHub Issues in `nhanhuynh296/good-bad-board`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Build

The `just generate` step is required after modifying any `@freezed` model or JSON-serializable class — it regenerates `*.freezed.dart` and `*.g.dart` files.

## UX-Redesign

UX-Redesign contains ALL the context for the new UX design.
- ARCHITECTURE.md contains the design tokens
- IMPLEMENTATION.md contains the implementation, phases, task and high level UAT. 
- UAT.md contains the user acceptance testing plan. 
- PERSISTENCE.md contains the data-layer handoff — current storage design, measured benchmarks, four known defects, and the agreed implementation plan.
- All the HTMLs contain a rendered app, however it might not be 100% accurate to the app features. 
Some features are still being decided, there will be drift between HTML and features.Refer to UAT.md and IMPLEMENTATION.md as the source of truth for features.
- If after any changes in features, new test written, ALWAYS check of outdated information and update [ARCHITECTURE.md](UX-Redesign/ARCHITECTURE.md), [IMPLEMENTATION.md](UX-Redesign/IMPLEMENTATION.md) and [UAT.md](UX-Redesign/UAT.md) accordingly

## Domain language

[CONTEXT.md](CONTEXT.md) is the glossary. Use its terms exactly — `Round` and `Game Type` in
particular carry meanings the code comments get wrong. [docs/adr/](docs/adr/) records the
decisions behind them.

## Data layer

Read [UX-Redesign/PERSISTENCE.md](UX-Redesign/PERSISTENCE.md) before changing anything under
`lib/repository/`, `lib/model/`, or the analytics engine. Its mechanism B finding was **wrong**
and is marked corrected — read ADR-0002 before acting on §3.1 or phase 1.

Two rules it exists to protect:
- **Never write a game roster back to disk after dropping unresolvable player ids.** Doing so
  erased 98% of the match history once already. See PERSISTENCE.md §3.1.
- **Tests must never touch the real data directory.** `~/Library/Containers/nz.nathanHuynh.goodBadBoard/Data/Documents/`
  is production data. See PERSISTENCE.md §2.2 and §6 phase 4.

It also records why SQLite was investigated and deferred, with the benchmarks and the conditions
that should trigger revisiting it — do not re-open that question without re-running them
(PERSISTENCE.md §4, §5.2).

## Architecture

See [lib/CLAUDE.md](lib/CLAUDE.md) — state management, data layer, matchmaking, drag-and-drop, and theming.

## Testing Conventions

### TDD Workflow
- Always write failing tests BEFORE implementation
- Use AAA pattern: Arrange-Act-Assert
- One assertion per test when possible
- Test names describe behavior: "should_return_empty_when_no_items"

### Test-First Rules
- When I ask for a feature, write tests first
- Tests should FAIL initially (no implementation exists)
- Only after tests are written, implement minimal code to pass
