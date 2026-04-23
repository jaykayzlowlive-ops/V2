# ============================================================
# SECXION VPLUS | INTERACTIVE KERNEL TUNER
# ============================================================
$Purple = "#BC13FE"; $Cyan = "#00FFFF"

Function Show-Header {
    Clear-Host
    Write-Host @"
   ███████╗███████╗ ██████╗██╗  ██╗██╗ ██████╗ ███╗   ██╗    ██╗   ██╗██████╗ ██╗     ██╗   ██╗███████╗
   ██╔════╝██╔════╝██╔════╝╚██╗██╔╝██║██╔═══██╗████╗  ██║    ██║   ██║██╔══██╗██║     ██║   ██║██╔════╝
   ███████╗█████╗  ██║      ╚███╔╝ ██║██║   ██║██╔██╗ ██║    ██║   ██║██████╔╝██║     ██║   ██║███████╗
   ╚════██║██╔══╝  ██║      ██╔██╗ ██║██║   ██║██║╚██╗██║    ╚██╗ ██╔╝██╔═══╝ ██║     ██║   ██║╚════██║
   ███████║███████╗╚██████╗██╔╝ ██╗██║╚██████╔╝██║ ╚████║     ╚████╔╝ ██║     ███████╗╚██████╔╝███████║
   ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═══╝  ╚═╝     ╚══════╝ ╚═════╝ ╚══════╝
   >> EDITION: VPLUS | SELECT AN OPTION TO BEGIN <<
"@ -ForegroundColor Magenta
}

Function Show-Progress {
    param([string]$TaskName)
    Write-Host -NoNewline "`n[*] $TaskName " -ForegroundColor Cyan
    for ($i = 0; $i -le 10; $i++) {
        Write-Host -NoNewline "█" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 20
    }
    Write-Host " [OK]" -ForegroundColor Green
}

# --- FUNCTIONS FOR EACH OPTION ---
Function Apply-HID {
    Show-Progress "Setting DataQueueSize to 16"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass" -Name "DataQueueSize" -Value 16
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass" -Name "DataQueueSize" -Value 16
    # Mouse Additional Regs (10+)
    $mPath = "HKCU:\Control Panel\Mouse"
    Set-ItemProperty -Path $mPath -Name "MouseSpeed" -Value 0
    Set-ItemProperty -Path $mPath -Name "MouseSensitivity" -Value 10
}

Function Apply-Kernel {
    Show-Progress "Configuring Win32Priority & BCD"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    bcdedit /set disabledynamictick yes | Out-Null
    bcdedit /set useplatformtick yes | Out-Null
}

Function Apply-Network {
    Show-Progress "Resetting Network & TCP NoDelay"
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | % {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
    }
}

Function Apply-Cleanup {
    Show-Progress "Cleaning Logs & Junk Files"
    Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | ForEach-Object { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) }
    $CleanPath = @("$env:TEMP\*", "$env:windir\Temp\*", "$env:windir\Prefetch\*")
    foreach ($path in $CleanPath) { Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- MAIN MENU LOOP ---
do {
    Show-Header
    Write-Host "`n [1] OPTIMIZE HID (MOUSE/KBD 16)" -ForegroundColor White
    Write-Host " [2] KERNEL & WIN32 PRIORITY" -ForegroundColor White
    Write-Host " [3] NETWORK LATENCY & RESET" -ForegroundColor White
    Write-Host " [4] CLEAN JUNK & EVENT LOGS" -ForegroundColor White
    Write-Host " [5] RUN ALL (FULL OPTIMIZATION)" -ForegroundColor Cyan
    Write-Host " [6] WIPE HISTORY & EXIT" -ForegroundColor Red
    Write-Host "`n SELECT OPTION [1-6]: " -NoNewline
    $Choice = Read-Host

    switch ($Choice) {
        "1" { Apply-HID; pause }
        "2" { Apply-Kernel; pause }
        "3" { Apply-Network; pause }
        "4" { Apply-Cleanup; pause }
        "5" { Apply-HID; Apply-Kernel; Apply-Network; Apply-Cleanup; Write-Host "`n[!] ALL SYSTEMS BOOSTED!"; pause }
        "6" { 
            Write-Host "`n[*] Wiping Traces..." -ForegroundColor Red
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
            Clear-History
            [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
            Write-Host "[*] Done. Goodbye!" -ForegroundColor Red
            Start-Sleep -Seconds 1
            exit
        }
    }
} while ($true)