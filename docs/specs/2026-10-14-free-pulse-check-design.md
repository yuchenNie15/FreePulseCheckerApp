# Free Pulse Check — Design

**Date:** 2026-10-14
**Status:** Approved for implementation
**Repo:** `git@github.com:yuchenNie15/FreePulseCheckerApp.git`
**Mockups:** [`docs/designs/`](../designs/README.md)

## 1. Goal

A free iPhone app — no ads, no subscriptions, no network — that measures heart rate and heart-rate
variability (HRV) from a fingertip placed over the rear camera and torch. It is also a test of
spec-driven development with AI: this document is the source of truth the implementation plan and
code are checked against.

The app is a wellness tool, not a medical device, and says so in Settings and on every result.

### In scope (v1)

- Measure tab: hero **Start Measurement** button and the **3 most recent** results.
- 60-second full-screen measurement with live BPM, waveform and finger guidance.
- Result screen with BPM, RMSSD, SDNN, signal quality; **Save** or **Discard**.
- Results persisted on device and written to Apple Health (heart rate + HRV SDNN).
- History tab (all results, delete) and Settings tab (Health status, disclaimer, licenses).

### Out of scope (v1)

Face/front-camera measurement, accounts, cloud sync, trends/charts, widgets, Apple Watch app,
reading data back from Health (except the debug comparison in §9), localization beyond English.

## 2. Platform and stack

| Item | Choice |
|---|---|
| Minimum OS | iOS 18.0, iPhone only, portrait |
| Language | Swift 6 language mode, strict concurrency |
| UI | SwiftUI |
| Architecture | The Composable Architecture **1.26.x** (`@Reducer`, `@ObservableState`, `@Shared`, `@DependencyClient`) |
| Signal processing | Swift + Accelerate (vDSP for statistics and frame reduction) |
| Capture | AVFoundation (camera + torch), CoreMotion (accelerometer) |
| Persistence | `@Shared(.fileStorage)` JSON in Documents |
| Health | HealthKit (write-only in release builds) |
| Tests | swift-testing + TCA `TestStore` |
| Third-party code | TCA and its Point-Free dependencies only |

TCA patterns follow the library's own examples: tab root as in the `SharedStateFileStorage` case
study, the measurement sheet as in SyncUps `RecordMeeting`, persistence as in SyncUps `syncUps`.
Deprecated APIs (`Effect.debounce`/`throttle`, `scope(state:action:)`) are not used.

## 3. Module layout

The Xcode project is a thin app target. All code lives in one local Swift package, `FreePulseKit`.

```
FreePulseCheckerApp/
├─ FreePulseCheck.xcodeproj
├─ App/                    @main, Info.plist, entitlements, assets, root Store
└─ FreePulseKit/
   └─ Sources/
      ├─ PulseEngine         Pure Swift + Accelerate. No AVFoundation, no TCA.
      ├─ PulseCapture        AVFoundation + CoreMotion. Raw samples only, no signal math.
      ├─ HeartRateClient     TCA dependency joining Capture → Engine off the main actor.
      ├─ HealthKitClient     TCA dependency: authorization + save.
      ├─ Models              Measurement and shared keys.
      ├─ DesignSystem        Tokens and reusable views from the mockups.
      ├─ AppFeature          Root reducer and TabView.
      ├─ MeasureFeature      Tab 1.
      ├─ MeasurementFeature  The 60 s full-screen flow.
      ├─ HistoryFeature      Tab 2.
      └─ SettingsFeature     Tab 3.
```

Dependencies point one way: features → clients → engine/capture → models. `PulseEngine` is the only
module containing signal math and is fully testable on the host without a device.

## 4. Measurement engine (`PulseEngine`)

The engine is an original implementation informed by ClimbPulse (MIT, © 2024 University of
Jyväskylä). Any file that ports ClimbPulse code keeps that copyright notice in its header, and the
notice appears in Settings → Open-source licenses.

### 4.1 Input

`PPGFrame { timestamp: TimeInterval, red: Double, green: Double, cells: [CellStats] }` per camera
frame, where `cells` are 8×8 grid statistics (mean R, G, B and the fraction of saturated red pixels)
over the centre 60% of the frame. Timestamps are camera presentation timestamps relative to the
first frame. `MotionSample { timestamp, magnitude }` at 50 Hz.

### 4.2 Finger detection (`FingerDetector`)

Evaluated every frame:

| Condition | Rule |
|---|---|
| Cell is "finger" | `meanR > 90` and `meanR ≥ 2 × meanG` |
| Coverage | `present` candidate needs ≥ 90% finger cells; 50–90% is `partial` |
| Uniformity | coefficient of variation of cell `meanR` ≤ 0.15, otherwise not a finger |
| Saturated | > 30% of pixels have red = 255 |
| Too dark | frame `meanR < 40` |
| Too much pressure | `present` but perfusion index < 0.05% for ≥ 2 s (needs signal from §4.3) |

Output `FingerState`: `.absent`, `.partial`, `.saturated`, `.tooDark`, `.tooMuchPressure`,
`.present`. Hysteresis: 10 consecutive qualifying frames to enter `.present`, 6 to leave it. Every
state maps to one prompt in the mockups (`04-sheet-finger-prompts`).

### 4.3 Signal pipeline (`SignalPipeline`)

Runs incrementally per sample. Nothing recomputes a full window per frame.

1. **Normalize** each channel to AC/DC: divide by a 1.5 s moving mean, subtract 1. The pulsatile
   amplitude of this signal is the perfusion index.
2. **Channel selection**: every 2 s, choose red or green by higher in-band spectral SNR over the last
   8 s. Red is skipped while more than 30% of pixels are saturated.
3. **Band-pass**: four-pole Butterworth, 0.7–3.5 Hz, as a 2nd-order high-pass and 2nd-order low-pass
   biquad in series. Causal for live use. The final result re-filters the whole recording zero-phase
   (forward–backward).
4. **Motion and artifact masking**: a sample is unusable if accelerometer magnitude deviates from
   1 g by more than 0.05 g within ±0.5 s, or if its amplitude exceeds 4 × the rolling median absolute
   deviation.

Two sample-rate paths, both linearly resampled onto a uniform grid **before** filtering:

- **BPM path**: 30 Hz.
- **Beat path**: the capture rate (60 fps when the format supports it, otherwise 30 fps).

Resampling the beat path is required, not an optimisation: the filters and slope detection assume
even spacing, and ±3 ms of frame jitter without it inflates RMSSD from 33 ms to 57 ms in testing.

### 4.4 Estimators

- **Spectral (`SpectralEstimator`)**: Hann-windowed DFT over 8 s of the BPM path, evaluated by
  Goertzel on a 0.25 BPM grid across 42–210 BPM, with parabolic peak interpolation. Harmonic guard:
  if the spectrum at a third, then a half, of the peak frequency is ≥ 50% of the peak power and inside
  the band, take it. SNR counts ±12 BPM around the heart rate and its 2nd and 3rd harmonics as signal,
  because an 8 s Hann window spreads a pure tone across about ±15 BPM.
- **Beats (`BeatDetector`)**: systolic upstrokes on the beat path. Adaptive threshold
  (0.3 × the rolling 2 s amplitude range above the rolling mean); refractory period
  0.5 × the current expected interbeat interval, bounded to 250–1000 ms. Each beat time is refined to
  sub-frame precision by parabolic interpolation of the slope maximum.
- **Fusion**: live BPM is the spectral estimate. When both estimators agree within 5 BPM the agreement
  term of the quality score is 1, falling linearly to 0 at 15 BPM.

### 4.5 Signal quality (`QualityScorer`)

Score 0–1 = mean of five terms, each clamped to 0–1:

| Term | 1.0 when | 0.0 when |
|---|---|---|
| Spectral SNR | ≥ 6 dB | ≤ 0 dB |
| Perfusion index | 0.1–5% | < 0.05% or > 10% |
| Beat template correlation | mean r ≥ 0.9 | ≤ 0.5 |
| Usable fraction (motion/artifact) | 100% | ≤ 50% |
| Estimator agreement | ≤ 5 BPM | ≥ 15 BPM |

If spectral SNR is below 2 dB there is no dominant rhythm and the score is capped at 0.3, because
noise alone can satisfy the amplitude-based terms.

Bands: **Good** ≥ 0.7, **Fair** 0.4–0.7, **Poor** < 0.4. Live BPM is displayed only at Fair or above.

### 4.6 HRV (`HRVCalculator`)

From beat times over the measuring phase:

1. Interbeat intervals (IBIs) from consecutive beats.
2. Reject IBIs outside 300–1500 ms, and any IBI deviating > 20% from the median of its 5 neighbours.
3. HRV is reported only if ≥ 80% of IBIs survive and they span ≥ 25 s. Otherwise `rmssd`/`sdnn`
   are `nil` and the result says "HRV unavailable — try to stay still".
4. **RMSSD** (headline) and **SDNN** in milliseconds, plus mean IBI and beat count.

### 4.7 Final result

Sliding 8 s windows, 1 s step, across usable samples of the measuring phase. BPM = median of window
estimates, rounded. Quality = score over the whole measuring phase. If fewer than 50% of samples are
usable the measurement fails with `.unreliable`.

## 5. Capture (`PulseCapture`)

- Rear `.builtInWideAngleCamera`, lowest-resolution format supporting 60 fps (fallback 30 fps),
  BGRA output on a dedicated serial queue, `alwaysDiscardsLateVideoFrames = true`.
- Video stabilization, HDR and low-light boost off.
- Torch at `min(0.6, maxAvailableTorchLevel)`. Auto-exposure runs for ~1 s with the finger in place,
  then exposure, white balance and focus are locked (during the calibrating phase).
- Frame → `PPGFrame` via vDSP strided means on the centre ROI; no per-pixel Swift loops.
- `CMMotionManager` accelerometer at 50 Hz.
- `ProcessInfo.thermalState` at `.serious` or above stops capture with `.overheated`.
- Torch is turned off on every exit path, including cancellation.

## 6. `HeartRateClient` (TCA dependency)

```swift
@DependencyClient
public struct HeartRateClient: Sendable {
    public var start: @Sendable () async -> AsyncThrowingStream<MeasurementEvent, any Error> = { .finished() }
    public var finish: @Sendable () async throws -> MeasurementSummary
}

public struct MeasurementEvent: Equatable, Sendable {
    public var fingerState: FingerState
    public var bpm: Int?
    public var quality: SignalQuality?
    public var waveform: [Double]     // last ~4 s, display-ready, ≤ 120 points
    public var isCalibrated: Bool
}
```

- The live implementation runs capture and engine on a background actor and emits events at
  **4 Hz**. Raw frames never reach the store.
- `testValue` is unimplemented. `previewValue` replays a synthetic 72 BPM signal.
- Errors: `.cameraUnavailable`, `.configurationFailed`, `.overheated`, `.unreliable`.

## 7. Features (TCA)

### 7.1 Shared state

```swift
extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<Measurement>>.Default {
    static var measurements: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "measurements.json")), default: []]
    }
}
```

`Measurement`: `id`, `date`, `bpm`, `rmssd: Double?`, `sdnn: Double?`, `quality`, `qualityScore`,
`beatIntervals: [Double]` (stored for future features, no v1 UI), `waveform: [Double]` (100 points),
`savedToHealth: Bool`. Newest first.

### 7.2 `AppFeature`

`selectedTab: Tab` (`.measure`, `.history`, `.settings`) plus three child states composed with
`Scope`. `TabView(selection: $store.selectedTab.sending(\.tabSelected))`.

### 7.3 `MeasureFeature`

- Shows the hero Start button and `measurements.prefix(3)`. Empty state when there are none.
  "See all" switches to History through a delegate action.
- `startTapped`: check camera authorization (§8), then set `@Presents var measurement`, presented
  with `.fullScreenCover(item:)`.

### 7.4 `MeasurementFeature`

Phases:

```
preparing → waitingForFinger → calibrating → measuring(remaining) ⇄ paused → result | failed(reason)
```

| Transition | Trigger |
|---|---|
| preparing → waitingForFinger | first event received |
| waitingForFinger → calibrating | `fingerState == .present` |
| calibrating → measuring(60) | first event with `bpm != nil` and quality ≥ Fair |
| measuring → paused | `fingerState != .present`; countdown stops |
| paused → measuring | finger back to `.present` |
| paused → failed(.fingerLifted) | more than 10 s paused in total |
| measuring → result | countdown reaches 0, then `finish()` succeeds |
| any → failed(reason) | client error |

- Countdown: `continuousClock.timer(interval: .seconds(1))`, cancellable, running only while measuring.
- **Save**: `$measurements.withLock { $0.insert(m, at: 0) }`, then `.run` → `healthKitClient.save`.
  A Health failure leaves the local save in place, sets `savedToHealth = false` and shows a
  non-blocking banner. Then `.delegate(.finished)`.
- **Discard / close (X)**: confirmation alert while measuring; cancels the engine effect; `.delegate(.finished)`.

### 7.5 `HistoryFeature`

All results grouped Today / Yesterday / Earlier; swipe to delete (local only; the Health sample is
left in place and the delete confirmation says so); tap → read-only detail reusing the result layout.

### 7.6 `SettingsFeature`

Apple Health status with a button to open Health settings; measurement duration (read-only, 60 s);
disclaimer; open-source licenses (TCA and its dependencies, ClimbPulse); app version.

## 8. Permissions and errors

| Situation | Behaviour |
|---|---|
| Camera not determined | `startTapped` requests access; on grant, present the sheet |
| Camera denied/restricted | Full-screen state with **Open Settings** (`11-camera-denied`) |
| HealthKit not determined | Requested on first Save; denial does not block saving locally |
| HealthKit unavailable | Settings shows "Unavailable on this device"; Save skips Health |
| No torch (simulator) | `.cameraUnavailable`; the simulator uses `previewValue` in debug builds |
| Overheated | failed(.overheated): "Your iPhone is too warm. Let it cool down and try again." |
| Unreliable signal | failed(.unreliable) with tips (`08-sheet-failed`) |
| App backgrounded mid-measurement | Engine cancelled, torch off, failed(.interrupted) |

Info.plist: `NSCameraUsageDescription`, `NSMotionUsageDescription`, `NSHealthUpdateUsageDescription`,
`NSHealthShareUsageDescription` (debug comparison only). Entitlement: HealthKit.

## 9. Testing and verification

- **`PulseEngine` unit tests** with synthetic PPG: sums of Gaussians at known BPMs 45–180 with
  noise, baseline drift, motion spikes, a dominant second harmonic and ±3 ms frame jitter.
  Requirements: BPM within ±2; RMSSD/SDNN within ±5 ms of the ground truth; noisy cases score Poor;
  injected missed and extra beats are rejected by the IBI filter. Finger detector tests use
  synthetic cell grids for every `FingerState`, including the hysteresis.
- **Reducer tests** (`TestStore`, `TestClock`, exhaustive) for every transition in §7.4, save with
  Health success and failure, discard, denied camera, and the 3-recent prefix.
- **Replay fixtures**: a debug-only toggle records raw `PPGFrame`/`MotionSample` streams to JSON;
  recorded sessions are added as engine regression tests.
- **On-device check**: a debug-only screen reads Apple Watch heart rate and HRV from HealthKit for
  the same window and shows the difference. Target: mean absolute BPM error ≤ 3 at rest over
  10 sessions. Results are reported as measured.
- `xcodebuild test` passes on an iPhone 18 Pro simulator; capture is verified on a physical iPhone.

## 10. Visual design

Dark, gradient, bold. Tokens and per-screen mockups live in [`docs/designs/`](../designs/README.md)
and are mapped one-to-one onto `DesignSystem`. Screens: Measure (populated and empty), the sheet in
each phase, finger prompts, result, failure, History, Settings, camera denied.
