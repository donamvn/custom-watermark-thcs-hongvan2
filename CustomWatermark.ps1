param(
    [string]$Line1 = "🏫 THCS Hồng Vân 2, PH Duyên Thái ✨",
    [string]$Line2 = "💻 Bộ môn Tin học 🌸",
    [switch]$InstallStartup,
    [switch]$UninstallStartup,
    [switch]$RestoreOriginal
)

$startupCmdPath = Join-Path ([Environment]::GetFolderPath('Startup')) "CustomWatermark.cmd"
$scriptPath = $MyInvocation.MyCommand.Path

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

Add-Type @"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class WatermarkWin32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORY_BASIC_INFORMATION {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public IntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesRead);

    [DllImport("kernel32.dll")]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    public static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    private static int cachedExplorerPid = 0;
    private static IntPtr cachedStructAddr = IntPtr.Zero;
    private static IntPtr cachedHwnd = IntPtr.Zero;

    public static bool FindWatermarkStruct(out int explorerPid, out IntPtr structAddr, out IntPtr hwnd) {
        explorerPid = 0;
        structAddr = IntPtr.Zero;
        hwnd = IntPtr.Zero;

        // Kiểm tra cache trước để tối ưu hiệu năng (0ms)
        if (cachedExplorerPid != 0 && cachedStructAddr != IntPtr.Zero) {
            IntPtr hCheck = OpenProcess(0x0410, false, cachedExplorerPid);
            if (hCheck != IntPtr.Zero) {
                try {
                    byte[] checkBuf = new byte[0x100];
                    int r = 0;
                    if (ReadProcessMemory(hCheck, cachedStructAddr, checkBuf, checkBuf.Length, out r) && r == checkBuf.Length) {
                        if (BitConverter.ToUInt64(checkBuf, 0x18) == 0x0000000600000006UL &&
                            BitConverter.ToUInt32(checkBuf, 0xB8) == 0xFFA8A8A8U) {
                            explorerPid = cachedExplorerPid;
                            structAddr = cachedStructAddr;
                            hwnd = (IntPtr)BitConverter.ToInt64(checkBuf, 0x28);
                            cachedHwnd = hwnd;
                            return hwnd != IntPtr.Zero;
                        }
                    }
                } finally {
                    CloseHandle(hCheck);
                }
            }
        }

        // Quét vùng nhớ stack của explorer.exe (~15ms) để lấy đúng HWND của "Worker Window" (ZBID_SYSTEM_TOOLS)
        foreach (Process p in Process.GetProcessesByName("explorer")) {
            IntPtr h = OpenProcess(0x0410, false, p.Id);
            if (h == IntPtr.Zero) continue;
            try {
                long addr = 0;
                MEMORY_BASIC_INFORMATION mbi;
                uint mbiSize = (uint)Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION));
                while (VirtualQueryEx(h, (IntPtr)addr, out mbi, mbiSize) != 0) {
                    long size = mbi.RegionSize.ToInt64();
                    if (mbi.State == 0x1000 && mbi.Protect == 0x04 && size <= 0x200000) {
                        byte[] buf = new byte[size];
                        int r = 0;
                        if (ReadProcessMemory(h, mbi.BaseAddress, buf, (int)size, out r) && r > 0x100) {
                            for (int i = 0; i <= r - 0x100; i += 8) {
                                if (BitConverter.ToUInt64(buf, i + 0x18) == 0x0000000600000006UL &&
                                    BitConverter.ToUInt32(buf, i + 0xB8) == 0xFFA8A8A8U) {
                                    IntPtr foundHwnd = (IntPtr)BitConverter.ToInt64(buf, i + 0x28);
                                    if (foundHwnd != IntPtr.Zero) {
                                        cachedExplorerPid = p.Id;
                                        cachedStructAddr = (IntPtr)(mbi.BaseAddress.ToInt64() + i);
                                        cachedHwnd = foundHwnd;
                                        explorerPid = cachedExplorerPid;
                                        structAddr = cachedStructAddr;
                                        hwnd = cachedHwnd;
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                    addr = mbi.BaseAddress.ToInt64() + size;
                    if (addr <= 0 || addr >= 0x7FFFFFFFFFFF) break;
                }
            } finally {
                CloseHandle(h);
            }
        }
        return false;
    }

    public static void CloseExistingCustomOverlays() {
        EnumWindows((hWnd, lParam) => {
            StringBuilder txt = new StringBuilder(128);
            GetWindowText(hWnd, txt, 128);
            if (txt.ToString() == "CustomWatermarkOverlay") {
                PostMessage(hWnd, 0x0010, IntPtr.Zero, IntPtr.Zero); // WM_CLOSE
            }
            return true;
        }, IntPtr.Zero);
    }

    public static void ToggleOriginalWatermark(bool show) {
        int pid;
        IntPtr structAddr;
        IntPtr hWnd;
        if (!FindWatermarkStruct(out pid, out structAddr, out hWnd)) return;

        if (show) {
            // WM_USER + 5 (0x0405) với wParam = 0x212: Bảo explorer.exe khôi phục mode = 2 và vẽ lại Watermark gốc
            PostMessage(hWnd, 0x0405, (IntPtr)0x212, IntPtr.Zero);
            ShowWindow(hWnd, 4); // SW_SHOWNOACTIVATE
            PostMessage(hWnd, 0x0406, IntPtr.Zero, IntPtr.Zero);
        } else {
            // 1. Xóa vùng vẽ chữ (rcLine1, rcLine2) trong struct của explorer.exe để nếu có vẽ lại cũng trong suốt 100%
            IntPtr hProc = OpenProcess(0x0038, false, pid);
            if (hProc != IntPtr.Zero) {
                try {
                    byte[] zeroRects = new byte[32];
                    int w = 0;
                    WriteProcessMemory(hProc, (IntPtr)(structAddr.ToInt64() + 0xBC), zeroRects, zeroRects.Length, out w);
                } finally {
                    CloseHandle(hProc);
                }
            }
            // 2. Gửi WM_USER + 5 (0x0405) với wParam = 0: Chính luồng của explorer.exe sẽ đặt mode = 0 và tự gọi SetWindowPos(SWP_HIDEWINDOW) trên ZBID_SYSTEM_TOOLS
            PostMessage(hWnd, 0x0405, IntPtr.Zero, IntPtr.Zero);
            ShowWindow(hWnd, 0); // SW_HIDE
            SetWindowPos(hWnd, IntPtr.Zero, -32000, -32000, 0, 0, 0x0095);
        }
    }

    public static void MakeClickThrough(IntPtr hWnd) {
        int exStyle = GetWindowLong(hWnd, -20);
        // WS_EX_TRANSPARENT (0x20) | WS_EX_LAYERED (0x80000) | WS_EX_TOOLWINDOW (0x80) | WS_EX_NOACTIVATE (0x08000000)
        SetWindowLong(hWnd, -20, exStyle | 0x00000020 | 0x00080000 | 0x00000080 | 0x08000000);
    }
}
"@

if ($UninstallStartup) {
    if (Test-Path $startupCmdPath) {
        Remove-Item $startupCmdPath -Force
        Write-Host "[OK] Đã gỡ tự khởi động tại: $startupCmdPath" -ForegroundColor Green
    }
    Unregister-ScheduledTask -TaskName "CustomWatermarkTask" -Confirm:$false -ErrorAction SilentlyContinue
    $RestoreOriginal = $true
}

if ($RestoreOriginal) {
    [WatermarkWin32]::CloseExistingCustomOverlays()
    [WatermarkWin32]::ToggleOriginalWatermark($true)
    Write-Host "[OK] Đã đóng Watermark tùy chỉnh và khôi phục Watermark gốc của Windows." -ForegroundColor Cyan
    exit
}

if ($InstallStartup) {
    $cmdContent = "@echo off`r`nstart `"`" powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"`r`n"
    Set-Content -Path $startupCmdPath -Value $cmdContent -Encoding ASCII
    Write-Host "[OK] Đã cài đặt tự khởi động cùng Windows tại: $startupCmdPath" -ForegroundColor Green
}

# Đóng các cửa sổ CustomWatermarkOverlay cũ
[WatermarkWin32]::CloseExistingCustomOverlays()

# Ẩn cửa sổ Watermark gốc (ClassName = "Worker Window" trên ZBID_SYSTEM_TOOLS) của explorer.exe
[WatermarkWin32]::ToggleOriginalWatermark($false)

# Tạo cửa sổ Overlay trong suốt, click xuyên qua, đúng font & màu sắc (#FFA8A8A8) của Windows
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="CustomWatermarkOverlay"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ResizeMode="NoResize"
        SizeToContent="WidthAndHeight"
        IsHitTestVisible="False"
        Focusable="False">
    <StackPanel Margin="0,0,50,42" IsHitTestVisible="False">
        <TextBlock Name="TxtLine1"
                   FontFamily="Segoe UI, Segoe UI Emoji"
                   FontSize="20"
                   Foreground="#99CFCFCF"
                   TextAlignment="Left" />
        <TextBlock Name="TxtLine2"
                   FontFamily="Segoe UI, Segoe UI Emoji"
                   FontSize="15"
                   Foreground="#99CFCFCF"
                   TextAlignment="Left"
                   Margin="0,1,0,0" />
    </StackPanel>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$txt1 = $window.FindName("TxtLine1")
$txt2 = $window.FindName("TxtLine2")
$txt1.Text = $Line1
$txt2.Text = $Line2

$updatePosition = {
    $workArea = [System.Windows.SystemParameters]::WorkArea
    $window.Left = $workArea.Right - $window.ActualWidth
    $window.Top  = $workArea.Bottom - $window.ActualHeight
    [WatermarkWin32]::ToggleOriginalWatermark($false)
}

$window.Add_SourceInitialized({
    $interop = New-Object System.Windows.Interop.WindowInteropHelper($window)
    [WatermarkWin32]::MakeClickThrough($interop.Handle)
})

$window.Add_Loaded({
    & $updatePosition
})

$window.Add_SizeChanged({
    & $updatePosition
})

# Định kỳ 2 giây kiểm tra giữ ẩn watermark gốc và đảm bảo luôn nổi trên cùng
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(2)
$timer.Add_Tick({
    [WatermarkWin32]::ToggleOriginalWatermark($false)
    $window.Topmost = $false
    $window.Topmost = $true
})
$timer.Start()

[void]$window.ShowDialog()
