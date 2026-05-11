### Android (contacts demo)

```
Open android_playground/ in Android Studio → Run
```

The Android playground demonstrates SDUI with real data:
- Reads all **phone contacts** via `ContentResolver`
- Converts to **DynamicLayout JSON** (search input + one FIELDSET per contact)
- Renders with **Jetpack Compose** renderer
- Typing in the search field **regenerates JSON** and re‑renders — full SDUI round‑trip

This is the canonical SDUI demo: real device data → generated JSON → rendered UI.
No hardcoded screens, no Activity-per-screen.