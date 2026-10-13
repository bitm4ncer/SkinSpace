// WmpHost.cs — SPIKE: load & render a classic WMP visualization DLL outside WMP.
// Verifies: registration-free load via DllGetClassObject, IWMPEffects instantiation,
// synthetic TimedLevel feed, memory-DC rendering, PNG evidence.
//
// Build: C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /nologo /platform:x86 /r:System.Drawing.dll /out:WmpHost.exe WmpHost.cs
//
// Modes:
//   scan   <dll> [outfile]         - parse PE, list GUID candidates (no load)
//   sweep  <dll> <hitsfile>        - load dll, try ALL candidates as CLSID via DllGetClassObject (isolated proc)
//   probe  <dll> <clsid>           - CreateInstance + QI + info calls only (isolated proc)
//   render <dll> <clsid> <outdir>  - full render loop, PNGs (isolated proc)
//   run    <dll> <outdir>          - orchestrator: scan -> sweep -> probe -> render
//
// Interface facts verified against (a) microsoft/Windows-driver-samples hid/firefly/sauron/effects.idl,
// (b) learn.microsoft.com effects.h docs, (c) StackOverflow C# sample 2060978 + VB/Delphi ports:
//   IID_IWMPEffects  = D3984C13-C3CB-48e2-8BE5-5168340B4F35
//   IID_IWMPEffects2 = 695386EC-AA3C-4618-A5E1-DD9A8B987632
//   vtable (after IUnknown): Render, MediaInfo(LONG,LONG,BSTR), GetCapabilities, GetTitle,
//     GetPresetTitle, GetPresetCount, SetCurrentPreset, GetCurrentPreset, DisplayPropertyPage,
//     GoFullscreen, RenderFullScreen
//   TimedLevel: BYTE frequency[2][1024]; BYTE waveform[2][1024]; int state; __int64 timeStamp; (4112 bytes on x86)

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

internal static class Program
{
    // ---------------- COM IDs ----------------
    static readonly Guid IID_IClassFactory = new Guid("00000001-0000-0000-C000-000000000046");
    static readonly Guid IID_IUnknown = new Guid("00000000-0000-0000-C000-000000000046");
    static readonly Guid IID_IWMPEffects = new Guid("D3984C13-C3CB-48e2-8BE5-5168340B4F35");
    static readonly Guid IID_IWMPEffects2 = new Guid("695386EC-AA3C-4618-A5E1-DD9A8B987632");

    // IWMPEffects vtable slots (0-2 = IUnknown)
    const int SLOT_RENDER = 3;
    const int SLOT_MEDIAINFO = 4;
    const int SLOT_GETCAPS = 5;
    const int SLOT_GETTITLE = 6;
    const int SLOT_GETPRESETTITLE = 7;
    const int SLOT_GETPRESETCOUNT = 8;
    const int SLOT_SETCURRENTPRESET = 9;
    const int SLOT_GETCURRENTPRESET = 10;

    const int TL_SIZE = 4112;          // TimedLevel size on x86 MSVC (state at 4096, pad, timeStamp at 4104)
    const int W = 640, H = 480;
    const int FRAMES = 120;

    // ---------------- P/Invoke ----------------
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr LoadLibraryW(string lpFileName);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    [DllImport("kernel32.dll")]
    static extern bool FreeLibrary(IntPtr hModule);

    [DllImport("gdi32.dll")]
    static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern IntPtr CreateDIBSection(IntPtr hdc, IntPtr pbmi, uint usage, out IntPtr ppvBits, IntPtr hSection, uint dwOffset);
    [DllImport("gdi32.dll")]
    static extern IntPtr SelectObject(IntPtr hdc, IntPtr h);
    [DllImport("gdi32.dll")]
    static extern IntPtr GetStockObject(int i);
    [DllImport("user32.dll")]
    static extern int FillRect(IntPtr hDC, ref RECT lprc, IntPtr hbr);
    [DllImport("user32.dll")]
    static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetClassNameW(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetWindowTextW(IntPtr hWnd, StringBuilder sb, int max);

    delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    struct BITMAPINFOHEADER
    {
        public uint biSize; public int biWidth; public int biHeight;
        public ushort biPlanes; public ushort biBitCount;
        public uint biCompression; public uint biSizeImage;
        public int biXPelsPerMeter; public int biYPelsPerMeter;
        public uint biClrUsed; public uint biClrImportant;
    }

    // ---------------- COM delegates ----------------
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int DgcoDel(ref Guid rclsid, ref Guid riid, out IntPtr ppv);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int QiDel(IntPtr pThis, ref Guid riid, out IntPtr ppv);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int ReleaseDel(IntPtr pThis);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int CfCreateDel(IntPtr pThis, IntPtr pUnkOuter, ref Guid riid, out IntPtr ppv);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int RenderDel(IntPtr pThis, IntPtr pLevels, IntPtr hdc, ref RECT prc);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int MediaInfoDel(IntPtr pThis, int channels, int sampleRate, IntPtr bstrTitle);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int OutIntDel(IntPtr pThis, out int val);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int OutPtrDel(IntPtr pThis, out IntPtr val);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int Int1Del(IntPtr pThis, int val);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int IntOutPtrDel(IntPtr pThis, int val, out IntPtr val2);

    static T Vt<T>(IntPtr p, int slot) where T : class
    {
        IntPtr vtbl = Marshal.ReadIntPtr(p);
        IntPtr fn = Marshal.ReadIntPtr(vtbl, slot * IntPtr.Size);
        return (T)(object)Marshal.GetDelegateForFunctionPointer(fn, typeof(T));
    }

    static string Hx(int hr) { return "0x" + ((uint)hr).ToString("X8"); }
    static void L(string s) { Console.WriteLine(s); Console.Out.Flush(); }

    // ---------------- PE parsing ----------------
    class Section { public string Name; public uint VS, VA, RawSize, RawPtr, Chars; }
    class PeInfo
    {
        public int PeOffset; public ushort Machine, NumSections, OptSize, OptMagic;
        public bool IsDll; public List<Section> Sections = new List<Section>();
        public List<string> Exports = new List<string>();
    }

    static PeInfo ParsePe(byte[] b)
    {
        var p = new PeInfo();
        p.PeOffset = BitConverter.ToInt32(b, 0x3C);
        if (p.PeOffset <= 0 || p.PeOffset + 24 > b.Length) throw new Exception("bad e_lfanew");
        if (b[p.PeOffset] != (byte)'P' || b[p.PeOffset + 1] != (byte)'E') throw new Exception("no PE signature");
        p.Machine = BitConverter.ToUInt16(b, p.PeOffset + 4);
        p.NumSections = BitConverter.ToUInt16(b, p.PeOffset + 6);
        p.OptSize = BitConverter.ToUInt16(b, p.PeOffset + 20);
        ushort chars = BitConverter.ToUInt16(b, p.PeOffset + 22);
        p.IsDll = (chars & 0x2000) != 0;
        int opt = p.PeOffset + 24;
        p.OptMagic = BitConverter.ToUInt16(b, opt);
        int secTab = opt + p.OptSize;
        for (int i = 0; i < p.NumSections; i++)
        {
            int so = secTab + i * 40;
            if (so + 40 > b.Length) break;
            var s = new Section();
            s.Name = Encoding.ASCII.GetString(b, so, 8).TrimEnd('\0', ' ');
            s.VS = BitConverter.ToUInt32(b, so + 8);
            s.VA = BitConverter.ToUInt32(b, so + 12);
            s.RawSize = BitConverter.ToUInt32(b, so + 16);
            s.RawPtr = BitConverter.ToUInt32(b, so + 20);
            s.Chars = BitConverter.ToUInt32(b, so + 36);
            p.Sections.Add(s);
        }
        int ddOff = opt + (p.OptMagic == 0x10B ? 96 : 112);
        if (ddOff + 8 <= b.Length)
        {
            uint expRva = BitConverter.ToUInt32(b, ddOff);
            if (expRva != 0)
            {
                int expOff = RvaToOff(p, expRva);
                if (expOff > 0 && expOff + 40 < b.Length)
                {
                    uint numNames = BitConverter.ToUInt32(b, expOff + 0x18);
                    uint namesRva = BitConverter.ToUInt32(b, expOff + 0x20);
                    int namesOff = RvaToOff(p, namesRva);
                    if (namesOff > 0)
                    {
                        for (int i = 0; i < numNames && i < 4096; i++)
                        {
                            int ent = namesOff + i * 4;
                            if (ent + 4 > b.Length) break;
                            int no = RvaToOff(p, BitConverter.ToUInt32(b, ent));
                            if (no <= 0) continue;
                            var sb = new StringBuilder();
                            while (no < b.Length && b[no] != 0 && sb.Length < 256) { sb.Append((char)b[no]); no++; }
                            p.Exports.Add(sb.ToString());
                        }
                    }
                }
            }
        }
        return p;
    }

    static int RvaToOff(PeInfo p, uint rva)
    {
        foreach (var s in p.Sections)
        {
            uint lim = Math.Max(s.VS, s.RawSize);
            if (rva >= s.VA && rva < s.VA + lim)
            {
                long off = (long)s.RawPtr + (rva - s.VA);
                if (off > 0 && off < int.MaxValue) return (int)off;
            }
        }
        return -1;
    }

    // ---------------- GUID candidate scan ----------------
    static List<KeyValuePair<Guid, string>> FindGuids(byte[] b, PeInfo p, bool wide)
    {
        var seen = new HashSet<Guid>();
        var list = new List<KeyValuePair<Guid, string>>();
        foreach (var s in p.Sections)
        {
            if (s.RawSize < 16) continue;
            bool initializedData = (s.Chars & 0x40) != 0 && (s.Chars & 0x20) == 0;
            bool include = wide || (initializedData && s.Name != ".reloc");
            if (!include) continue;
            int rawEnd = (int)Math.Min(b.Length, (long)s.RawPtr + s.RawSize);
            for (int i = 0; i + 16 <= rawEnd - (int)s.RawPtr; i++)
            {
                int o = (int)s.RawPtr + i;
                if (o + 16 > b.Length) break;
                byte v8 = b[o + 8];
                if ((v8 & 0xC0) != 0x80) continue;       // GUID variant bits
                byte v7 = b[o + 7];
                int ver = v7 >> 4;
                if (!wide && ver != 1 && ver != 3 && ver != 4 && ver != 5) continue;
                byte[] g = new byte[16];
                Array.Copy(b, o, g, 0, 16);
                Guid guid = new Guid(g);
                if (!seen.Contains(guid))
                {
                    seen.Add(guid);
                    list.Add(new KeyValuePair<Guid, string>(guid, s.Name + "@0x" + i.ToString("X")));
                }
            }
        }
        return list;
    }

    static string FullPath(string f) { return Path.GetFullPath(f); }

    static void FindCurrentWindows()
    {
        uint myPid = (uint)Process.GetCurrentProcess().Id;
        var res = new List<string>();
        EnumWindows(delegate(IntPtr hwnd, IntPtr lp)
        {
            uint pid; GetWindowThreadProcessId(hwnd, out pid);
            if (pid == myPid)
            {
                var cn = new StringBuilder(256); GetClassNameW(hwnd, cn, 255);
                var tt = new StringBuilder(256); GetWindowTextW(hwnd, tt, 255);
                res.Add("hwnd=0x" + hwnd.ToInt64().ToString("X") + " class='" + cn + "' title='" + tt + "'");
            }
            return true;
        }, IntPtr.Zero);
        if (res.Count == 0) L("[render] no top-level windows owned by this process");
        foreach (var s in res) L("[render] WINDOW " + s);
    }

    // ---------------- modes ----------------
    static int ModeScan(string dll, string outFile)
    {
        byte[] b = File.ReadAllBytes(dll);
        PeInfo p = ParsePe(b);
        L("[scan] file=" + dll);
        L("[scan] machine=0x" + p.Machine.ToString("X4") + " (" + (p.Machine == 0x14C ? "x86" : "NOT x86!") + ") isDll=" + p.IsDll +
          " sections=" + p.Sections.Count + " optMagic=0x" + p.OptMagic.ToString("X4"));
        foreach (var s in p.Sections)
            L("[scan] section " + s.Name + " VA=0x" + s.VA.ToString("X") + " vsize=0x" + s.VS.ToString("X") + " rawsize=0x" + s.RawSize.ToString("X") + " chars=0x" + s.Chars.ToString("X"));
        L("[scan] exports(" + p.Exports.Count + "): " + string.Join(", ", p.Exports.ToArray()));
        L("[scan] DllGetClassObject exported: " + p.Exports.Contains("DllGetClassObject"));

        var cands = FindGuids(b, p, false);
        L("[scan] GUID candidates in data sections: " + cands.Count);
        foreach (var kv in cands) L("[scan]   " + kv.Key.ToString("B") + "  @ " + kv.Value);
        if (outFile != null)
        {
            var sb = new StringBuilder();
            foreach (var kv in cands) sb.AppendLine(kv.Key.ToString("B") + "\t" + kv.Value);
            File.WriteAllText(outFile, sb.ToString());
            L("[scan] written " + outFile);
        }
        return 0;
    }

    static int ModeSweep(string dll, string hitsFile)
    {
        byte[] b = File.ReadAllBytes(dll);
        PeInfo p = ParsePe(b);
        var cands = FindGuids(b, p, false);
        L("[sweep] candidates to try: " + cands.Count);
        IntPtr h = LoadLibraryW(FullPath(dll));
        if (h == IntPtr.Zero) { L("[sweep] LoadLibrary FAILED GetLastError=" + Hx(Marshal.GetLastWin32Error())); return 2; }
        L("[sweep] LoadLibrary OK");
        IntPtr proc = GetProcAddress(h, "DllGetClassObject");
        if (proc == IntPtr.Zero) { L("[sweep] DllGetClassObject not found"); return 3; }
        var dgco = (DgcoDel)Marshal.GetDelegateForFunctionPointer(proc, typeof(DgcoDel));
        int hits = 0, tried = 0;
        foreach (var kv in cands)
        {
            tried++;
            Guid clsid = kv.Key; Guid iid = IID_IClassFactory;
            IntPtr pcf;
            int hr;
            try { hr = dgco(ref clsid, ref iid, out pcf); }
            catch (Exception ex) { L("[sweep] EXCEPTION on " + clsid.ToString("B") + ": " + ex.Message); continue; }
            if (hr == 0 && pcf != IntPtr.Zero)
            {
                hits++;
                L("[sweep] HIT " + clsid.ToString("B") + " @ " + kv.Value);
                File.AppendAllText(hitsFile, clsid.ToString("B") + "\r\n");
                try { var rel = Vt<ReleaseDel>(pcf, 2); rel(pcf); } catch { }
            }
        }
        L("[sweep] done: tried=" + tried + " hits=" + hits);
        return 0;
    }

    static int ModeProbe(string dll, Guid clsid)
    {
        L("[probe] dll=" + dll + " clsid=" + clsid.ToString("B"));
        IntPtr h = LoadLibraryW(FullPath(dll));
        if (h == IntPtr.Zero) { L("[probe] LoadLibrary FAILED err=" + Hx(Marshal.GetLastWin32Error())); return 2; }
        IntPtr proc = GetProcAddress(h, "DllGetClassObject");
        if (proc == IntPtr.Zero) { L("[probe] no DllGetClassObject"); return 3; }
        var dgco = (DgcoDel)Marshal.GetDelegateForFunctionPointer(proc, typeof(DgcoDel));
        Guid iid = IID_IClassFactory; IntPtr pcf;
        int hr = dgco(ref clsid, ref iid, out pcf);
        L("[probe] DllGetClassObject hr=" + Hx(hr));
        if (hr != 0 || pcf == IntPtr.Zero) return 4;
        var ci = Vt<CfCreateDel>(pcf, 3);
        Guid iidEff = IID_IWMPEffects; IntPtr peff;
        hr = ci(pcf, IntPtr.Zero, ref iidEff, out peff);
        L("[probe] CreateInstance(IID_IWMPEffects) hr=" + Hx(hr));
        if (hr != 0 || peff == IntPtr.Zero)
        {
            Guid iidU = IID_IUnknown; IntPtr punk;
            hr = ci(pcf, IntPtr.Zero, ref iidU, out punk);
            L("[probe] CreateInstance(IID_IUnknown) hr=" + Hx(hr));
            if (hr != 0 || punk == IntPtr.Zero) return 5;
            var qi = Vt<QiDel>(punk, 0);
            hr = qi(punk, ref iidEff, out peff);
            L("[probe] QI(IID_IWMPEffects) hr=" + Hx(hr));
            if (hr != 0 || peff == IntPtr.Zero) return 6;
        }
        Guid iid2 = IID_IWMPEffects2; IntPtr peff2;
        var qiEff = Vt<QiDel>(peff, 0);
        hr = qiEff(peff, ref iid2, out peff2);
        L("[probe] QI(IID_IWMPEffects2) hr=" + Hx(hr) + (hr == 0 ? " (IWMPEffects2 supported)" : ""));

        var setPreset = Vt<Int1Del>(peff, SLOT_SETCURRENTPRESET);
        hr = setPreset(peff, 0);
        L("[probe] SetCurrentPreset(0) hr=" + Hx(hr));
        var getCaps = Vt<OutIntDel>(peff, SLOT_GETCAPS);
        int caps = 0; hr = getCaps(peff, out caps);
        L("[probe] GetCapabilities hr=" + Hx(hr) + " caps=0x" + ((uint)caps).ToString("X8"));
        var getTitle = Vt<OutPtrDel>(peff, SLOT_GETTITLE);
        IntPtr tb; hr = getTitle(peff, out tb);
        if (hr == 0 && tb != IntPtr.Zero) { L("[probe] GetTitle='" + Marshal.PtrToStringBSTR(tb) + "'"); Marshal.FreeBSTR(tb); }
        else L("[probe] GetTitle hr=" + Hx(hr));
        var getCount = Vt<OutIntDel>(peff, SLOT_GETPRESETCOUNT);
        int pc = -1; hr = getCount(peff, out pc);
        L("[probe] GetPresetCount hr=" + Hx(hr) + " count=" + pc);
        var getCur = Vt<OutIntDel>(peff, SLOT_GETCURRENTPRESET);
        int cur = -1; hr = getCur(peff, out cur);
        L("[probe] GetCurrentPreset hr=" + Hx(hr) + " cur=" + cur);
        var getPT = Vt<IntOutPtrDel>(peff, SLOT_GETPRESETTITLE);
        IntPtr pt; hr = getPT(peff, 0, out pt);
        if (hr == 0 && pt != IntPtr.Zero) { L("[probe] GetPresetTitle(0)='" + Marshal.PtrToStringBSTR(pt) + "'"); Marshal.FreeBSTR(pt); }
        else L("[probe] GetPresetTitle(0) hr=" + Hx(hr));
        L("[probe] PROBE_OK");
        return 0;
    }

    static void FillLevels(IntPtr levels, int frame)
    {
        for (int ch = 0; ch < 2; ch++)
        {
            for (int i = 0; i < 1024; i++)
            {
                // fixed "bass beat" near index 30 + moving peak index 300..950
                double v = 235.0 * Math.Exp(-((i - 30) * (i - 30)) / (2.0 * 18 * 18)) * (0.55 + 0.45 * Math.Abs(Math.Sin(frame * 0.35)));
                double c2 = 300.0 + 350.0 * (0.5 + 0.5 * Math.Sin(frame * 0.10 + ch * 0.3));
                v += 225.0 * Math.Exp(-((i - c2) * (i - c2)) / (2.0 * 55 * 55));
                int bb = (int)Math.Max(0, Math.Min(255, v));
                Marshal.WriteByte(levels, ch * 1024 + i, (byte)bb);
            }
        }
        for (int ch = 0; ch < 2; ch++)
        {
            for (int j = 0; j < 1024; j++)
            {
                double amp = 110.0 * (0.35 + 0.65 * Math.Max(0.0, 1.0 - frame / 150.0));
                double s = Math.Sin(2 * Math.PI * (440.0 + 0.8 * frame) * j / 22050.0 + ch * 0.5);
                int bb = (int)(128.0 + amp * s);
                Marshal.WriteByte(levels, 2048 + ch * 1024 + j, (byte)Math.Max(0, Math.Min(255, bb)));
            }
        }
        Marshal.WriteInt32(levels, 4096, 2);                    // play_state
        Marshal.WriteInt64(levels, 4104, (long)frame * 330000L); // 100ns units (33 ms)
    }

    static int CountNonBlack(byte[] px)
    {
        int n = 0;
        for (int i = 0; i < px.Length; i += 4)
            if ((px[i] | px[i + 1] | px[i + 2]) > 16) n++;
        return n;
    }

    static int CountDiff(byte[] a, byte[] b)
    {
        int n = 0;
        for (int i = 0; i < a.Length; i += 4)
            if ((a[i] != b[i]) || (a[i + 1] != b[i + 1]) || (a[i + 2] != b[i + 2])) n++;
        return n;
    }

    static void SavePng(byte[] px, int w, int h, string path)
    {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppRgb))
        {
            var bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppRgb);
            for (int y = 0; y < h; y++)
                Marshal.Copy(px, y * w * 4, (IntPtr)(bd.Scan0.ToInt64() + (long)y * bd.Stride), w * 4);
            bmp.UnlockBits(bd);
            bmp.Save(path, ImageFormat.Png);
        }
    }

    static int ModeRender(string dll, Guid clsid, string outDir)
    {
        Directory.CreateDirectory(outDir);
        L("[render] dll=" + dll + " clsid=" + clsid.ToString("B") + " out=" + outDir);
        IntPtr h = LoadLibraryW(FullPath(dll));
        if (h == IntPtr.Zero) { L("[render] LoadLibrary FAILED err=" + Hx(Marshal.GetLastWin32Error())); return 2; }
        L("[render] LoadLibrary OK");
        IntPtr proc = GetProcAddress(h, "DllGetClassObject");
        if (proc == IntPtr.Zero) { L("[render] no DllGetClassObject"); return 3; }
        var dgco = (DgcoDel)Marshal.GetDelegateForFunctionPointer(proc, typeof(DgcoDel));
        Guid iid = IID_IClassFactory; IntPtr pcf;
        int hr = dgco(ref clsid, ref iid, out pcf);
        L("[render] DllGetClassObject hr=" + Hx(hr));
        if (hr != 0 || pcf == IntPtr.Zero) return 4;
        var ci = Vt<CfCreateDel>(pcf, 3);
        Guid iidEff = IID_IWMPEffects; IntPtr peff;
        hr = ci(pcf, IntPtr.Zero, ref iidEff, out peff);
        L("[render] CreateInstance(IID_IWMPEffects) hr=" + Hx(hr));
        if (hr != 0 || peff == IntPtr.Zero)
        {
            Guid iidU = IID_IUnknown; IntPtr punk;
            hr = ci(pcf, IntPtr.Zero, ref iidU, out punk);
            L("[render] CreateInstance(IID_IUnknown) hr=" + Hx(hr));
            if (hr != 0 || punk == IntPtr.Zero) return 5;
            var qi = Vt<QiDel>(punk, 0);
            hr = qi(punk, ref iidEff, out peff);
            L("[render] QI(IID_IWMPEffects) hr=" + Hx(hr));
            if (hr != 0 || peff == IntPtr.Zero) return 6;
        }
        Guid iid2 = IID_IWMPEffects2; IntPtr peff2;
        var qiEff = Vt<QiDel>(peff, 0);
        hr = qiEff(peff, ref iid2, out peff2);
        L("[render] QI(IID_IWMPEffects2) hr=" + Hx(hr) + (hr == 0 ? " (IWMPEffects2 supported)" : ""));

        var setPreset = Vt<Int1Del>(peff, SLOT_SETCURRENTPRESET);
        hr = setPreset(peff, 0);
        L("[render] SetCurrentPreset(0) hr=" + Hx(hr));
        var getCaps = Vt<OutIntDel>(peff, SLOT_GETCAPS);
        int caps = 0; hr = getCaps(peff, out caps);
        L("[render] GetCapabilities hr=" + Hx(hr) + " caps=0x" + ((uint)caps).ToString("X8"));
        var getTitle = Vt<OutPtrDel>(peff, SLOT_GETTITLE);
        IntPtr tb; hr = getTitle(peff, out tb);
        if (hr == 0 && tb != IntPtr.Zero) { L("[render] GetTitle='" + Marshal.PtrToStringBSTR(tb) + "'"); Marshal.FreeBSTR(tb); }
        else L("[render] GetTitle hr=" + Hx(hr));
        var getCount = Vt<OutIntDel>(peff, SLOT_GETPRESETCOUNT);
        int pc = -1; hr = getCount(peff, out pc);
        L("[render] GetPresetCount hr=" + Hx(hr) + " count=" + pc);
        var getPT = Vt<IntOutPtrDel>(peff, SLOT_GETPRESETTITLE);
        IntPtr pt; hr = getPT(peff, 0, out pt);
        if (hr == 0 && pt != IntPtr.Zero) { L("[render] GetPresetTitle(0)='" + Marshal.PtrToStringBSTR(pt) + "'"); Marshal.FreeBSTR(pt); }
        else L("[render] GetPresetTitle(0) hr=" + Hx(hr));
        var mediaInfo = Vt<MediaInfoDel>(peff, SLOT_MEDIAINFO);
        IntPtr bstrTitle = Marshal.StringToBSTR("Spike Synthetic Track");
        hr = mediaInfo(peff, 2, 44100, bstrTitle);
        L("[render] MediaInfo(2,44100,'Spike Synthetic Track') hr=" + Hx(hr));
        Marshal.FreeBSTR(bstrTitle);

        IntPtr memDc = CreateCompatibleDC(IntPtr.Zero);
        var bi = new BITMAPINFOHEADER();
        bi.biSize = (uint)Marshal.SizeOf(typeof(BITMAPINFOHEADER));
        bi.biWidth = W; bi.biHeight = -H; bi.biPlanes = 1; bi.biBitCount = 32; bi.biCompression = 0;
        int bmiSize = Marshal.SizeOf(typeof(BITMAPINFOHEADER)) + 64;
        IntPtr biPtr = Marshal.AllocHGlobal(bmiSize);
        for (int i = 0; i < bmiSize; i++) Marshal.WriteByte(biPtr, i, 0);
        Marshal.StructureToPtr(bi, biPtr, false);
        IntPtr bits; IntPtr hbmp = CreateDIBSection(memDc, biPtr, 0, out bits, IntPtr.Zero, 0);
        L("[render] memDC=0x" + memDc.ToInt64().ToString("X") + " dib=0x" + hbmp.ToInt64().ToString("X") + " bits=0x" + bits.ToInt64().ToString("X"));
        if (hbmp == IntPtr.Zero || memDc == IntPtr.Zero) { L("[render] DIB creation failed"); return 7; }
        SelectObject(memDc, hbmp);
        IntPtr blackBrush = GetStockObject(4);
        RECT rc; rc.Left = 0; rc.Top = 0; rc.Right = W; rc.Bottom = H;
        IntPtr levels = Marshal.AllocHGlobal(TL_SIZE);
        for (int i = 0; i < TL_SIZE; i++) Marshal.WriteByte(levels, i, 0);
        var render = Vt<RenderDel>(peff, SLOT_RENDER);

        byte[] frame0 = null;
        var saved = new Dictionary<int, byte[]>();
        var hrHist = new Dictionary<int, int>();
        bool[] saveAt = new bool[FRAMES]; saveAt[0] = saveAt[29] = saveAt[59] = saveAt[89] = saveAt[119] = true;

        for (int f = 0; f < FRAMES; f++)
        {
            FillRect(memDc, ref rc, blackBrush);
            FillLevels(levels, f);
            int rhr = render(peff, levels, memDc, ref rc);
            if (!hrHist.ContainsKey(rhr)) hrHist[rhr] = 0;
            hrHist[rhr]++;
            if (saveAt[f])
            {
                byte[] px = new byte[W * H * 4];
                Marshal.Copy(bits, px, 0, px.Length);
                if (f == 0) frame0 = px;
                saved[f] = px;
                SavePng(px, W, H, Path.Combine(outDir, "frame_" + f.ToString("D3") + ".png"));
                L("[render] frame " + f + " render_hr=" + Hx(rhr) + " nonblack=" + CountNonBlack(px) + "/" + (W * H));
            }
            Thread.Sleep(10);
        }
        foreach (int f in new int[] { 29, 59, 89, 119 })
        {
            if (frame0 != null && saved.ContainsKey(f))
            {
                int d = CountDiff(frame0, saved[f]);
                L("[render] diff(frame_000, frame_" + f.ToString("D3") + ") = " + d + " px (" + (100.0 * d / (W * H)).ToString("F1") + "%)");
            }
        }
        foreach (var kv in hrHist) L("[render] Render hr " + Hx(kv.Key) + " count=" + kv.Value);
        FindCurrentWindows();
        L("[render] RENDER_DONE");
        return 0;
    }

    static int RunChild(string exe, string args, string logFile)
    {
        var psi = new ProcessStartInfo(exe, args);
        psi.UseShellExecute = false;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.CreateNoWindow = true;
        var p = Process.Start(psi);
        string o = p.StandardOutput.ReadToEnd();
        string e = p.StandardError.ReadToEnd();
        p.WaitForExit();
        int ec = p.ExitCode;
        string txt = "===== child [" + args + "] exit=" + Hx(ec) + " =====\r\n" + o + (e.Length > 0 ? "[stderr]\r\n" + e : "");
        File.AppendAllText(logFile, txt + "\r\n");
        Console.WriteLine("child [" + args + "] exit=" + Hx(ec));
        Console.Out.Flush();
        return ec;
    }

    static int ModeRun(string dll, string outDir)
    {
        Directory.CreateDirectory(outDir);
        string logFile = Path.Combine(outDir, "log.txt");
        string exe = System.Reflection.Assembly.GetEntryAssembly().Location;
        File.AppendAllText(logFile, "\r\n######## spike run " + DateTime.Now.ToString("s") + " dll=" + dll + " ########\r\n");
        Console.WriteLine("[run] orchestrating " + dll + " -> " + outDir);

        // 1) scan (no DLL load in parent)
        ModeScan(dll, Path.Combine(outDir, "candidates.txt"));

        // 2) sweep in child
        string hitsFile = Path.Combine(outDir, "sweep_hits.txt");
        if (File.Exists(hitsFile)) File.Delete(hitsFile);
        RunChild(exe, "sweep \"" + dll + "\" \"" + hitsFile + "\"", logFile);
        if (!File.Exists(hitsFile)) { Console.WriteLine("[run] no hits file - sweep crashed or found nothing; see log"); return 10; }
        string[] hits = File.ReadAllLines(hitsFile);
        if (hits.Length == 0) { Console.WriteLine("[run] sweep found no matching CLSID"); return 11; }
        Console.WriteLine("[run] CLSID hits: " + string.Join(", ", hits));

        // 3) probe each hit in child until one is a real IWMPEffects
        string winner = null;
        foreach (string hit in hits)
        {
            string h = hit.Trim();
            if (h.Length == 0) continue;
            int ec = RunChild(exe, "probe \"" + dll + "\" " + h, logFile);
            if (ec == 0)
            {
                // confirm stdout had PROBE_OK — RunChild doesn't return it, so re-check log tail is enough:
                string tail = File.ReadAllText(logFile);
                int idx = tail.LastIndexOf("child [probe");
                if (idx >= 0 && tail.IndexOf("PROBE_OK", idx) > 0) { winner = h; break; }
            }
        }
        if (winner == null) { Console.WriteLine("[run] no CLSID passed probe"); return 12; }
        Console.WriteLine("[run] winner CLSID: " + winner);

        // 4) render in child
        int rec = RunChild(exe, "render \"" + dll + "\" " + winner + " \"" + outDir + "\"", logFile);
        Console.WriteLine("[run] render child exit=" + Hx(rec));
        return rec;
    }

    [STAThread]
    static int Main(string[] args)
    {
        try { Console.OutputEncoding = Encoding.UTF8; } catch { }
        if (args.Length < 2) { Console.WriteLine("usage: WmpHost scan|sweep|probe|render|run ..."); return 1; }
        try
        {
            switch (args[0])
            {
                case "scan": return ModeScan(args[1], args.Length > 2 ? args[2] : null);
                case "sweep": return ModeSweep(args[1], args[2]);
                case "probe": return ModeProbe(args[1], new Guid(args[2]));
                case "render": return ModeRender(args[1], new Guid(args[2]), args[3]);
                case "run": return ModeRun(args[1], args[2]);
                default: Console.WriteLine("unknown mode " + args[0]); return 1;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("FATAL: " + ex);
            return 99;
        }
    }
}
