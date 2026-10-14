# Free Pulse Check — UI designs

Dark, gradient, bold. Canvas is 393 × 852 pt (iPhone Pro). Each screen is an SVG with a 3× PNG render (1179 × 2556) beside it.

| File | Screen |
|---|---|
| `01-measure-tab` | Measure tab: glowing Start button hero card, three most recent results, "See all" link to History |
| `02-measure-empty` | Measure tab with no results yet: empty-state card in place of the list |
| `03-sheet-waiting-finger` | Measurement cover, before a finger is detected: fingertip-on-camera illustration, "Waiting for finger" pill |
| `04-sheet-finger-prompts` | Component sheet of the five finger-state banners (partial, pressure, saturated, too dark, lifted/paused) |
| `05-sheet-calibrating` | "Hold still…" with an indeterminate ring and shimmer bar. No BPM yet, quality shows "Reading…" |
| `06-sheet-measuring` | Live: gradient progress ring, BPM, countdown, signal quality chip, live PPG waveform |
| `07-sheet-result` | Result: BPM, RMSSD and SDNN, quality, waveform thumbnail, Apple Health toggle, Save / Discard |
| `08-sheet-failed` | Unreliable reading: reasons (moved too much, finger lifted), Try Again / Close |
| `09-history-tab` | History grouped by Today / Yesterday / Earlier. One row is mid-swipe, showing Delete |
| `10-settings-tab` | Settings: Apple Health status, fixed 60 s duration, disclaimer, licenses (ClimbPulse, MIT), privacy, version |
| `11-camera-denied` | Camera permission denied: camera.slash glyph, explanation, Open Settings |

## Design tokens

**Color**

| Token | Value | Use |
|---|---|---|
| `background` | `#0B0B10` | Screen background |
| `surface` | `#16161E` | Cards, grouped lists |
| `surfaceElevated` | `#1F1F2A` | Chips, secondary buttons, close button |
| `separator` | `#2A2A35` | Hairlines (0.5 pt) |
| `textPrimary` | `#FFFFFF` | |
| `textSecondary` | `#8E8E9A` | Units, subtitles, footers |
| `textTertiary` | `#5A5A66` | Section micro-labels, placeholders, chevrons |
| `accentGradient` | `#FF2D55` → `#FF6B9A` | Primary button, ring, selected tab, BPM on Result. Diagonal on shapes, horizontal on strokes and buttons |
| `accent` | `#FF6B9A` | Links, text-only buttons, HRV chip text |
| `accentTint` | `#2A1520` | HRV chip fill, empty-state icon disc |
| `qualityGood` / `Fair` / `Poor` | `#30D158` / `#FFD60A` / `#FF453A` | Quality dots and chips |
| `warning` | `#FF9F0A` | Saturated and too-dark banners |
| `destructive` | `#FF3B30` | Swipe-to-delete |

Glow: the same gradient behind the element, Gaussian blur radius about 14 pt, opacity 0.45–0.75.

**Radii**: card 20, button 18, chip and pill capsule (height ÷ 2), settings icon tile 7, phone illustration 40.

**Type** (SF Pro):

| Style | Size / weight | Example |
|---|---|---|
| Hero numeral | 84–96 / heavy | Live and result BPM |
| Large title | 34 / bold | Tab titles |
| Title | 26–30 / bold | Sheet headlines |
| Card numeral | 24–34 / bold | Row and card BPM, HRV values |
| Headline | 17 / semibold | Nav titles, buttons |
| Body | 15–16 / regular | Row titles, explanations |
| Footnote | 13–14 / regular | Dates, footers, chips |
| Micro label | 11 / bold, +1 tracking, uppercase | `LIVE PULSE`, `HEART RATE VARIABILITY` |
| Tab label | 10 / semibold | |

**Spacing**: 16 pt screen margin to card edges, 18–20 pt inset inside cards, 10–12 pt between stacked cards. List rows are 56–62 pt tall, 66 pt with a subtitle. The tab bar is 83 pt including the home indicator.
