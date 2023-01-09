<# 
.SYNOPSIS
   Start this script to run the reverseshell resever or VNC client

.DESCRIPTION 
    ..
 
.NOTES 
    Make sure that "tvnviewer.exe" is in the same folder as this script

    like to have. 
        Log: send all logs back to admin
        Runnow: send run now to host, ePO api


.LINK 
    Download VNC from https://www.tightvnc.com/
    Extract the ececuteboles for the package and the admin console side
  
.LINK
    code ustes for the reverse shell https://github.com/ZHacker13/ReverseTCPShell
#>
[int]$Local_Console_Port = 1616
[int]$Local_VNC_Port = 5900

function start-vnc-client{
    Write-Host " - Starting VNC client"
    Start-Process -FilePath tvnviewer.exe -ArgumentList "-listen"
    Start-Sleep -Seconds 1
    if((Get-Process -Name tvnviewer -ErrorAction SilentlyContinue).count -gt 0){
        Write-Host " - VNC client is listening for client to connect." -ForegroundColor DarkGreen
    } else {
        Write-Host " - VNC client is not running." -ForegroundColor DarkRed
    }
}

function stop-vnc-client{
    Write-Host " - stopping VNC client."
    Stop-Process -Name tvnviewer -Force
    Start-Sleep -Seconds 1
    if((Get-Process -Name tvnviewer -ErrorAction SilentlyContinue).count -gt 0){
        Write-Host " - VNC client is not stopping." -ForegroundColor DarkRed
    } else {
        Write-Host " - VNC client is stopt." -ForegroundColor DarkGreen
    }
}

function Get-HostAddress {
    $r = Get-NetIPAddress | Select-Object IPAddress | Where-Object IPAddress -NotIn "::1","127.0.0.1" | Where-Object IPAddress -NotLike "169.254.*"
    $r = ($r | Format-Table -HideTableHeaders | Out-String).Trim()
    $r =  $r + "`n" + [System.Net.Dns]::GetHostByName($env:computerName).HostName
    return $r
}

function Check_free_Ports {
    netstat -na | Select-String LISTENING | % {
        If(($_.ToString().split(":")[1].split(" ")[0]) -eq "$Local_Console_Port")
        {
            Write-Host " - Console port in use. Please change port." -ForegroundColor DarkRed
            exit 1
        }
        If(($_.ToString().split(":")[1].split(" ")[0]) -eq "$Local_VNC_Port")
        {
            Write-Host " - Default VNC port in use."  -ForegroundColor DarkRed
            exit 1
        }
    }
    Write-Host " - Ports are free for you to use." -ForegroundColor DarkGreen
}

function Start-ReverseShell {
    #start script
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File ReverseShell.ps1 -port $($Local_Console_Port) "
}

Clear-Host;

[String]$ePO = "-time <minutes> -host <address>"

Check_free_Ports

Write-Host " - Use the folowing IP addresses in ePO"
Get-HostAddress
Write-Host "Do you like to start VNC?"
:loop while(-1){
    switch (Read-Host '(Y/N)'){
        Y { 
            start-vnc-client
            $ePO="$ePO -VNC"
            break loop
        }
        N {break loop}
        default { Write-Host 'Only Y/N valid' -fore red }
    }
}

Write-Host "Do you like to start Reverse shell?"
:loop while(-1){
    switch (Read-Host '(Y/N)'){
        Y { 
            Start-ReverseShell
            $ePO="$ePO -Console -port $Local_Console_Port"
            break loop
        }
        N {break loop}
        default { Write-Host 'Only Y/N valid' -fore red }
    }
}
Write-Host -ForegroundColor DarkGreen "Add the folowing string in ePO as command"
Write-Host $ePO



