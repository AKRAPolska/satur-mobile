# Welcome + Join Program — Design Spec

**Date:** 2026-09-24  
**Status:** Approved for implementation (user: screens A+B only; review on finish)

## Goal

Ship two v1 entry screens with senior-level feature architecture and tests:

1. **Welcome** (`ekran_startowy_poprawiony`) — logo, copy, *Zaloguj się* (no-op), *Dołącz do programu* → join route  
2. **Join program** (`rejestracja_do_platformy_benefity_zakupowe`) — email form wired through use case + stub repository (no HTTP, no email send)

Out of scope: login screen, confirmation-email screen, real Satur API.

## Architecture

Feature-first + domain/data/presentation. Cubit for join form. Manual composition root (no heavy DI framework required; `get_it` optional).

```
lib/
  app/           # MaterialApp, go_router, DI
  core/          # theme tokens, shared buttons/fields
  features/
    welcome/presentation/
    join_program/{domain,data,presentation}/
```

### Domain (join_program)

- `EmailAddress` — value object; trim + lowercase; format validation  
- `JoinProgramFailure` — sealed (`invalidEmail`, `network`, `unknown`) — network reserved for future HTTP  
- `JoinProgramRepository` — `Future<Result<void, JoinProgramFailure>> requestAccess(EmailAddress email)`  
- `JoinProgram` use case — validate → repository  

### Data

- `StubJoinProgramRepository` — ~300ms delay, always success (simulates latency). Swap later for `HttpJoinProgramRepository`.

### Presentation

- `WelcomeScreen` — pure UI; login button `onPressed: null` behavior via empty callback that does nothing (button remains enabled visually but handler is empty `() {}`)  
- `JoinProgramCubit` states: `idle` | `invalidEmail` | `submitting` | `success` | `failure`  
- On success: stay on screen, show SnackBar „Zgłoszenie przyjęte” (no navigation to mail-sent screen)  
- Footer „Zaloguj się” on join screen: no-op  

### Routing

- `/welcome` — initial  
- `/join-program` — join form  
- Back from join → `/welcome`

## UI (from design docs)

Tokens from `DESIGN.md`: primary `#003684`, primary-container `#214ea2`, background/surface, Arimo via `google_fonts`.

**Welcome:** centered logo (`assets/brand/satur_logo.png`), title „Witaj w Satur”, subtitle „Twoje centrum technologii i biznesu.”, primary filled CTA + outline CTA at bottom. Prefer DS radii (full/rounded) over heavy shadows.

**Join:** light blue-tinted background, white card, badge „BENEFITY ZAKUPOWE”, title/subtitle/body, 3 benefit stats (0 zł / 2× / 80%), email field + „Zarejestruj się”, trust line, back link + „Masz już konto? Zaloguj się” (no-op).

Note: join mock uses Inter/cards — implement with Arimo + DS colors; keep layout structure from mock.

## Testing

| Layer | What |
|-------|------|
| Domain | `EmailAddress` valid/invalid; `JoinProgram` happy path + invalid skips repo |
| Cubit | `bloc_test`: invalid → `invalidEmail`; valid → submitting → success (stub) |
| Widget | Welcome shows both CTAs; Dołącz navigates; Zaloguj does not push routes |
| Widget | Join shows field/button; submit invalid shows error; valid reaches success UI |

## Non-goals

- Password login UI  
- Real API / email delivery  
- Confirmation screen after join  
- Account / B2B screens  
