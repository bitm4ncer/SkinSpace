# vout_mask.ps1 - setzt das Video-Fenster des Skins "hinter" den Skin-Rahmen.
#
# Hintergrund: skins2 zeichnet das Video in KIND-Fenster des Skin-Fensters.
# Kind-Fenster liegen in Windows IMMER ueber der Zeichnung des Elternfensters -
# ein Skin kann sein Video also nicht selbst ueberdecken. Bei einem runden
# Screen-Ausschnitt (wie Headspace) stehen die rechteckigen Video-Ecken deshalb
# ueber den Rahmen (und das Letterbox-Schwarz liegt zwischen Video und Rahmen).
#
# Loesung: Diesen Kind-Fenstern eine Fenster-Region (SetWindowRgn) in Form des
# Screen-Lochs geben. Die Form wird direkt aus der Alpha-Maske von head.png
# gelesen - dadurch sitzt das Video exakt im Ausschnitt und der gemalte Rahmen
# bleibt sichtbar.
#
# Der Waechter wird vom Starter-Bat parallel zu VLC gestartet und beendet sich,
# wenn kein VLC mehr laeuft.
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiFix { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DpiFix]::SetProcessDPIAware()

# --- Konfiguration im 1x-Layout (Headspace) ---
# Screen-Bereich (Video-Control) im Skin und der dazu passende Ausschnitt in head.png.
$VideoX = 271; $VideoY = 59; $VideoW = 214; $VideoH = 157
$MaskX  = 10;  $MaskY  = 59; $MaskW  = $VideoW; $MaskH = $VideoH
$MaskPath = Join-Path $PSScriptRoot '..\skins\headspace\theme\images\head.png'

# --- Region-Rechtecke (maskenlokal) aus der Alpha-Maske bauen ---
$flat = New-Object System.Collections.Generic.List[int]
if (Test-Path $MaskPath) {
  $bmp = New-Object System.Drawing.Bitmap($MaskPath)
  for ($y = 0; $y -lt $MaskH; $y++) {
    $x = 0
    while ($x -lt $MaskW) {
      if ($bmp.GetPixel($MaskX + $x, $MaskY + $y).A -lt 128) {
        $x0 = $x
        while ($x -lt $MaskW -and $bmp.GetPixel($MaskX + $x, $MaskY + $y).A -lt 128) { $x++ }
        $flat.Add($x0); $flat.Add($y); $flat.Add($x); $flat.Add($y + 1)
      } else { $x++ }
    }
  }
  $bmp.Dispose()
  Write-Host ("Maske geladen: " + ($flat.Count / 4) + " Rechtecke")
} else {
  Write-Host "head.png nicht gefunden - Fallback auf rundes Rechteck"
}
$flatArr = $flat.ToArray()

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ScreenMask {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr hWnd, EnumProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder s, int max);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern int SetWindowRgn(IntPtr hWnd, IntPtr hRgn, bool redraw);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateRectRgn(int x1, int y1, int x2, int y2);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int x1, int y1, int x2, int y2, int ew, int eh);
  [DllImport("gdi32.dll")] public static extern int CombineRgn(IntPtr dst, IntPtr s1, IntPtr s2, int mode);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObj);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }

  private static IntPtr Skin;
  private static readonly List<IntPtr> Kids = new List<IntPtr>();

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

  /* Sucht Skin + Video-Kind-Fenster und liefert einen Schluessel fuer die aktuelle Lage. */
  public static string Scan(uint pid) {
    Skin = FindSkin(pid);
    Kids.Clear();
    if (Skin == IntPtr.Zero) return "wait";
    StringBuilder key = new StringBuilder();
    EnumChildWindows(Skin, delegate(IntPtr ch, IntPtr lp) {
      StringBuilder c = new StringBuilder(256);
      GetClassName(ch, c, 256);
      string cs = c.ToString();
      if (cs == "SkinWindowClass" || cs.StartsWith("VLC video")) {
        RECT r; GetWindowRect(ch, out r);
        Kids.Add(ch);
        key.Append(ch).Append(':').Append(r.R - r.L).Append('x').Append(r.B - r.T).Append('@').Append(r.L).Append(',').Append(r.T).Append(';');
      }
      return true;
    }, IntPtr.Zero);
    if (Kids.Count == 0) return "novout";
    return key.ToString();
  }

  private static double ScaleFor(IntPtr skin) {
    RECT sr; GetWindowRect(skin, out sr);
    int sw = sr.R - sr.L, sh = sr.B - sr.T;
    if (sw <= 0 || sh <= 0) return 0;
    double aspect = (double)sw / (double)sh;
    int layoutW = (aspect > 1.65) ? 760 : 549;   /* 760er- bzw. 549er-Layout */
    return (double)sw / (double)layoutW;
  }

  /* Setzt die Region (aus der Maske, maskenlokal) auf alle Video-Kind-Fenster. */
  public static void Apply(int vx, int vy, int mw, int mh, int[] rects) {
    if (Skin == IntPtr.Zero || Kids.Count == 0) return;
    double scale = ScaleFor(Skin);
    if (scale <= 0) return;
    RECT sr; GetWindowRect(Skin, out sr);

    foreach (IntPtr ch in Kids) {
      RECT r; GetWindowRect(ch, out r);
      int cl = r.L - sr.L, ct = r.T - sr.T;
      IntPtr reg = CreateRectRgn(0, 0, 0, 0);
      if (rects.Length == 0) {
        /* Fallback: rundes Rechteck */
        IntPtr rr = CreateRoundRectRgn(0, 0, (r.R - r.L) + 1, (r.B - r.T) + 1,
                                       (int)Math.Round(108 * scale), (int)Math.Round(108 * scale));
        SetWindowRgn(ch, rr, true);
        DeleteObject(reg);
        continue;
      }
      for (int i = 0; i < rects.Length; i += 4) {
        int x0 = (int)Math.Round(rects[i]     * scale) + (int)Math.Round(vx * scale) - cl;
        int y0 = (int)Math.Round(rects[i + 1] * scale) + (int)Math.Round(vy * scale) - ct;
        int x1 = (int)Math.Round(rects[i + 2] * scale) + (int)Math.Round(vx * scale) - cl;
        int y1 = (int)Math.Round(rects[i + 3] * scale) + (int)Math.Round(vy * scale) - ct;
        IntPtr rr = CreateRectRgn(x0, y0, x1, y1);
        CombineRgn(reg, reg, rr, 2);   /* RGN_OR */
        DeleteObject(rr);
      }
      SetWindowRgn(ch, reg, true);
    }
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
    # bei geaenderter Fensterlage ODER regelmaessig als Sicherheit neu anwenden
    if ($key -ne $lastKey -or ($tick % 10) -eq 0) {
      [ScreenMask]::Apply($VideoX, $VideoY, $MaskW, $MaskH, $flatArr)
      $lastKey = $key
    }
  }
  $tick++
  Start-Sleep -Milliseconds 900
}
exit 0
