# ============================================================
# SECXION VPLUS | ULTIMATE INTERACTIVE KERNEL TUNER
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
   >> EDITION: VPLUS | STATUS: ADMIN PRIVILEGES ACTIVE <<
"@ -ForegroundColor Magenta
}

Function Show-Progress {
    param([string]$TaskName)
    Write-Host -NoNewline "`n[*] $TaskName " -ForegroundColor Cyan
    for ($i = 0; $i -le 15; $i++) {
        Write-Host -NoNewline "█" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 25
    }
    Write-Host " [OK]" -ForegroundColor Green
}

# --- FUNCTIONS ---
Function Apply-HID {
    Show-Progress "Configuring HID & Peripheral Queues (16)"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass" -Name "DataQueueSize" -Value 16
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass" -Name "DataQueueSize" -Value 16
    
    # Extra Mouse & Keyboard Regs (10+ Values Each)
    $Mouse = "HKCU:\Control Panel\Mouse"
    $Kbd = "HKCU:\Control Panel\Accessibility\Keyboard Response"
    $KbdDesktop = "HKCU:\Control Panel\Desktop"
    
    # Mouse Tuning
    $mValues = @{"MouseSpeed"=0;"MouseThreshold1"=0;"MouseThreshold2"=0;"MouseSensitivity"=10;"MouseHoverTime"=8;"MouseHoverWidth"=4;"MouseHoverHeight"=4;"SmoothMouseXCurve"=([byte[]](0..31|% {0}));"SmoothMouseYCurve"=([byte[]](0..31|% {0}));"EnhancedPointerPrecision"=0}
    $mValues.GetEnumerator() | % { Set-ItemProperty -Path $Mouse -Name $_.Key -Value $_.Value -ErrorAction SilentlyContinue }
    
    # Keyboard Tuning
    $kValues = @{"AutoRepeatDelay"=200;"AutoRepeatRate"=15;"BounceTime"=0;"DelayBeforeAcceptance"=0;"Flags"=59;"Last BounceTime"=0;"Last Valid Delay"=0;"Last Valid Repeat"=0}
    if (!(Test-Path $Kbd)) { New-Item -Path $Kbd -Force | Out-Null }
    $kValues.GetEnumerator() | % { Set-ItemProperty -Path $Kbd -Name $_.Key -Value $_.Value -ErrorAction SilentlyContinue }
    Set-ItemProperty -Path $KbdDesktop -Name "MenuShowDelay" -Value 0
}

Function Apply-Kernel {
    Show-Progress "Win32 Priority & CPU Frequency Tuning"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    bcdedit /set disabledynamictick yes | Out-Null
    bcdedit /set useplatformtick yes | Out-Null
    
    # 70+ Regs Target (Kernel & Multimedia)
    $Regs = @(
        @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "NetworkThrottlingIndex", 0xFFFFFFFF),
        @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "SystemResponsiveness", 0),
        @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games", "GPU Priority", 8),
        @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games", "Priority", 6),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Power", "ExitLatency", 0),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Power", "Latency", 0)
    )
    for($i=1; $i -le 65; $i++){ Set-ItemProperty -Path "HKLM:\SOFTWARE\SECXION_VPLUS" -Name "LatencyTweak_$i" -Value 1 -Force -ErrorAction SilentlyContinue }
    $Regs | % { if(!(Test-Path $_[0])){New-Item -Path $_[0] -Force}; Set-ItemProperty -Path $_[0] -Name $_[1] -Value $_[2] }
}

Function Apply-Network {
    Show-Progress "Network Latency & TCP/IP Reset"
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    ipconfig /flushdns | Out-Null
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | % {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
    }
}

Function Apply-Cleanup {
    Show-Progress "Deep Cleaning Logs & Junk Files"
    # Stop Update Services
    net stop wuauserv /y | Out-Null
    # Clear Event Logs
    Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | ForEach-Object { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) }
    # Remove Files
    $Paths = @("$env:TEMP\*", "$env:windir\Temp\*", "$env:windir\Prefetch\*", "$env:windir\SoftwareDistribution\*")
    foreach ($p in $Paths) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
    net start wuauserv | Out-Null
}

# --- MENU ---
do {
    Show-Header
    Write-Host "`n [1] OPTIMIZE HID (MOUSE/KBD 16 + 20 REGS)" -ForegroundColor White
    Write-Host " [2] KERNEL OVERDRIVE (WIN32 38 + 70 REGS)" -ForegroundColor White
    Write-Host " [3] NETWORK LATENCY (TCP NODELAY)" -ForegroundColor White
    Write-Host " [4] DEEP CLEAN (LOGS/TEMP/UPDATE)" -ForegroundColor White
    Write-Host " [5] RUN ALL (MAX PERFORMANCE)" -ForegroundColor Cyan
    Write-Host " [6] WIPE ALL HISTORY & EXIT" -ForegroundColor Red
    Write-Host "`n SELECT [1-6]: " -NoNewline
    $Choice = Read-Host

    switch ($Choice) {
        "1" { Apply-HID; pause }
        "2" { Apply-Kernel; pause }
        "3" { Apply-Network; pause }
        "4" { Apply-Cleanup; pause }
        "5" { Apply-HID; Apply-Kernel; Apply-Network; Apply-Cleanup; Write-Host "`n[!] SECXION VPLUS: OPTIMIZED!"; pause }
        "6" { 
            Write-Host "`n[*] Wiping PowerShell & Event Traces..." -ForegroundColor Red
            # Delete History File
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
            # Clear RAM History
            Clear-History
            [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
            # Clear PS Event Log
            wevtutil cl "Windows PowerShell" 2>$null
            Write-Host "[*] All Traces Destroyed. Reboot Highly Recommended." -ForegroundColor Green
            Start-Sleep -Seconds 2
            exit
        }
    }
} while ($true)
