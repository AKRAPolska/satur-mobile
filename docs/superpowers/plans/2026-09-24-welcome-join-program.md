# Welcome + Join Program Implementation Plan

> **For agentic workers:** Execute task-by-task. Steps use checkbox syntax.

**Goal:** Implement Welcome and Join Program screens with feature-first architecture, stub join use case, and tests.

**Architecture:** Feature modules (`welcome`, `join_program`) with domain/data/presentation; `go_router`; Cubit; stub repository (no HTTP).

**Tech Stack:** Flutter 3.47+, `flutter_bloc`, `equatable`, `go_router`, `google_fonts`, `bloc_test`, `mocktail`

## Global Constraints

- Screens A+B only; no login screen
- „Zaloguj się” buttons: no-op (empty handler)
- Join must not send email / call Satur API; stub only
- UI tokens from DESIGN.md (Arimo, navy `#003684`)
- Polish copy from design mocks
- Tests required for domain, cubit, widgets

## File map

- Create: `lib/core/theme/satur_colors.dart`, `satur_typography.dart`, `satur_theme.dart`
- Create: `lib/core/widgets/satur_button.dart`, `satur_text_field.dart`, `satur_logo.dart`
- Create: `lib/core/result/result.dart`
- Create: `lib/features/join_program/domain/*`, `data/stub_join_program_repository.dart`, `presentation/*`
- Create: `lib/features/welcome/presentation/welcome_screen.dart`
- Create: `lib/app/di.dart`, `router.dart`, `app.dart`
- Modify: `lib/main.dart`, `pubspec.yaml`
- Test: `test/features/join_program/**`, `test/features/welcome/**`

---

### Task 1: Dependencies + theme + Result

**Files:** `pubspec.yaml`, `lib/core/**`

- [ ] Add deps: `flutter_bloc`, `equatable`, `go_router`, `google_fonts`; dev: `bloc_test`, `mocktail`
- [ ] Register `assets/brand/satur_logo.png`
- [ ] Implement colors/typography/theme matching DESIGN.md
- [ ] Implement sealed `Result<T, E>` with `Success` / `Failure`
- [ ] Shared `SaturButton` (primary/outline), `SaturTextField`, `SaturLogo`

### Task 2: Join domain + stub + tests

**Files:** `lib/features/join_program/domain/**`, `data/stub_*.dart`, `test/features/join_program/domain/**`

- [ ] `EmailAddress.tryParse` / `create`
- [ ] `JoinProgramFailure` sealed
- [ ] `JoinProgramRepository` abstract
- [ ] `JoinProgram` use case
- [ ] `StubJoinProgramRepository` (300ms → Success)
- [ ] Unit tests for email + use case (mock repo)

### Task 3: Join Cubit + tests

**Files:** `presentation/join_program_cubit.dart`, `join_program_state.dart`, tests

- [ ] States with Equatable
- [ ] `emailChanged`, `submit`
- [ ] `bloc_test` coverage

### Task 4: Screens + router + app

**Files:** welcome/join screens, `app/*`, `main.dart`

- [ ] Pixel-faithful layouts from docs (structure + tokens)
- [ ] Routes `/welcome`, `/join-program`
- [ ] Wire Cubit via `BlocProvider` + DI
- [ ] SnackBar on success

### Task 5: Widget tests + verify

- [ ] Welcome navigation / no-op login
- [ ] Join validation + success path
- [ ] `flutter test` green; `flutter analyze` clean
