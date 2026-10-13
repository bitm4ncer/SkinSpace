# vout_mask.ps1 - schneidet das VLC-Video-Fenster (skins2) auf die runde Screen-Form zu.
# Wird vom Starter-Bat parallel zu VLC gestartet; beendet sich selbst, wenn kein VLC mehr laeuft.
# Der Skin kann das Video nicht selbst clippen (eigenes Fenster) - darum diese externe Fenster-Region.
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiFix { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DpiFix]::SetProcessDPIAware()
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class VoutMask {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder s, int max);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern int SetWindowRgn(IntPtr hWnd, IntPtr hRgn, bool redraw);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int x1, int y1, int x2, int y2, int ew, int eh);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }

  private static int LookupScale(int w) {
    if (w >= 1640) return 3;   /* 1647 / 2280 */
    if (w >= 1090) return 2;   /* 1098 / 1520 */
    return 1;                  /* 549 / 760 */
  }

  private static string ApplyOne(uint pid, int bx, int by, int bw, int bh, int br, bool doIt) {
    IntPtr skin = IntPtr.Zero, vid = IntPtr.Zero;
    int sw = 0, sh = 0, sx = 0, sy = 0, vl = 0, vt = 0;
    EnumWindows(delegate(IntPtr hw, IntPtr lp) {
      uint p; GetWindowThreadProcessId(hw, out p);
      if (p == pid) {
        StringBuilder cls = new StringBuilder(256);
        GetClassName(hw, cls, 256);
        string c = cls.ToString();
        RECT r; GetWindowRect(hw, out r);
        if (c == "SkinWindowClass" && (r.R - r.L) > 500) { skin = hw; sw = r.R - r.L; sh = r.B - r.T; sx = r.L; sy = r.T; }
        else if (c.StartsWith("VLC video")) { vid = hw; vl = r.L; vt = r.T; }
      }
      return true;
    }, IntPtr.Zero);
    if (skin == IntPtr.Zero || vid == IntPtr.Zero) return "wait";
    /* Layout per Seitenverhaeltnis erkennen (549er = 1.39, 760er = 1.93), Scale aus der Breite */
    double aspect = (double)sw / (double)sh;
    int layoutW = (aspect > 1.65) ? 760 : 549;
    double scale = (double)sw / (double)layoutW;
    int vx = sx + (int)Math.Round(bx * scale) - vl;
    int vy = sy + (int)Math.Round(by * scale) - vt;
    int vw = (int)Math.Round(bw * scale);
    int vh = (int)Math.Round(bh * scale);
    int rr = (int)Math.Round(br * scale) * 2;
    string key = vid.ToString() + "|" + vx + "|" + vy + "|" + vw + "|" + vh + "|" + rr;
    if (doIt) {
      IntPtr hReg = CreateRoundRectRgn(vx, vy, vx + vw, vy + vh, rr, rr);
      SetWindowRgn(vid, hReg, true);
    }
    return key;
  }

  public static string Probe(uint pid, int bx, int by, int bw, int bh, int br) { try { return ApplyOne(pid, bx, by, bw, bh, br, false); } catch { return "err"; } }
  public static void Apply(uint pid, int bx, int by, int bw, int bh, int br) { try { ApplyOne(pid, bx, by, bw, bh, br, true); } catch { } }
}
"@

# Screen-Bereich im 1x-Layout: x=273 y=61 w=210 h=153, Eckenradius ~26 (aus head.png gemessen)
$bx = 273; $by = 61; $bw = 210; $bh = 153; $br = 26
$lastKey = ''
while ($true) {
  $procs = @(Get-Process vlc -ErrorAction SilentlyContinue)
  if ($procs.Count -eq 0) {
    Start-Sleep -Milliseconds 1200
    if (@(Get-Process vlc -ErrorAction SilentlyContinue).Count -eq 0) { break }
    continue
  }
  foreach ($vp in $procs) {
    $key = [VoutMask]::Probe([uint32]$vp.Id, $bx, $by, $bw, $bh, $br)
    if ($key -eq 'wait' -or $key -eq 'err') { continue }
    if ($key -ne $lastKey) {
      [VoutMask]::Apply([uint32]$vp.Id, $bx, $by, $bw, $bh, $br)
      $lastKey = $key
    }
  }
  Start-Sleep -Milliseconds 900
}
exit 0
