param([string]$TestId, [string]$FileName)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

# Close any existing PS window
Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq 'Windows PowerShell' } | Stop-Process -Force -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Open new PS window with test
$scriptPath = "C:\Users\User\lab-ia-chatbot\screenshots\run_test.ps1"
Start-Process powershell -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File",$scriptPath,"-TestNum",$TestId -WindowStyle Maximized

if ($TestId -in @("5","topk","9","grounding")) {
    Start-Sleep -Seconds 60
} else {
    Start-Sleep -Seconds 15
}

# Bring PS window to foreground
$psProc = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq 'Windows PowerShell' } | Select-Object -First 1
if ($psProc) {
    [WinApi]::ShowWindow($psProc.MainWindowHandle, 3) | Out-Null  # SW_MAXIMIZE
    [WinApi]::SetForegroundWindow($psProc.MainWindowHandle) | Out-Null
    Start-Sleep -Seconds 2
}

# Take screenshot
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$bitmap.Save("C:\Users\User\lab-ia-chatbot\screenshots\$FileName", [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Screenshot saved: $FileName"
