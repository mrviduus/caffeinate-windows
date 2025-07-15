<#
.SYNOPSIS
    Windows “caffeinate” – prevent sleep/display sleep just like macOS caffeinate.

.EXAMPLE
    # Keep the display awake for two hours
    .\caffeinate.ps1 -d -t 7200

.EXAMPLE
    # Prevent system sleep while a long build runs
    .\caffeinate.ps1 -i -- msbuild MySolution.sln /m
#>

param(
    [switch]$d,   # display
    [switch]$i,   # idle/system
    [switch]$s,   # system (same as -i for Windows)
    [switch]$u,   # user active
    [int]$t = 0,  # seconds
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Command
)

# Map flags to execution‑state bits
$ES_CONTINUOUS       = 0x80000000
$ES_SYSTEM_REQUIRED  = 0x00000001
$ES_DISPLAY_REQUIRED = 0x00000002
$ES_AWAYMODE_REQUIRED= 0x00000040  # optional: media servers

[int]$state = $ES_CONTINUOUS
if($d){ $state = $state -bor $ES_DISPLAY_REQUIRED }
if($i -or $s){ $state = $state -bor $ES_SYSTEM_REQUIRED }
# User-present assertion is one‑shot; include display flag so screen stays on
if($u){ $state = $state -bor $ES_DISPLAY_REQUIRED }

# Import SetThreadExecutionState
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeMethods{
  [DllImport("kernel32.dll")]
  public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

function Assert-State{
    $null = [NativeMethods]::SetThreadExecutionState($state)
}

# Initial assertion (and optionally send user-present pulse)
Assert-State
if($u){
    $null = [NativeMethods]::SetThreadExecutionState($ES_CONTINUOUS -bor 0x00000004)  # ES_USER_PRESENT
}

# Helper: maintain assertion until timeout or wrapped cmd finishes
function Hold-Assertion([int]$seconds){
    $start = [datetime]::UtcNow
    while($true){
        Start-Sleep -Seconds 50      # Windows clears idle flags after 60 s
        Assert-State
        if($seconds -gt 0 -and (([datetime]::UtcNow - $start).TotalSeconds -ge $seconds)){ break }
    }
}

# Branch: wrapped command vs. plain timer/indefinite
if($Command){
    $p = Start-Process -FilePath $Command[0] -ArgumentList $Command[1..($Command.Length-1)] -NoNewWindow -PassThru
    while(-not $p.HasExited){
        Start-Sleep -Seconds 10
        Assert-State
    }
}
else{
    if($t -gt 0){
        Hold-Assertion -seconds $t
    }else{
        Write-Host "Caffeinate active – press Ctrl‑C to exit."
        while($true){ Start-Sleep -Seconds 50; Assert-State }
    }
}