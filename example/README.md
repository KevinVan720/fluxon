# Flux Image Studio — Fluxon Framework Demo

An interactive Flutter app demonstrating Fluxon’s cross‑isolate services and event system with computation‑heavy image filters. The UI remains responsive while a remote worker processes filters; changing any control cancels the in‑flight job and starts the latest one.

## 🎯 What This Demo Shows

- **📡 Event‑driven, cancelable jobs**: versioned FilterRequest/Progress/Result events; workers cooperatively cancel on newer requests
- **🔄 Local vs Remote**: toggle runtime (segmented button) to compare latency and UI smoothness
- **🖼️ Heavy filters**: gaussian blur, motion blur (multi‑pass), pixelate, edge detect, grayscale, sepia, brightness, contrast, saturation, hue
- **🧭 Material 3 UI**: compact DropdownMenu/SegmentedButton, non‑blocking sliders, upload/save

## 🚀 Run

```bash
cd example
flutter pub get
dart run build_runner build -d
flutter run -d macos   # or any Flutter target
```

macOS only: if you see a sandbox error when saving/loading, run `pod install` once in `example/macos` and we already set user‑selected read/write entitlements.

## 🏗️ Architecture (high level)

```
UI (main isolate)                Remote worker (service isolate)
┌──────────────────────────┐     ┌──────────────────────────┐
│ ImageFiltersScreen       │     │ ImageFilterService       │
│ ImageFiltersController   │     │  • listens to FilterRequestEvent
│ ImageFilterCoordinator   │◄────┤  • emits Progress/Result/Cancelled
│  • sends FilterRequest   │     └──────────────────────────┘
└──────────────────────────┘
            ▲ events
            │
        FluxRuntime (automatic event bridge + dispatcher)
```

## 🕹️ Controls

- **Runtime**: Remote | Local (AppBar segmented button)
- **Filter**: Dropdown (Material 3)
- **Sliders** (contextual ranges)
  - Gaussian blur: Sigma 1–16
  - Motion blur: Passes 1–10, Radius 1–16
  - Pixelate: Block size 2–40
  - Brightness: 0–2 (1 = original)
  - Contrast: 0–2 (1 = original)
  - Saturation: 0–2 (1 = original)
  - Hue: −180° to 180°
- **Upload**: choose an image; **Save**: export PNG

All sliders are live; moving them emits a new request and cancels the previous one. The AppBar shows a spinner while the latest job runs.

## 🧩 Services

- `ImageFilterService` (remote): heavy compute in a worker isolate
- `LocalImageFilterService` (local): same API to compare performance
- `ImageFilterCoordinator` (local): issues requests, waits for results, and reconciles by requestId

## 📡 Event Types

- `FilterRequestEvent { requestId, target, filter, amount, sigma, brightness, contrast, saturation, hue, image }`
- `FilterProgressEvent { requestId, percent }`
- `FilterResultEvent { requestId, image }`
- `FilterCancelledEvent { requestId }`

## ✨ Notes

- The demo uses a fixed number of internal passes to showcase progress; you can tune/debounce in `ImageFiltersController`.
- No tiling is used; artifacts from tile seams are avoided.

## 📦 Tech

- Flutter + Material 3 UI
- `fluxon` (services, proxies, events)
- `image` (pure Dart image processing)
- `file_picker` + `file_selector` (upload/save)