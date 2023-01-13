# EEDK VNC and Revers Shell 
## build.cmd 
Run this to build the package for ePO.

## adminConsole.ps1
Run this before you deploy the package to a agent. This will provide the options to run VNC and Revers Shell. 
At the end it will provide the command that you need to give in ePO:
-time <minutes> -host <address> -VNC -Console -port 1616


Based on the work from Steen Pedersen https://github.com/SteenPedersen/EEDK_PowerShell_template
# EEDK_PowerShell_template
Example of a PowerShell template script which can be deployed and provide feedback to ePO using Custom Props.

Make sure to place both the .CMD and .PS1 in an empty folder and use the EEDK to select that folder.
This will create an ePO package with both script files included.
