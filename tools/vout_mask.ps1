# vout_mask.ps1 - Video randlos im runden Screen, ohne schwarze Balken/Ecken.
#
# Warum die Video-Steuerung auf der vollen Loch-Box steht:
#   skins2 legt das Video-Fenster (Klasse "SkinWindowClass", Kind des Skin-
#   Fensters) exakt auf das <Video>-Rect und setzt diese Geometrie bei jedem
#   Layout-Wechsel neu. Steht das Rect auf der Loch-Bounding-Box, macht VLC das
#   selbst und stabil - das Video springt nicht.
#
# Balken oben/unten:
#   Der Starter-Bat erzwingt per --crop=214:157 (Screen-Seitenverhaeltnis), dass
#   das Video den Screen ausfuellt (sonst Letterbox-Balken).
#
# Schwarze Ecken / Flackern:
#   CtrlVideo::draw() malet das Rect schwarz und Win32Graphics::fillRect() nimmt
#   es per CombineRgn in die Fenster-Region auf. Die ~78 px der Box ausserhalb
#   des Kopf-Artworks (obere Screen-Ecken) werden dadurch deckend schwarz und
#   skins2 setzt seine Region bei jedem Repaint neu -> die Ecken blitzen.
#   Loesung: Das Player-Fenster wird auf "Oeffnung + diese Zipfel" geclippt -
#   also auf ALLE transparenten Pixel der Box (Box minus Kopf-Rahmen). Da das
#   Video (per --crop) die ganze Box fuellt, deckt es die Zipfel mit Video ab:
#   kein Schwarz und keine Region-Korrektur mehr noetig -> kein Flackern.
#
# head.png bleibt unveraendert. Wird vom Starter-Bat parallel zu VLC gestartet;
# endet, wenn kein VLC laeuft. Diagnose: %TEMP%\headspace_voutmask.log
$ErrorActionPreference = 'Stop'

# --- Diagnose-Log (der Starter-Bat startet das Skript ohne Fenster) ---
$LogPath = Join-Path $env:TEMP 'headspace_voutmask.log'
function Write-Log([string]$m){
  try { ("{0}  {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $m) |
        Out-File -FilePath $LogPath -Append -Encoding utf8 } catch {}
}
trap { Write-Log ("ERROR: " + $_.Exception.Message + " @ line " + $_.InvocationInfo.ScriptLineNumber); exit 1 }
Write-Log ("START pid=" + $PID + " ps=" + $PSVersionTable.PSVersion.ToString())

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiFix { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
public class TimerFix { [DllImport("winmm.dll")] public static extern uint timeBeginPeriod(uint p); }
"@
[void][DpiFix]::SetProcessDPIAware()
[void][TimerFix]::timeBeginPeriod(1)

# --- Konfiguration im 1x-Layout (Headspace) ---
$HoleX = 271; $HoleY = 59; $HoleW = 214; $HoleH = 157
$MaskX = 10;  $MaskY = 59
$MaskPath = Join-Path $PSScriptRoot '..\skins\headspace\theme\images\head.png'

# --- Video-Region = ALLE transparenten Pixel der Box (Oeffnung + Eck-Zipfel) ---
$vid = New-Object System.Collections.Generic.List[int]
if (Test-Path $MaskPath) {
  $bmp = New-Object System.Drawing.Bitmap($MaskPath)
  $mw = $HoleW; $mh = $HoleH
  for ($y = 0; $y -lt $mh; $y++) {
    $x = 0
    while ($x -lt $mw) {
      if ($bmp.GetPixel($MaskX + $x, $MaskY + $y).A -lt 128) {
        $x0 = $x
        while ($x -lt $mw -and $bmp.GetPixel($MaskX + $x, $MaskY + $y).A -lt 128) { $x++ }
        $vid.Add($x0); $vid.Add($y); $vid.Add($x); $vid.Add($y + 1)
      } else { $x++ }
    }
  }
  $bmp.Dispose()
  Write-Host ("Video-Region: " + ($vid.Count / 4) + " Rechtecke")
  Write-Log ("Region: " + ($vid.Count / 4) + " Rechtecke, maskExists=" + (Test-Path $MaskPath))
}
$vidArr = $vid.ToArray()

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ScreenMask {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int m);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern int SetWindowRgn(IntPtr h, IntPtr hRgn, bool redraw);
  [DllImport("user32.dll")] public static extern int GetWindowRgn(IntPtr h, IntPtr hRgn);
  [DllImport("gdi32.dll")] public static extern bool PtInRegion(IntPtr hRgn, int x, int y);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateRectRgn(int a, int b, int c, int d);
  [DllImport("gdi32.dll")] public static extern int CombineRgn(IntPtr d, IntPtr a, IntPtr b, int m);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }

  private static IntPtr Skin = IntPtr.Zero;
  private static readonly List<IntPtr> Vids = new List<IntPtr>();
  private const int RGN_OR = 2;

  private static IntPtr FindSkin(uint pid) {
    IntPtr res = IntPtr.Zero;
    EnumWindows(delegate(IntPtr hw, IntPtr lp) {
      uint pp; GetWindowThreadProcessId(hw, out pp);
      if (pp == pid) {
        StringBuilder c = new StringBuilder(256); GetClassName(hw, c, 256);
        RECT r; GetWindowRect(hw, out r);
        if (c.ToString() == "SkinWindowClass" && (r.R - r.L) > 500) res = hw;
      }
      return true;
    }, IntPtr.Zero);
    return res;
  }

  private static double ScaleFor(IntPtr skin) {
    RECT sr; GetWindowRect(skin, out sr);
    int sw = sr.R - sr.L, sh = sr.B - sr.T;
    if (sw <= 0 || sh <= 0) return 0;
    int layoutW = ((double)sw / sh > 1.65) ? 760 : 549;
    return (double)sw / layoutW;
  }

  public static string Scan(uint pid) {
    Skin = FindSkin(pid);
    Vids.Clear();
    if (Skin == IntPtr.Zero) return "wait";
    StringBuilder key = new StringBuilder();
    EnumChildWindows(Skin, delegate(IntPtr ch, IntPtr lp) {
      StringBuilder c = new StringBuilder(256); GetClassName(ch, c, 256);
      if (c.ToString() == "SkinWindowClass") {
        RECT r; GetWindowRect(ch, out r);
        Vids.Add(ch);
        key.Append(ch).Append(':').Append(r.R - r.L).Append('x').Append(r.B - r.T).Append(';');
      }
      return true;
    }, IntPtr.Zero);
    if (Vids.Count == 0) return "novout";
    return key.ToString();
  }

  /* Player-Fenster auf die Video-Region (Oeffnung + Zipfel) clippen. Idempotent:
     nur setzen, wenn die Region nicht schon stimmt (Mitte + Zipfel drin). */
  public static void Apply(int vx, int vy, int vw, int vh, int[] rects) {
    if (Skin == IntPtr.Zero || Vids.Count == 0) return;
    double scale = ScaleFor(Skin);
    if (scale <= 0) return;

    foreach (IntPtr v in Vids) {
      if (RegionOk(v, vw, vh, scale)) continue;
      IntPtr reg = CreateRectRgn(0, 0, 0, 0);
      if (rects.Length == 0) {
        SetWindowRgn(v, reg, true);
      } else {
        for (int i = 0; i < rects.Length; i += 4) {
          int x0 = (int)Math.Round(rects[i] * scale), y0 = (int)Math.Round(rects[i + 1] * scale);
          int x1 = (int)Math.Round(rects[i + 2] * scale), y1 = (int)Math.Round(rects[i + 3] * scale);
          IntPtr rr = CreateRectRgn(x0, y0, x1, y1);
          CombineRgn(reg, reg, rr, RGN_OR);
          DeleteObject(rr);
        }
        SetWindowRgn(v, reg, true);
      }
    }
  }

  /* Stimmt die Region des Player-Fensters schon?  Oeffnungsmitte + Box-Ecke
     (Zipfel) muessen drin sein, sonst neu setzen. */
  private static bool RegionOk(IntPtr v, int vw, int vh, double scale) {
    IntPtr h = CreateRectRgn(0, 0, 0, 0);
    bool ok = false;
    if (GetWindowRgn(v, h) != 0) {
      bool inMid = PtInRegion(h, (int)Math.Round((vw / 2) * scale), (int)Math.Round((vh / 2) * scale));
      bool inCorner = PtInRegion(h, (int)Math.Round(2 * scale), (int)Math.Round(2 * scale));
      ok = inMid && inCorner;
    }
    DeleteObject(h);
    return ok;
  }
}
"@

$lastScan = 0
$skinFound = $false
$seenVlc = $false
$loggedFound = $false
$startTick = [Environment]::TickCount
while ($true) {
  $now = [Environment]::TickCount
  if (($now - $lastScan) -ge 20) {
    $lastScan = $now
    $procs = @(Get-Process vlc -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) {
      if (-not $seenVlc) {
        if (($now - $startTick) -gt 60000) { break }
        Start-Sleep -Milliseconds 300
        continue
      }
      Start-Sleep -Milliseconds 1200
      if (@(Get-Process vlc -ErrorAction SilentlyContinue).Count -eq 0) { break }
      continue
    }
    $seenVlc = $true
    $skinFound = $false
    foreach ($vp in $procs) {
      $key = [ScreenMask]::Scan([uint32]$vp.Id)
      if ($key -ne 'wait' -and $key -ne 'novout') { $skinFound = $true }
    }
    if ($skinFound -and -not $loggedFound) { Write-Log "Skin+Video gefunden, Wache aktiv"; $loggedFound = $true }
  }
  if ($skinFound) {
    [ScreenMask]::Apply($HoleX, $HoleY, $HoleW, $HoleH, $vidArr)
  }
  Start-Sleep -Milliseconds 2
}
Write-Log "VLC beendet, Wache stoppt"
exit 0
