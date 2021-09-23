

<#

user32.dll is part of the win32 api, which was originally meant for C++ applications. 

When Microsoft rolled out .NET (and soon after, C#), they did not provide native support.

In order to run a .NET application, requires the .NET dll binaries.


user32.dll does not contain the same functions across different versions of Windows. 

blanket-import everything will most likely ensure program can run only on specific version of Windows currently using.

import a native function, should check what version it came from.

#>



# inline C++ code

Add-Type @"

  using System;

  using System.Runtime.InteropServices;

  public class Win32 {

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]

    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]

    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
  }

  public struct RECT
  {
    public int Left;        // x position of upper-left corner
    public int Top;         // y position of upper-left corner
    public int Right;       // x position of lower-right corner
    public int Bottom;      // y position of lower-right corner
  }
"@



# & "C:\windows\system32\mstsc.exe"
# 
# $wshell = New-Object -ComObject wscript.shell;
# $wshell.AppActivate('title of the application window')
# Sleep 1
# $wshell.SendKeys('~')

$width  =   960   # 
#$height =   720   #  width / 1.33  4x3
#$height =   540   #  width / 1.777  16x9 HD 1280 x 720, 1920 x 1080
$height =   596   #  width / 1.61  UHD  3480x2160

$height = $height + 22  # good guess for titlebar

# overkill on the casting, it's the native type
# NOTE:  if there's more than one window, we're just affecting the first one
$handle = New-Object System.IntPtr
$handle = [System.IntPtr](Get-Process | where {$_.MainWindowTitle -like "*Remote Desktop*"})[0].MainWindowHandle

# not used - good for cut paste checking where it's at
$Rectangle = New-Object RECT  
[Win32]::GetWindowRect($handle,[ref]$Rectangle)
$Rectangle

Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen

[Win32]::MoveWindow( $handle , $screen.Bounds.Width - $width , 5 , $width , $height , $true )
