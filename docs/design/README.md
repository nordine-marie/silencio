# Design system & screens (reference)

Imported from the Claude Design project
[Silencio call blocker design](https://claude.ai/design/p/a22342cd-b851-4cd5-b8f7-6ce5ce6d79f4).

**Reference only.** These files are not part of the app build — they document the
visual language and the intended screen flow so implementation can match the design.

## Files

| File | What it is |
| --- | --- |
| [`design-system.html`](./design-system.html) | Brand & tone, color palette, typography scale, spacing/radius, components, iconography. |
| [`screens.html`](./screens.html) | The 7 core screens: Promise → How it works → Activation → Success → Home (active) → Home (paused) → Custom block list. |

Open either file directly in a browser — they are self-contained (only web font
`Figtree` is loaded from Google Fonts) and require no build step or runtime.

## Design language at a glance

- **Feeling:** relief and calm. Reassuring, premium-but-warm, credible. No dark
  patterns, no countdowns, no fake urgency.
- **Color system:** warm cream base (`#F4F1EA`); brick **red** (`#A8443A`) is the
  color of protection ("the wall is up"); plum (`#574766`) as secondary accent;
  amber (`#B8863A`) for the paused state; green (`#4E7A5B`) for confirmation.
  Telecom blue is deliberately avoided.
- **Typography:** neutral, legible sans in the iOS spirit (SF Pro natively).
  Nothing below 15px in-app; first-class Dynamic Type & VoiceOver.
- **Targets:** touch targets ≥ 60px tall — designed for a senior audience.
- **Language:** French first.

## Note on naming

These pages have been updated to the current product name, **Silencia** (renamed
from "Silencio" — see commit `7497cc3`). The upstream Claude Design project and its
source files are still named "Silencio"; if you re-import, re-apply the rename.

## Updating

To re-import after the design changes upstream, re-fetch the project files via the
`claude_design` MCP (`/design-login` to authenticate) and regenerate these
standalone pages, then rename "Silencio" → "Silencia". The source canvas docs are
`Silencio.dc.html` (screens) and `Silencio - Design System.dc.html`, which wrap the
same markup in the Claude Design `<x-dc>` runtime.
