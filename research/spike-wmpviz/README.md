# Spike: WMP-Visualizer-Host — Retro-Vizzes außerhalb von WMP rendern

**Datum:** 2026-10-13 · **Verdikt: ✅ GO (GDI-Vizzes)** · Throwaway-Code, als Referenz ins Repo übernommen.

## Frage

Können klassische WMP-Visualizer-DLLs (`IWMPEffects`) außerhalb von Windows Media Player von einem kleinen Host geladen und mit (zunächst synthetischem) Audio gerendert werden? — Grundlage für ein optionales VLC-Feature (Spec §5.2/Phase F) und als Test-Harness für eigene Visualizer (Bitmancer-Pack).

## Ergebnis (alles verifiziert)

- **3/3** getestete DLLs (MS **Alchemy**, MS **Musical Colors**, Third-Party **Better Bars**) rendern **120/120 Frames `S_OK`** in einen 640×480-Memory-DC — ohne Registrierung, ohne Admin, **ohne eigenes Fenster**. Aufruf: `LoadLibrary` + `DllGetClassObject`, kein `regsvr32`.
- Echte Animation nachgewiesen: Alchemy Frame-Diff f0↔f119 = **100 %**; Musical Colors 49,8 % (f29↔f119); Better Bars 16,2 % (f29↔f119).
- `GetCapabilities` lieferte 0x0/0x0/0x4 (`EFFECT_VARIABLEFREQSTEP`); Musical Colors kann **nur** `IWMPEffects` (QI auf `IWMPEffects2` = `E_NOINTERFACE`) → v2 ist optional.
- **GDI ist erwiesen. D3D-/DirectDraw-Ära (Battery, WM3DSpectrum …) ist offen** → zweiter Spike; ggf. braucht es den `IWMPEffects2`-Windowed-Pfad (`Create`/`RenderWindowed`).

## Verifizierte Referenz

- `IID_IWMPEffects` = `D3984C13-C3CB-48e2-8BE5-5168340B4F35`
- `IID_IWMPEffects2` = `695386EC-AA3C-4618-A5E1-DD9A8B987632`
- Vtable (IWMPEffects): 0–2 `QI/AddRef/Release`, 3 `Render(TimedLevel*, HDC, RECT*)`, 4 `MediaInfo(LONG ch, LONG rate, BSTR title)`, 5 `GetCapabilities(DWORD*)`, 6 `GetTitle(BSTR*)`, 7 `GetPresetTitle(LONG, BSTR*)`, 8 `GetPresetCount(LONG*)`, 9 `SetCurrentPreset(LONG)`, 10 `GetCurrentPreset(LONG*)`, 11 `DisplayPropertyPage(HWND)`, 12 `GoFullscreen(BOOL)`, 13 `RenderFullScreen(TimedLevel*)`
- IWMPEffects2 zusätzlich: 14 `SetCore`, 15 `Create(HWND)`, 16 `Destroy`, 17 `NotifyNewMedia`, 18 `OnWindowMessage`, 19 `RenderWindowed(TimedLevel*, BOOL)`
- `TimedLevel` (x86, **4112 Bytes**):
  - `0x0000 BYTE frequency[2][1024]` — [Kanal][Band], 0..255, Band 0 ≈ 20 Hz … 1023 ≈ 22050 Hz
  - `0x0800 BYTE waveform[2][1024]` — [Kanal][Sample], 0..255 entspricht −128..127
  - `0x1000 int state` — 0 stop, 1 pause, 2 play
  - `0x1008 __int64 timeStamp` — 100-ns-Einheiten (4 Byte Padding bei 0x1004)
- **Instantiation-Rezept:** LoadLibrary → `DllGetClassObject(CLSID, IID_IClassFactory)` → `CreateInstance(NULL, IID_IWMPEffects)` (Fallback `IID_IUnknown` + manuelles QI) → **sofort `SetCurrentPreset(0)`** → `GetCapabilities/GetTitle/GetPresetCount/MediaInfo` → pro Frame `TimedLevel` füllen, `Render(levels, memDC, &rect)`. Alles auf **einem STA-Thread** (DLLs sind apartment-bound).
- **CLSID ohne Registry finden:** DLL nach GUID-Mustern scannen, Kandidaten isoliert (Kindprozess pro Versuch) durch `DllGetClassObject` sweepen, Treffer mit `CreateInstance` + QI validieren — nicht jeder Factory-Treffer ist echt (Better Bars ignorierte die CLSID komplett).
- **Host bauen:** `WmpHost.cs` (x86): `C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /platform:x86 /out:WmpHost.exe WmpHost.cs`
- **x64-VLC-Architektur (Skizze):** `vlc.exe (x64)` tappt dekodiertes PCM → Shared-Memory-Ringpuffer (PCM oder FFT-Bänder + State) → `vizhost32.exe (x86)` lädt die DLL registration-frei, rendert in ein Shared-Memory-DIB → VLC blittet das DIB in ein Video-Frame. Audio läuft nie durch den Helper; Helper wird überwacht (Crash/Timeout → Neustart/Deaktivieren), Audiosignal wird nie blockiert.
- Aufwand Phase F: **~1–2 Wochen** funktional, **3–5 Wochen** robust.

## Risiken / Caveats

- D3D-/DirectDraw-Vizzes ungetestet; Fullscreen (`GoFullscreen`/`RenderFullScreen`) und Property Pages ungetestet.
- GDI ist CPU-gebunden; 640×480 billig, 1080p/4K-Performance ungemessen.
- Native Fremd-DLLs = Sicherheitsrisiko → nur vom Nutzer bereitgestellte/allowlistete DLLs; Helper isolieren und überwachen.
- Rechtlich: die DLLs **nie** mitliefern (Downloader/BYO, siehe Distribution-Spec) — der Host selbst ist unser Code.

## Dateien

- `WmpHost.cs` — Throwaway-Testhost (Referenz, **nicht produktiv**); enthält CLSID-Sweep, Probe-Load, DIB-Renderer, Frame-Diff, PNG-Export.
- `evidence/` — Frame-PNGs (Alchemy, Musical Colors, Better Bars) + Logs (`*_log.txt`).
