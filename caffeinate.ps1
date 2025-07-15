<#
.SYNOPSIS
    Windows "caffeinate" – prevent sleep/display sleep just like macOS caffeinate.

.DESCRIPTION
    Prevents Windows from sleeping, turning off the display, or going idle using the 
    SetThreadExecutionState Win32 API. Supports wrapping commands and time limits.

.PARAMETER d
    Prevent the display from sleeping (ES_DISPLAY_REQUIRED)

.PARAMETER i
    Prevent the system from idle sleeping (ES_SYSTEM_REQUIRED)

.PARAMETER s
    Prevent the system from sleeping (same as -i for Windows compatibility)

.PARAMETER u
    Send a user-present pulse to reset idle timer (ES_USER_PRESENT)

.PARAMETER t
    Duration in seconds to maintain caffeinate state (0 = indefinite)

.PARAMETER Command
    Command and arguments to execute while maintaining caffeinate state

.EXAMPLE
    # Keep the display awake for two hours
    .\caffeinate.ps1 -d -t 7200

.EXAMPLE
    # Prevent system sleep while a long build runs
    .\caffeinate.ps1 -i -- msbuild MySolution.sln /m

.EXAMPLE
    # Keep system awake indefinitely (Ctrl+C to stop)
    .\caffeinate.ps1 -i
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Prevent display from sleeping")]
    [switch]$d,
    
    [Parameter(HelpMessage = "Prevent system from idle sleeping")]
    [switch]$i,
    
    [Parameter(HelpMessage = "Prevent system from sleeping (alias for -i)")]
    [switch]$s,
    
    [Parameter(HelpMessage = "Send user-present pulse")]
    [switch]$u,
    
    [Parameter(HelpMessage = "Duration in seconds (0 = indefinite)")]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$t = 0,
    
    [Parameter(ValueFromRemainingArguments = $true, HelpMessage = "Command to execute")]
    [string[]]$Command
)

#region Constants and Types

# Windows SetThreadExecutionState constants
$script:ExecutionStateFlags = @{
    ES_CONTINUOUS        = 0x80000000
    ES_SYSTEM_REQUIRED   = 0x00000001
    ES_DISPLAY_REQUIRED  = 0x00000002
    ES_AWAYMODE_REQUIRED = 0x00000040
    ES_USER_PRESENT      = 0x00000004
}

# Sleep interval for maintaining state (Windows clears after ~60s)
$script:SleepInterval = 50
$script:ProcessCheckInterval = 10

# Import SetThreadExecutionState Win32 API
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class PowerManagement
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

#endregion

#region Helper Functions

function Get-ExecutionStateFlags {
    <#
    .SYNOPSIS
        Calculate the execution state flags based on parameters
    #>
    [CmdletBinding()]
    param()
    
    [uint]$state = $ExecutionStateFlags.ES_CONTINUOUS
    
    if ($d) { 
        $state = $state -bor $ExecutionStateFlags.ES_DISPLAY_REQUIRED 
        Write-Verbose "Display sleep prevention enabled"
    }
    
    if ($i -or $s) { 
        $state = $state -bor $ExecutionStateFlags.ES_SYSTEM_REQUIRED 
        Write-Verbose "System sleep prevention enabled"
    }
    
    # User-present requires display flag to keep screen on
    if ($u) { 
        $state = $state -bor $ExecutionStateFlags.ES_DISPLAY_REQUIRED 
        Write-Verbose "User-present mode enabled with display protection"
    }
    
    return $state
}

function Set-PowerState {
    <#
    .SYNOPSIS
        Set the thread execution state using Win32 API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uint]$Flags
    )
    
    try {
        $result = [PowerManagement]::SetThreadExecutionState($Flags)
        if ($result -eq 0) {
            Write-Warning "Failed to set power state. GetLastError: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())"
            return $false
        }
        Write-Verbose "Power state set successfully with flags: 0x$($Flags.ToString('X8'))"
        return $true
    }
    catch {
        Write-Error "Error setting power state: $($_.Exception.Message)"
        return $false
    }
}

function Send-UserPresentPulse {
    <#
    .SYNOPSIS
        Send a one-time user-present pulse to reset idle timer
    #>
    [CmdletBinding()]
    param()
    
    $userPresentFlags = $ExecutionStateFlags.ES_CONTINUOUS -bor $ExecutionStateFlags.ES_USER_PRESENT
    $result = Set-PowerState -Flags $userPresentFlags
    if ($result) {
        Write-Verbose "User-present pulse sent successfully"
    }
}

function Wait-WithPowerAssertion {
    <#
    .SYNOPSIS
        Maintain power assertion for specified duration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uint]$PowerFlags,
        
        [int]$TimeoutSeconds = 0
    )
    
    $startTime = [DateTime]::UtcNow
    $indefinite = $TimeoutSeconds -le 0
    
    Write-Verbose "Starting power assertion $(if ($indefinite) { 'indefinitely' } else { "for $TimeoutSeconds seconds" })"
    
    while ($true) {
        Start-Sleep -Seconds $SleepInterval
        
        if (-not (Set-PowerState -Flags $PowerFlags)) {
            Write-Warning "Failed to maintain power state"
        }
        
        if (-not $indefinite) {
            $elapsed = ([DateTime]::UtcNow - $startTime).TotalSeconds
            if ($elapsed -ge $TimeoutSeconds) {
                Write-Verbose "Timeout reached after $([Math]::Round($elapsed, 1)) seconds"
                break
            }
        }
    }
}

function Start-ProcessWithPowerAssertion {
    <#
    .SYNOPSIS
        Execute a command while maintaining power assertion
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CommandArgs,
        
        [Parameter(Mandatory)]
        [uint]$PowerFlags
    )
    
    if ($CommandArgs.Count -eq 0) {
        throw "No command specified"
    }
    
    $executable = $CommandArgs[0]
    $arguments = $CommandArgs[1..($CommandArgs.Length - 1)]
    
    Write-Host "Starting command: $executable $(if ($arguments) { $arguments -join ' ' })"
    Write-Verbose "Maintaining power assertion while command executes..."
    
    try {
        $processParams = @{
            FilePath     = $executable
            NoNewWindow  = $true
            PassThru     = $true
        }
        
        if ($arguments) {
            $processParams.ArgumentList = $arguments
        }
        
        $process = Start-Process @processParams
        
        while (-not $process.HasExited) {
            Start-Sleep -Seconds $ProcessCheckInterval
            
            if (-not (Set-PowerState -Flags $PowerFlags)) {
                Write-Warning "Failed to maintain power state during command execution"
            }
        }
        
        Write-Host "Command completed with exit code: $($process.ExitCode)"
        return $process.ExitCode
    }
    catch {
        Write-Error "Failed to execute command: $($_.Exception.Message)"
        return 1
    }
}

function Test-Parameters {
    <#
    .SYNOPSIS
        Validate parameter combinations
    #>
    [CmdletBinding()]
    param()
    
    # Check if any power flags are specified
    if (-not ($d -or $i -or $s -or $u)) {
        Write-Warning "No power management flags specified. Use -d (display), -i/-s (system), or -u (user-present)"
        Write-Host "Use Get-Help $($MyInvocation.ScriptName) for more information"
        return $false
    }
    
    # Validate command format
    if ($Command -and $Command.Count -eq 0) {
        Write-Error "Command parameter specified but empty"
        return $false
    }
    
    return $true
}

#endregion

#region Main Logic

function Invoke-Caffeinate {
    <#
    .SYNOPSIS
        Main caffeinate logic
    #>
    [CmdletBinding()]
    param()
    
    # Validate parameters
    if (-not (Test-Parameters)) {
        exit 1
    }
    
    # Calculate execution state flags
    $powerFlags = Get-ExecutionStateFlags
    
    # Set initial power state
    if (-not (Set-PowerState -Flags $powerFlags)) {
        Write-Error "Failed to set initial power state"
        exit 1
    }
    
    # Send user-present pulse if requested
    if ($u) {
        Send-UserPresentPulse
    }
    
    try {
        if ($Command) {
            # Execute wrapped command
            $exitCode = Start-ProcessWithPowerAssertion -CommandArgs $Command -PowerFlags $powerFlags
            exit $exitCode
        }
        elseif ($t -gt 0) {
            # Run for specified time
            Write-Host "Caffeinate active for $t seconds – press Ctrl+C to exit early"
            Wait-WithPowerAssertion -PowerFlags $powerFlags -TimeoutSeconds $t
        }
        else {
            # Run indefinitely
            Write-Host "Caffeinate active indefinitely – press Ctrl+C to exit"
            Wait-WithPowerAssertion -PowerFlags $powerFlags
        }
    }
    catch {
        Write-Error "Caffeinate interrupted: $($_.Exception.Message)"
        exit 1
    }
    finally {
        # Clear power assertion on exit
        Write-Verbose "Clearing power assertions"
        [void][PowerManagement]::SetThreadExecutionState($ExecutionStateFlags.ES_CONTINUOUS)
    }
}

#endregion

# Entry point
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Caffeinate
}
