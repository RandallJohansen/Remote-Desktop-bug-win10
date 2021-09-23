

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Const PS1_file = "RDP HD"
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


' second parameter: 0 = hide (powershell) window
'
' third (last) parameter:  
'    False = (default) DON'T pause script for objshell to finish
'    True = DO pause script for objshell to finish


' --  HIDE  --
 CreateObject("Wscript.Shell").Run  "powershell.exe  -WindowStyle hidden  -ExecutionPolicy bypass  -NonInteractive  -File " & chr(34) & PS1_file  & ".ps1" & chr(34), 0, True


' -- SHOW --
' CreateObject("Wscript.Shell").Run  "powershell.exe  -NoExit  -ExecutionPolicy bypass  -NonInteractive  -File " & chr(34) & PS1_file  & ".ps1" & chr(34), 1, True


