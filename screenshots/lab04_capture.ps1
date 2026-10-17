param([string]$TestId, [string]$FileName)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi04 {
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
$scriptPath = "C:\Users\User\lab-ia-chatbot\screenshots\lab04_run_test.ps1"
Start-Process powershell -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File",$scriptPath,"-TestNum",$TestId -WindowStyle Maximized

# Wait based on test type
if ($TestId -in @("10")) {
    Start-Sleep -Seconds 180
} elseif ($TestId -in @("2","3","5","8","exp1","exp2","exp3","exp4")) {
    Start-Sleep -Seconds 45
} elseif ($TestId -in @("9")) {
    Start-Sleep -Seconds 35
} else {
    Start-Sleep -Seconds 20
}

# Bring PS window to foreground
$psProc = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq 'Windows PowerShell' } | Select-Object -First 1
if ($psProc) {
    [WinApi04]::ShowWindow($psProc.MainWindowHandle, 3) | Out-Null
    [WinApi04]::SetForegroundWindow($psProc.MainWindowHandle) | Out-Null
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
