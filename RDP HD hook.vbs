

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
PS1_file = "RDP HD hook V4b"
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


''''''''''''''''''''''''''''''''''''''''
'   UNCOMMENT FEATURES AS NEEDED
''''''''''''''''''''''''''''''''''''''''
'
' Const Stay  =     " -NoExit "
'
' Const Hide  = " -WindowStyle hidden "    'use 0 parameter below, this flashes a console to the screen for a moment
'
 Const Quiet =  " -NonInteractive "
'
''''''''''''''''''''''''''''''''''''''''

CmdLine = "powershell.exe -ExecutionPolicy bypass" & Quiet & Hide & Stay & " -File " & chr(34) & PS1_file & ".ps1" & chr(34) 

CreateObject("Wscript.Shell").Run CmdLine , 0, True

' second parameter: normal=1, hide=0, 2=Min, 3=max, 4=restore, 5=current, 7=min/inactive, 10=default
'
' third (last) parameter:  
'    False = (default) DON'T pause script for objshell to finish
'    True = DO pause script for objshell to finish

