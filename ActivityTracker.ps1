Add-Type @"
    using System;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Threading;

    public class UserInputInfo {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        public struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }
    }
"@

function Get-IdleDuration {
    $lii = New-Object UserInputInfo+LASTINPUTINFO
    $lii.cbSize = [System.UInt32][System.Runtime.InteropServices.Marshal]::SizeOf($lii)

    if ([System.Boolean][UserInputInfo]::GetLastInputInfo([ref]$lii)) {
        $idleMillis = [Environment]::TickCount - $lii.dwTime
        return $idleMillis / 1000.0
    } else {
        throw [InvalidOperationException]"Failed to retrieve last input info."
    }
}

function Update-ActivityStats {
    param($idleness, [ref]$activeTime, [ref]$inactiveTime, $interval)

    if ($idleness -gt 10) {
        Write-Host "Away ($idleness sec w/o interact)"
        $inactiveTime.value += $interval
    } else {
        Write-Host "Active ($idleness sec w/o interact)"
        $activeTime.value += $interval
    }
}

function Format-Time {
    param($seconds)

    $minutes = [math]::floor($seconds / 60)
    $remainingSeconds = $seconds % 60

    if ($minutes -gt 0) {
        return "$($minutes) minute(s) $($remainingSeconds) second(s)"
    } else {
        return "$($remainingSeconds) second(s)"
    }
}

[bool]$consoleAllocated = $false

$activeTime = 0
$inactiveTime = 0
$interval = 5
$totalTime = 0
$targetDuration = 300
$logFilePath = Join-Path $env:TEMP "WorkTimepowershell.log"

$sw = [System.IO.File]::AppendText($logFilePath)

if ($sw.BaseStream.Length -eq 0) {
    $sw.WriteLine("ActiveTime`tInactiveTime`tTimestamp")
}

while ($totalTime -lt $targetDuration) {
    Start-Sleep -Seconds $interval

    $idleness = Get-IdleDuration
    Update-ActivityStats $idleness ([ref]$activeTime) ([ref]$inactiveTime) $interval

    $totalTime += $interval

    $now = Get-Date

    Write-Host "$(Format-Time $activeTime)`t$(Format-Time $inactiveTime)`t$now"

    if ($totalTime % $targetDuration -eq 0) {
        Write-Host "Total Active Time: $(Format-Time $activeTime)"
        Write-Host "Total Inactive Time: $(Format-Time $inactiveTime)"

        $formattedData = "$(Format-Time $activeTime)`t$(Format-Time $inactiveTime)`t$($now.ToString('dd.MM.yyyy HH:mm:ss'))"
        $sw.WriteLine($formattedData)
    }
}

$sw.Dispose()
