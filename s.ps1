# ============================================================
# SECXION VPLUS | ULTIMATE KERNEL & NETWORK (BUG FIXED)
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Purple = "#BC13FE"; $Cyan = "#00FFFF"

Function Show-Header {
    Clear-Host
    # ใช้ ASCII แบบเรียบง่ายเพื่อลดโอกาสเกิดตัวอักษร ?
    Write-Host @"
    ----------------------------------------------------------
       SECXION VPLUS - ULTIMATE PERFORMANCE TUNER V2
    ----------------------------------------------------------
    >> MODE: ZERO LATENCY | TARGET: FIVE-M <<
"@ -ForegroundColor Magenta
}

Function Show-Progress {
    param([string]$TaskName)
    Write-Host -NoNewline "[*] $TaskName " -ForegroundColor Cyan
    for ($i = 0; $i -le 10; $i++) {
        Write-Host -NoNewline ">" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 15
    }
    Write-Host " [DONE]" -ForegroundColor Green
}

Function Apply-HID {
    Show-Progress "Optimizing HID (16)"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass" -Name "DataQueueSize" -Value 16 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass" -Name "DataQueueSize" -Value 16 -ErrorAction SilentlyContinue
}

Function Apply-Kernel {
    Show-Progress "Configuring Kernel (38)"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction SilentlyContinue
    bcdedit /set disabledynamictick yes 2>&1 | Out-Null
    bcdedit /set useplatformtick yes 2>&1 | Out-Null
}

Function Apply-Network {
    Show-Progress "Executing SetNet Overhaul"
    netsh int ip reset > $null; netsh winsock reset > $null; ipconfig /flushdns > $null
    # TCP Tweak
    netsh int tcp set global autotuninglevel=disabled > $null
}

Function Apply-Cleanup {
    Show-Progress "Deep Cleaning Logs & Junk"
    # ข้าม Error กรณี Service ไม่ได้เปิดอยู่
    net stop wuauserv /y 2>$null | Out-Null
    
    # ล้าง Log เฉพาะที่ได้รับอนุญาต (ป้องกัน UnauthorizedAccessException)
    $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue
    foreach ($log in $logs) {
        try {
            [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($log.LogName)
        } catch {
            # ข้าม Log ที่ระบบล็อคไว้
            continue
        }
    }
    
    $Paths = @("$env:TEMP\*", "$env:windir\Temp\*", "$env:windir\Prefetch\*")
    foreach ($p in $Paths) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
    
    net start wuauserv 2>$null | Out-Null
}

do {
    Show-Header
    Write-Host "`n [1] OPTIMIZE HID (16)" -ForegroundColor White
    Write-Host " [2] KERNEL (38)" -ForegroundColor White
    Write-Host " [3] SETNET V2" -ForegroundColor Cyan
    Write-Host " [4] DEEP CLEAN" -ForegroundColor White
    Write-Host " [5] RUN ALL" -ForegroundColor Green
    Write-Host " [6] WIPE & EXIT" -ForegroundColor Red
    Write-Host "`n SELECT [1-6]: " -NoNewline
    $Choice = Read-Host

    switch ($Choice) {
        "1" { Apply-HID; pause }
        "2" { Apply-Kernel; pause }
        "3" { Apply-SetNet; pause }
        "4" { Apply-Cleanup; pause }
        "5" { Apply-HID; Apply-Kernel; Apply-SetNet; Apply-Cleanup; Write-Host "`n[!] ALL SYSTEMS BOOSTED!"; pause }
        "6" { 
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
            Clear-History
            [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
            exit
        }
    }
} while ($true)
