# ============================================================
# SECXION VPLUS | ULTIMATE KERNEL & NETWORK (FIXED ASCII)
# ============================================================
# บังคับการแสดงผลเป็น UTF-8 เพื่อให้รูปสวยงาม
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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
   >> INTEGRATED: SETNET.PS1 | ENCODING: UTF-8 <<
"@ -ForegroundColor Magenta
}

Function Show-Progress {
    param([string]$TaskName)
    Write-Host -NoNewline "`n[*] $TaskName " -ForegroundColor Cyan
    for ($i = 0; $i -le 10; $i++) {
        Write-Host -NoNewline "█" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 25
    }
    Write-Host " [SUCCESS]" -ForegroundColor Green
}

# --- 1. HID & MOUSE TUNING ---
Function Apply-HID {
    Show-Progress "Applying HID QueueSize (16) & Mouse Regs"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass" -Name "DataQueueSize" -Value 16
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass" -Name "DataQueueSize" -Value 16
    $mPath = "HKCU:\Control Panel\Mouse"
    $mValues = @{"MouseSpeed"=0;"MouseThreshold1"=0;"MouseThreshold2"=0;"MouseSensitivity"=10;"EnhancedPointerPrecision"=0}
    $mValues.GetEnumerator() | % { Set-ItemProperty -Path $mPath -Name $_.Key -Value $_.Value -ErrorAction SilentlyContinue }
}

# --- 2. KERNEL & WIN32 PRIORITY ---
Function Apply-Kernel {
    Show-Progress "Configuring Win32PrioritySeparation (38)"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    bcdedit /set disabledynamictick yes | Out-Null
    bcdedit /set useplatformtick yes | Out-Null
    for($i=1; $i -le 70; $i++){ Set-ItemProperty -Path "HKLM:\SOFTWARE\SECXION_VPLUS" -Name "Latency_$i" -Value 1 -Force -ErrorAction SilentlyContinue }
}

# --- 3. SETNET V2 (Integrated from GitHub) ---
Function Apply-SetNet {
    Show-Progress "Executing SetNet Overhaul (TCPIP/NIC)"
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    ipconfig /flushdns | Out-Null
    netsh int tcp set global autotuninglevel=disabled
    netsh int tcp set global rss=enabled
    netsh int tcp set global chimney=enabled
    netsh int tcp set global dca=enabled
    netsh int tcp set global netqos=policy
    netsh int tcp set global ecncapability=disabled
    netsh int tcp set global timestamps=disabled
    $Interfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $Interfaces | % {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks" -Value 0 -ErrorAction SilentlyContinue
    }
}

# --- 4. DEEP CLEAN ---
Function Apply-Cleanup {
    Show-Progress "Deep Cleaning Logs & Junk Files"
    Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | ForEach-Object { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) }
    $Paths = @("$env:TEMP\*", "$env:windir\Temp\*", "$env:windir\Prefetch\*")
    foreach ($p in $Paths) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- MAIN MENU ---
do {
    Show-Header
    Write-Host "`n [1] OPTIMIZE HID (MOUSE/KBD 16)" -ForegroundColor White
    Write-Host " [2] KERNEL & WIN32 PRIORITY (38)" -ForegroundColor White
    Write-Host " [3] SETNET V2 (TCPIP & NIC OVERHAUL)" -ForegroundColor Cyan
    Write-Host " [4] DEEP CLEAN LOGS & JUNK" -ForegroundColor White
    Write-Host " [5] RUN ALL (FULL OPTIMIZATION)" -ForegroundColor Green
    Write-Host " [6] WIPE ALL HISTORY & EXIT" -ForegroundColor Red
    Write-Host "`n SELECT OPTION [1-6]: " -NoNewline
    $Choice = Read-Host

    switch ($Choice) {
        "1" { Apply-HID; pause }
        "2" { Apply-Kernel; pause }
        "3" { Apply-SetNet; pause }
        "4" { Apply-Cleanup; pause }
        "5" { Apply-HID; Apply-Kernel; Apply-SetNet; Apply-Cleanup; Write-Host "`n[!] ALL SYSTEMS BOOSTED!"; pause }
        "6" { 
            Write-Host "`n[*] Destroying Traces..." -ForegroundColor Red
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
            Clear-History
            [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
            wevtutil cl "Windows PowerShell" 2>$null
            Write-Host "[*] Session Wiped. Reboot to finish." -ForegroundColor Red
            Start-Sleep -Seconds 1
            exit
        }
    }
} while ($true)
