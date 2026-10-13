# vout_mask.ps1 - haelt das Video randlos im runden Screen und raeumt skins2's
# schwarzen Backdrop an den Screen-Ecken weg.
#
# Warum die Video-Steuerung auf der vollen Loch-Box steht:
#   skins2 legt das eigentliche Video-Fenster (Klasse "SkinWindowClass", Kind
#   des Skin-Fensters) exakt auf das <Video>-Rect und setzt diese Geometrie bei
#   jedem Layout-Wechsel neu (CtrlVideo::onResize). Steht das Rect auf der
#   Loch-Bounding-Box (271,59,214,157), macht VLC das selbst und stabil - das
#   Video springt nicht mehr.
#
# Warum es trotzdem Puzzlesteine braucht:
#   CtrlVideo::draw() malt genau dieses Rect schwarz, und
#   Win32Graphics::fillRect() nimmt das Rect per CombineRgn(RGN_OR) in die
#   Fenster-Region auf (notwendig, damit das Kind-Fenster dort ueberhaupt
#   zeichnen darf). Die ~78 px der Box, die ausserhalb des Kopf-Artworks liegen
#   (die beiden oberen Screen-Ecken, im Original die rote Clip-Farbe), werden
#   dadurch deckend schwarz und "ragen ueber den Rahmen".
#
# Loesung:
#   (a) das Video-Fenster per SetWindowRgn auf die Lochform (aus der Alpha-Maske
#       von head.png) schneiden -> randfuellend, runde Kanten;
#   (b) genau diese ~78 px aus der Fenster-Region des Skins abziehen
#       (SetWindowRgn mit RGN_DIFF). skins2 setzt seine Region bei jedem
#       Repaint neu, daher laeuft die Korrektur in einer engen Schleife.
#
# head.png bleibt unveraendert. Wird vom Starter-Bat parallel zu VLC gestartet;
# endet, wenn kein VLC laeuft.
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiFix { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DpiFix]::SetProcessDPIAware()

# --- Konfiguration im 1x-Layout (Headspace) ---
$HoleX = 271; $HoleY = 59; $HoleW = 214; $HoleH = 157
$MaskX = 10;  $MaskY = 59
$MaskPath = Join-Path $PSScriptRoot '..\skins\headspace\theme\images\head.png'

# --- Loch-Form + Eck-Zipfel aus head.png lesen ---
# Loch  = zusammenhaengende transparente Flaeche um die Mitte (die Oeffnung).
# Zipfel = transparente Pixel, die NICHT zu dieser Flaeche gehoeren (im
#          Original die rote Aussen-Clip-Farbe) -> deckend schwarz durch skins2.
$hole = New-Object System.Collections.Generic.List[int]
$trim = New-Object System.Collections.Generic.List[int]
if (Test-Path $MaskPath) {
  $bmp = New-Object System.Drawing.Bitmap($MaskPath)
  $mw = $HoleW; $mh = $HoleH
  $trans = New-Object 'bool[,]' $mw, $mh
  for ($y = 0; $y -lt $mh; $y++) {
    for ($x = 0; $x -lt $mw; $x++) {
      $trans[$x, $y] = ($bmp.GetPixel($MaskX + $x, $MaskY + $y).A -lt 128)
    }
  }
  $bmp.Dispose()
  $sx = -1; $sy = -1
  $cx = [int]($mw / 2); $cy = [int]($mh / 2)
  if ($trans[$cx, $cy]) { $sx = $cx; $sy = $cy }
  else { for ($y = 0; $y -lt $mh -and $sx -lt 0; $y++) { for ($x = 0; $x -lt $mw; $x++) { if ($trans[$x, $y]) { $sx = $x; $sy = $y; break } } } }
  $seen = New-Object 'bool[,]' $mw, $mh
  if ($sx -ge 0) {
    $q = New-Object System.Collections.Queue
    $q.Enqueue(($sy * $mw + $sx)); $seen[$sx, $sy] = $true
    while ($q.Count -gt 0) {
      $idx = [int]$q.Dequeue(); $x = $idx % $mw; $y = [int][Math]::Floor($idx / $mw)
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $x + $d[0]; $ny = $y + $d[1]
        if ($nx -ge 0 -and $nx -lt $mw -and $ny -ge 0 -and $ny -lt $mh -and -not $seen[$nx, $ny] -and $trans[$nx, $ny]) {
          $seen[$nx, $ny] = $true; $q.Enqueue(($ny * $mw + $nx))
        }
      }
    }
    for ($y = 0; $y -lt $mh; $y++) {
      $x = 0
      while ($x -lt $mw) {
        if ($seen[$x, $y]) { $x0 = $x; while ($x -lt $mw -and $seen[$x, $y]) { $x++ }; $hole.Add($x0); $hole.Add($y); $hole.Add($x); $hole.Add($y + 1) }
        else { $x++ }
      }
    }
    for ($y = 0; $y -lt $mh; $y++) {
      $x = 0
      while ($x -lt $mw) {
        if ($trans[$x, $y] -and -not $seen[$x, $y]) { $x0 = $x; while ($x -lt $mw -and $trans[$x, $y] -and -not $seen[$x, $y]) { $x++ }; $trim.Add($x0); $trim.Add($y); $trim.Add($x); $trim.Add($y + 1) }
        else { $x++ }
      }
    }
  }
  Write-Host ("Loch-Maske: " + ($hole.Count / 4) + " Rechtecke, Eck-Zipfel: " + ($trim.Count / 4) + " Rechtecke")
}
$holeArr = $hole.ToArray()
$trimArr = $trim.ToArray()

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
  [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr h, IntPtr p);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern int SetWindowRgn(IntPtr h, IntPtr hRgn, bool redraw);
  [DllImport("user32.dll")] public static extern int GetWindowRgn(IntPtr h, IntPtr hRgn);
  [DllImport("gdi32.dll")] public static extern bool RectInRegion(IntPtr hRgn, ref RECT r);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateRectRgn(int a, int b, int c, int d);
  [DllImport("gdi32.dll")] public static extern int CombineRgn(IntPtr d, IntPtr a, IntPtr b, int m);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }

  private static IntPtr Skin = IntPtr.Zero;
  private static readonly List<IntPtr> Vids = new List<IntPtr>();
  private const int RGN_OR = 2, RGN_DIFF = 4;

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

  /* Skin + Video-Fenster suchen; liefert Schluessel fuer die aktuelle Lage. */
  public static string Scan(uint pid) {
    Skin = FindSkin(pid);
    Vids.Clear();
    if (Skin == IntPtr.Zero) return "wait";
    StringBuilder key = new StringBuilder();
    EnumChildWindows(Skin, delegate(IntPtr ch, IntPtr lp) {
      StringBuilder c = new StringBuilder(256); GetClassName(ch, c, 256);
      string cs = c.ToString();
      if (cs == "SkinWindowClass" || cs.StartsWith("VLC video")) {
        RECT r; GetWindowRect(ch, out r);
        Vids.Add(ch);
        key.Append(ch).Append(':').Append(r.R - r.L).Append('x').Append(r.B - r.T).Append('@').Append(r.L).Append(',').Append(r.T).Append(';');
      }
      return true;
    }, IntPtr.Zero);
    if (Vids.Count == 0) return "novout";
    return key.ToString();
  }

  /* Video-Fenster auf die Lochform clippen (Steuerung selbst liegt schon auf Lochgroesse). */
  public static void Apply(int vx, int vy, int vw, int vh, int[] rects) {
    if (Skin == IntPtr.Zero || Vids.Count == 0) return;
    double scale = ScaleFor(Skin);
    if (scale <= 0) return;

    foreach (IntPtr v in Vids) {
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

  /* Eck-Zipfel (ausserhalb des Gesichts) aus der Fenster-Region des Skins
     abziehen. skins2 setzt seine Region bei jedem Repaint neu, daher wird das
     hier immer wieder (idempotent) nachgezogen. */
  public static void TrimRegion(int vx, int vy, int[] rects) {
    if (Skin == IntPtr.Zero || rects.Length == 0) return;
    double scale = ScaleFor(Skin);
    if (scale <= 0) return;

    IntPtr hTrim = CreateRectRgn(0, 0, 0, 0);
    for (int i = 0; i < rects.Length; i += 4) {
      int x0 = (int)Math.Round((vx + rects[i]) * scale), y0 = (int)Math.Round((vy + rects[i + 1]) * scale);
      int x1 = (int)Math.Round((vx + rects[i + 2]) * scale), y1 = (int)Math.Round((vy + rects[i + 3]) * scale);
      IntPtr rr = CreateRectRgn(x0, y0, x1, y1);
      CombineRgn(hTrim, hTrim, rr, RGN_OR);
      DeleteObject(rr);
    }

    IntPtr hCur = CreateRectRgn(0, 0, 0, 0);
    int t = GetWindowRgn(Skin, hCur);   /* 0 = ERROR, 1 = NULLREGION, 2 = SIMPLE, 3 = COMPLEX */
    if (t != 0) {
      bool need = false;
      for (int i = 0; i < rects.Length; i += 4) {
        RECT r = new RECT();
        r.L = (int)Math.Round((vx + rects[i]) * scale); r.T = (int)Math.Round((vy + rects[i + 1]) * scale);
        r.R = (int)Math.Round((vx + rects[i + 2]) * scale); r.B = (int)Math.Round((vy + rects[i + 3]) * scale);
        if (RectInRegion(hCur, ref r)) { need = true; break; }
      }
      if (need) {
        IntPtr hNew = CreateRectRgn(0, 0, 0, 0);
        CombineRgn(hNew, hCur, hTrim, RGN_DIFF);
        SetWindowRgn(Skin, hNew, true);   /* System uebernimmt hNew; nicht freigeben */
      }
    }
    DeleteObject(hCur);
    DeleteObject(hTrim);
  }
}
"@

$lastKey = ''
$tick = 0
while ($true) {
  $procs = @(Get-Process vlc -ErrorAction SilentlyContinue)
  if ($procs.Count -eq 0) {
    Start-Sleep -Milliseconds 1200
    if (@(Get-Process vlc -ErrorAction SilentlyContinue).Count -eq 0) { break }
    continue
  }
  foreach ($vp in $procs) {
    $key = [ScreenMask]::Scan([uint32]$vp.Id)
    if ($key -eq 'wait' -or $key -eq 'novout') { continue }
    if ($key -ne $lastKey -or ($tick % 16) -eq 0) {
      [ScreenMask]::Apply($HoleX, $HoleY, $HoleW, $HoleH, $holeArr)
      $lastKey = $key
    }
    [ScreenMask]::TrimRegion($HoleX, $HoleY, $trimArr)
  }
  $tick++
  Start-Sleep -Milliseconds 20
}
exit 0
