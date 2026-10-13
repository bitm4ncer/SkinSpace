# winhelp.ps1 — DPI-aware Fenster-Helfer für den Headspace-Spike (Screenshots, Klicks, DnD)
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
public struct POINT { public int X; public int Y; }
public class WinAPI {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  public static List<IntPtr> WindowsOf(uint pid, bool visibleOnly) {
    var res = new List<IntPtr>();
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && (!visibleOnly || IsWindowVisible(h))) res.Add(h);
      return true;
    }, IntPtr.Zero);
    return res;
  }
  public static bool Click(int x, int y) {
    POINT old; GetCursorPos(out old);
    SetCursorPos(x, y); System.Threading.Thread.Sleep(90);
    mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60);
    mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(180);
    SetCursorPos(old.X, old.Y);
    return true;
  }
  public static bool Drag(int x1, int y1, int x2, int y2) {
    POINT old; GetCursorPos(out old);
    SetCursorPos(x1, y1); System.Threading.Thread.Sleep(140);
    mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(140);
    int steps = 14;
    for (int i = 1; i <= steps; i++) {
      int x = x1 + (x2 - x1) * i / steps; int y = y1 + (y2 - y1) * i / steps;
      SetCursorPos(x, y); System.Threading.Thread.Sleep(35);
    }
    System.Threading.Thread.Sleep(140);
    mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(250);
    SetCursorPos(old.X, old.Y);
    return true;
  }
}
"@
[WinAPI]::SetProcessDPIAware() | Out-Null

function Get-VlcWin([int]$procId) {
  $out = @()
  foreach($h in [WinAPI]::WindowsOf([uint32]$procId, $true)) {
    $r = New-Object RECT
    [WinAPI]::GetWindowRect($h, [ref]$r) | Out-Null
    $out += [pscustomobject]@{ Hwnd=$h; Left=$r.Left; Top=$r.Top; W=($r.Right-$r.Left); H=($r.Bottom-$r.Top) }
  }
  return $out
}
function Get-MainWin([int]$procId, [int]$expectW) {
  $ws = Get-VlcWin $procId
  return ($ws | Where-Object { [Math]::Abs($_.W - $expectW) -lt 40 } | Select-Object -First 1)
}
function Capture-Win($hwnd, [string]$path) {
  $r = New-Object RECT
  [WinAPI]::GetWindowRect($hwnd, [ref]$r) | Out-Null
  $w = $r.Right-$r.Left; $h = $r.Bottom-$r.Top
  if($w -le 0 -or $h -le 0){ return "FEHLER: leeres Fenster" }
  $b = New-Object System.Drawing.Bitmap($w,$h)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $hdc = $g.GetHdc()
  [WinAPI]::PrintWindow($hwnd,$hdc,2) | Out-Null
  $g.ReleaseHdc($hdc); $g.Dispose()
  $b.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
  return "captured ${w}x${h} -> $path"
}
