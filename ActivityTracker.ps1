$NewClassName = 'Win32_UserActivityTime'
$Date = Get-Date
# Settings
$activeTime = 0
$inactiveTime = 0
$interval = 60  # Kontrol aralığı (saniye)
$totalTime = 0
$targetDuration = 3600 #saniye  (1 saat) Toplam çalışacak süre hedef süre (3600 saniye üzerinden)
$passiveThreshold = 30  # 30 saniye - #$passiveThreshold, kullanıcının bilgisayarda klavye - Mouse basmadığı süre için tolerans değeridir.Örnek: 30sn telefonda konuşabilir.O anı pasif olarak saymayacaktır. Eğer 30'den sonra halen pasif ise pasif olarak sayacaktır.




# WMI sınıfını oluşturun
$newClass = New-Object System.Management.ManagementClass ("root\cimv2", [String]::Empty, $null)
$newClass["__CLASS"] = $NewClassName

$newClass.Qualifiers.Add("Static", $true)
$newClass.Properties.Add("Timestamp", [System.Management.CimType]::String, $false)
$newClass.Properties.Add("ActiveTime", [System.Management.CimType]::String, $false)
$newClass.Properties.Add("InactiveTime", [System.Management.CimType]::String, $false)
$newClass.Properties.Add("ScriptLastRan", [System.Management.CimType]::String, $false)
$newClass.Properties["Timestamp"].Qualifiers.Add("Key", $true)
$newClass.Put() 

function Write-Log() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path = "C:\Windows\Temp\Win32_UserActivityTime.Log",
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level = "Info"
    )
    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {
		if (Test-Path $Path) {
			$LogSize = (Get-Item -Path $Path).Length/1MB
			$MaxLogSize = 5
		}
        # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
            Remove-Item $Path -Force
            $NewLogFile = New-Item $Path -Force -ItemType File
        }
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (-NOT(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
        }
        else {
            # Nothing to see here yet.
        }
        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End {
    }
}

Add-Type @"
    using System;
    using System.Runtime.InteropServices;

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
    $lii.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lii)

    if ([UserInputInfo]::GetLastInputInfo([ref]$lii)) {
        $idleMillis = [System.Environment]::TickCount - $lii.dwTime
        return $idleMillis / 1000.0
    } else {
        throw "Failed to retrieve last input info."
    }
}

function Is-UserActive {
    $idleness = Get-IdleDuration
    return $idleness -lt $passiveThreshold
}

function Update-ActivityStats {
    param (
        [double]$idleness
    )

    $isUserActive = Is-UserActive

    if ($isUserActive) {
        Write-Host "away or active ($idleness sec w/o interact)"
        $global:activeTime += $interval
    } else {
        Write-Host "away or active ($idleness sec w/o interact)"
        $global:inactiveTime += $interval
    }
    Write-Host "Is User Active: $isUserActive"
}

while ($totalTime -lt $targetDuration) {
    Start-Sleep -Seconds $interval
    $idleness = Get-IdleDuration
    Update-ActivityStats -idleness $idleness

    $global:totalTime += $interval
}

$activeMinutes = [math]::Round($global:activeTime / 60, 2)
$inactiveMinutes = [math]::Round($global:inactiveTime / 60, 2)

Write-Host "Total Active Time: $($activeMinutes) minutes"
Write-Host "Total Inactive Time: $($inactiveMinutes) minutes"
#Wmi 'e verileri kayıt eder
Set-WmiInstance -Namespace root\cimv2 -Class $NewClassName -Argument @{
    ActiveTime = $activeMinutes
    InactiveTime = $inactiveMinutes
    ScriptLastRan = $Date
} 

Get-WmiObject -Class $NewClassName | Select-Object ActiveTime, InactiveTime, Timestamp, ScriptLastRan | Sort-Object ScriptLastRan | ft