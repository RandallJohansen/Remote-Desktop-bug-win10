# doc, cond closed event,


Add-Type -Assembly System.Windows.Forms   # for notifyicon

Add-Type -AssemblyName System.Drawing     # for icon


#######################
#                     #
#    Debug Window
#                     #
#######################

#region begin Instantiate Debug Window


$Hash = @{}  # wrapper.  will also add psobject wrapper.  then pass to event handler, as means of realtimereporting back


#######################
#                     #
#  Instantiate Form
#                     #
#######################

$Form = New-Object Windows.Forms.Form
$Form.StartPosition = "CenterScreen"
$Form.text = 'Debug'


#######################
#                     #
# Instantiate TextBox
#                     #
#######################

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Multiline = $true
$TextBox.ScrollBars = 'both'
$TextBox.Dock = 'Fill'        #.Anchor = 'top,left,bottom,right'
$TextBox.Font = New-Object System.Drawing.Font("Courier New",12,0,3,0)

#######################
#                     #
#   assemble pieces
#                     #
#######################

$Hash.Add( "F" , $Form )
$Hash.Add( "T", $TextBox )
$Hash.F.controls.add( $Hash.T )

#######################
#                     #
#     show Form
#                     #
#######################

$Hash.F.show()

#endregion



# inline C# code


# expose IsWindow

Add-Type -TypeDefinition @"

using System;
using System.Runtime.InteropServices;

public class User32
{

        [DllImport("user32.dll")]
          public static extern bool IsWindow(IntPtr hWnd);
}

"@


# Define EventHook class

Add-Type -TypeDefinition @"


        // You can't just put code in the class like that - everything other than declarations (e.g. fields) needs to be in a method:


using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.ComponentModel;


namespace System.Diagnostics
{

    ////////////////////////////     CLASS     ////////////////////////////

    public class EventHook : Component
    {


        ////////////////////////////     EXPOSED EVENTS     ////////////////////////////
        
        public event EventHandler Changed;
        public event EventHandler Closed;




        ////////////////////////////     vars     ////////////////////////////
        

        public IntPtr myhandle { get; set; }

        private int processId;
        private int threadId;

        private WinEventDelegate ProcDelegate = null;
        


        // Constants from winuser.h
        
        public const uint EVENT_OBJECT_DESTROY = 32769; // 0x8001

        public const uint EVENT_OBJECT_STATECHANGE = 32778; // 0x800A 

        public const uint WINEVENT_OUTOFCONTEXT = 0;

        public const uint OBJID_WINDOW = 0; // 0x00000000




        ////////////////////////////     DLL's     ////////////////////////////


        [DllImport("user32.dll")]
          public static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess,uint idThread, uint dwFlags);

        [DllImport("user32.dll")]
          public static extern bool UnhookWinEvent(IntPtr hWinEventHook);
          
        [DllImport("user32.dll")]
          public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int ProcessId);
        
        [DllImport("user32.dll")]
          public static extern bool IsWindow(IntPtr hWnd);



        ///////////////////////////////// CALLBACKS /////////////////////////////////


        public void RaiseEvent( System.EventHandler EventName )
        {

                // Make a temporary copy of the event to avoid possibility of
                // a race condition if the last subscriber unsubscribes
                // immediately after the null check and before the event is raised.
 
                EventHandler handler = EventName;
 
 

                // the event itself is null only if there are no subscribers
 
                if (null != handler) handler(this, new EventArgs()); 
 
        }


        public void TriggerChange()
        {
                RaiseEvent( Changed );
        }


        private void WinEventProc(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
        {
             // if ( OBJID_WINDOW == idObject )  // make sure it's the window and not a component
             // if ( EVENT_OBJECT_DESTROY == eventType )  // validate event type

                if ( IsWindow( myhandle ) )     // verify hwnd is still valid
                {
                      RaiseEvent( Changed );
                }
                else
                {
                        RaiseEvent( Closed );
                }
            
        }



        ///////////////////////////////// HOOKS /////////////////////////////////

        
        IntPtr HookHandle;
        

        public delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);
        
        
        public void init()
        {                
        

                threadId = 0;            
                processId = 0;
        
                threadId = GetWindowThreadProcessId(myhandle, out processId);



                //////////// SET HOOK ////////////

                // Delegates allow methods to be passed as parameters
                // we will pass this "WinEventDelegate" as a parameter to "SetWinEventHook"

                ProcDelegate = new WinEventDelegate(WinEventProc);

        
                // Set a hook to recieve "changed" event. using WinEventDelegate
                HookHandle = SetWinEventHook(EVENT_OBJECT_STATECHANGE, EVENT_OBJECT_STATECHANGE, IntPtr.Zero, ProcDelegate, (uint)processId, (uint)threadId, WINEVENT_OUTOFCONTEXT);
                
        
                // Check for error
                if (HookHandle == IntPtr.Zero)
                    throw new WinEventHookException("Error when setting Windows Changed event hook.");

        }


        ///////////////////////////////// UN-HOOK /////////////////////////////////


        public void Kill()
        {
            UnhookWinEvent(HookHandle);
         //   ProcDelegate = null;
         //   GC.SuppressFinalize(this);
        }



        ////////////////////////////     EXCEPTION     ////////////////////////////


        public class WinEventHookException : Exception
        {
            public WinEventHookException() : base() { }
            public WinEventHookException(string message) : base(message) { }

        }

    } // class

} // namespace

"@




########################     FUNCTIONS     ########################



Function AddMenu ( $TaskBarIcon ) {


        $MenuItemReHook = New-Object System.Windows.Forms.MenuItem 

        $MenuItemReHook.Text = "Re-Hook"                                       

        $MenuItemExit = New-Object System.Windows.Forms.MenuItem 

        $MenuItemExit.Text = "Exit"                                       


        $contextmenu = New-Object System.Windows.Forms.ContextMenu 

        $TaskBarIcon.ContextMenu = $contextmenu 

        $TaskBarIcon.contextMenu.MenuItems.AddRange( $MenuItemReHook ) 
        $TaskBarIcon.contextMenu.MenuItems.AddRange( $MenuItemExit ) 


        $MenuItemExit.add_Click( { 

            $TaskBarIcon.Visible = $false   # Note: If “phantom” icon remains after closing, set the Visible property to False

            $TaskBarIcon.dispose()   

         } ) 

}


Function PaintIcon( $NotifyIcon ) {

        
        # init

        $Image = new-object System.Drawing.Bitmap 32,32                # image of type .bmp

       # $font = new-object System.Drawing.Font Verdana,16              # font to use
         $font = new-object System.Drawing.Font Verdana,14

        $Bold = [System.Drawing.Font]::new("Verdana", 16, [System.Drawing.FontStyle]::Bold)

        $graphics = [System.Drawing.Graphics]::FromImage($Image)       # use bitmap as canvas

        $graphics.SmoothingMode = "AntiAlias"
                                                                                  
        $format = [System.Drawing.StringFormat]::GenericDefault           # allocate a string format
        $format.Alignment = [System.Drawing.StringAlignment]::Center      # .. set string centered  left/right
        $format.LineAlignment = [System.Drawing.StringAlignment]::Center  # .. set string centered  top/bottom

        $Rectangle = [System.Drawing.RectangleF]::FromLTRB(0, 0, $Image.Width, $Image.Height)  # basically entire icon


        # solid background with single letter 'R'

        $brushBg = [System.Drawing.Brushes]::Blue                         # background color
       # $brushBg = [System.Drawing.Brushes]::Red                         # background color
                                                                                  
        $brushFg = [System.Drawing.Brushes]::Yellow                        # foreground color

        $graphics.FillRectangle($brushBg,$Rectangle)                # Fill background

        $graphics.DrawString('R',$Bold,$brushFg,$Rectangle,$format) # Draws text string in the specified rectangle



        ##########################
        #                        #
        #        sheild
        #                        #
        ##########################


        $W = [int]$Image.Width    # both exactly 32
        $h = [int]$Image.Height
        
        $Border = 3

        $EighthWidth       = [int]( $h / 8 )
        $QuarterWidth      = [int]( $h / 4 )
        $HalfWidth         = [int]( $w / 2 )
        $ThreeQuarterWidth = [int]( $HalfWidth + $QuarterWidth )

        $EighthHeight       = [int]( $h / 8 )
        $QuarterHeight      = [int]( $h / 4 )
        $HalfHeight         = [int]( $h / 2 )
        $ThreeQuarterHeight = [int]( $HalfHeight + $QuarterHeight )

        $zero  = [int]0    # upper-left corner
        $o45   = [int]45
        $o90   = [int]90
        $o135  = [int]135
        $o180  = [int]180
        

       # $Pen = [System.Drawing.Pen]::Yellow , 3                    # foreground color
        $Pen = new-object System.Drawing.Pen White , $Border       # foreground , pixels diameter pen tip


                                    ##########################
                                    #                        #
                                    # (x,y) 0,0 = upper left
                                    #                        #
                                    ##########################


     #   $graphics.DrawLine($Pen,$X1,$Y1,$X2,$Y2) # Draws between points 1 and 2

        $graphics.DrawLine( $Pen ,      $Border     , $Border ,      $Border     , $HalfHeight ) # left upright          
        $graphics.DrawLine( $Pen , $w - $Border - 1 , $Border , $w - $Border - 1 , $HalfHeight ) # right upright          


     #   $startAngle  Angle in degrees measured clockwise from the x-axis to the starting point of the arc.
     #   $sweepAngle  Angle in degrees measured clockwise from the startAngle parameter to ending point of the arc.

     #   $graphics.DrawArc($Pen,$X,$Y,$W,$H,$startAngle,$sweepAngle) # Draws in the specified rectangle

        $graphics.DrawArc( $Pen , $Border - 1 , $zero , $w - ( 2 * $Border ) + 1 ,           $Border , $zero , $o180 ) # top arc

        $graphics.DrawArc( $Pen , $Border , $zero , $w - ( 2 * $Border ) - 1 , $h - $Border - 1 ,  $o90 ,  $o90 ) # left arc
        $graphics.DrawArc( $Pen , $Border , $zero , $w - ( 2 * $Border ) - 1 , $h - $Border - 1 , $zero ,  $o90 ) # right arc







        # cleanup

        $graphics.Dispose() 

        $icon = [System.Drawing.Icon]::FromHandle($Image.GetHicon())
        
        $Image.Dispose()
      
        $NotifyIcon.Icon = $icon


        $icon.Dispose()
                      
}


Function Re-Hook {

#unhook
#unregister
#sethandle
#register
#sethook

}


Function WaitForProcess {

 $queryParameters = '__InstanceCreationEvent', (New-Object TimeSpan 0,0,1),"TargetInstance isa 'Win32_Process'"
 
 $Query = New-Object System.Management.WqlEventQuery -ArgumentList $queryParameters
 
 $ProcessWatcher = New-Object System.Management.ManagementEventWatcher $query
 
 $newEventArgs = @{
     SourceIdentifier = 'PowerShell.ProcessCreated'
     Sender = $Sender
     EventArguments = $EventArgs.NewEvent.TargetInstance
 }
 
 $Action = { New-Event @newEventArgs }
 
 Register-ObjectEvent -InputObject $ProcessWatcher -EventName "EventArrived" -Action $Action

}


Function SetWindowHandle( $EventHookInstance ) {  


        $process = @()  # ensure array, if just one, will blow up code

        $process = Get-Process | where {$_.MainWindowTitle -like "*Remote Desktop*"}

        if ( $process.count -lt 1 ) {  # RDP not running

                # wait for spawn
                #   -or-
                # return 0
                
        }



        # overkill on the casting, it's the native type

        $handle = New-Object System.IntPtr

        # NOTE:  if there's more than one window, we're just affecting the first one
        
        $handle = [System.IntPtr]$process[0].MainWindowHandle



        # psuedo return with direct placement

        $EventHookInstance.myhandle = $handle  # pass from Powershell to C#

}


Function RegisterForEvent ( $obj , [hashtable]$H ){



        $H.T.AppendText( "`r`n ***** Registering For Event ***** `r`n " )



        $handle = $obj.myhandle

        $Hash.Add( "hwnd" , $handle )


        $pso = new-object psobject -property $H # wrap hash as prep for being MessageData

        $job = Register-ObjectEvent -InputObject $obj -EventName "Changed" -MessageData $pso -Action { 


                    [console]::beep(1000,100)  # pitch 190 - 8500 , milliseconds duration
                    
                    $Event.MessageData.T.AppendText( "`r`n ***** Event fired ***** `r`n " )
                    $Event.MessageData.T.AppendText( ( $Event | Format-List -Property * | Out-String ) )


# inline C#

<#

user32.dll is part of the win32 api, which was originally meant for C++ applications. 

When Microsoft rolled out .NET (and soon after, C#), they did not provide native support.

In order to run a .NET application, requires the .NET dll binaries.


user32.dll does not contain the same functions across different versions of Windows. 

blanket-import everything will most likely ensure program can run only on specific version of Windows currently using.

import a native function, should check what version it came from.

#>

Add-Type -TypeDefinition  @"
 
  using System;

  using System.Runtime.InteropServices;


  public class Win32 {


    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]

    public static extern bool IsWindow(IntPtr hWnd);



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


                    $Rectangle = New-Object RECT  
 

                    $width  =   960   # 

                    #$height =   720   #  width / 1.33  4x3
                    #$height =   540   #  width / 1.777  16x9 HD 1280 x 720, 1920 x 1080
                    $height =   596   #  width / 1.61  UHD  3480x2160
        
                    $height = $height + 22  # good guess for titlebar


                    $handle =  [System.IntPtr]$Event.MessageData.hwnd


                    $rc_rect = [Win32]::GetWindowRect( $handle , [ref]$Rectangle) 
                    $rc_move = [Win32]::MoveWindow( $handle , $Rectangle.Left , $Rectangle.Top , $width , $height , $true )


                  #  if ( -not ( [Win32]::IsWindow( $handle ) ) ) { [console]::beep(500,1000) }


                    $Event.MessageData.T.AppendText( "`r`n rc_rect $rc_rect `r`n" )
                    $Event.MessageData.T.AppendText( "`r`n rc_move $rc_move `r`n" )


                    # dis-engage on negative return code
                    if ( -not ( $rc_rect -and $rc_move ) ) { 

                            [console]::beep(500,1000)  # pitch 190 - 8500 , duration

                            $Event.MessageData.T.AppendText( "`r`n UN-REGISTERING `r`n" )

                            # Disable the events - does not dispose instance of class
                            $a.Kill()
                      
                            sleep -Milliseconds 200  # make sure method finished
                                                  
                            # unregister all events
                            Get-Event | Remove-Event
                            Get-EventSubscriber -Force | Unregister-Event -Force
                            Get-Job | Stop-Job
                            Get-Job | Remove-Job

                    } # if




                    sleep -Milliseconds 100  # let everything finish up


} # Action



        $H.T.AppendText( "`r`n ***** Event Subscriber ***** `r`n " )
        $H.T.AppendText( $( Get-EventSubscriber | Format-List -Property * | Out-String ) )
      #  $H.T.AppendText( $( Get-EventSubscriber | Select-Object -Property * ) )              # single line, semicolon delimited
        $H.T.AppendText( "`r`n ***** job ***** `r`n " )
        $H.T.AppendText( $( $Job | Format-List -Property * | Out-String ) )



        <#

            #### register for CLOSED event ####

        $job = Register-ObjectEvent -InputObject $obj -EventName "Closed" -MessageData $pso -Action {
      
                            [console]::beep(500,1000)  # pitch 190 - 8500 , duration

                            $Event.MessageData.T.AppendText( "`r`n UN-REGISTERING" )

                            # Disable the events - does not dispose instance of class
                            $a.Kill()
                      
                            sleep -Milliseconds 200  # make sure method finished
                                                  
                            # unregister all events
                            Get-Event | Remove-Event
                            Get-EventSubscriber -Force | Unregister-Event -Force
                            Get-Job | Stop-Job
                            Get-Job | Remove-Job
    
         } # Action

         #>



} # RegisterForEvent




########################     CREATE ICON     ########################



$TaskBarIcon = New-Object System.Windows.Forms.NotifyIcon

$TaskBarIcon.add_Click( { if ( $_.Button -eq [Windows.Forms.MouseButtons]::Left ) { $EventHook.TriggerChange() } } ) 

AddMenu $TaskBarIcon

PaintIcon $TaskBarIcon

$TaskBarIcon.Visible = $true




########################     CREATE HOOK OBJECT     ########################



$EventHook = New-Object System.Diagnostics.EventHook


# while hwnd = 0
SetWindowHandle $EventHook
# wait for process


########################     REGISTER FOR EVENT     ########################


RegisterForEvent $EventHook $Hash



########################     MAIN{} - EVENT HANDLING    ########################


#######################
#                     #
#     launch RDP
#                     #
#######################

# & "C:\windows\system32\mstsc.exe"
# 
# $wshell = New-Object -ComObject wscript.shell;
# $wshell.AppActivate('title of the application window')
# Sleep 1
# $wshell.SendKeys('~')


#######################
#                     #
#   activate events
#                     #
#######################

# Enable the event - set the hook
 $EventHook.init()

 sleep -Seconds 1  # let things settle

# test fire the event for effect
 $EventHook.TriggerChange()


#######################
#                     #
#     Loop until
#                     #
#######################

# while ( $TaskBarIcon.Visible ) { 
# 
#         [System.Windows.Forms.Application]::DoEvents()
#      #   if ( -not ( [User32]::IsWindow( $EventHook.myhandle ) ) ) { [console]::beep(400,200) }
#         sleep -Milliseconds 300 
# }

#            -OR-

while ( $TaskBarIcon.Visible ) { [System.Windows.Forms.Application]::DoEvents() ; sleep -Milliseconds 300 }

#            -OR-

# # use debug window to close app, does not work with debug hidden
#
#$RetCode = $Hash.F.ShowDialog()
# # done in cleanup at end of script: $Hash.F.close() ; $Hash.F.Dispose()
#$TaskBarIcon.Visible = $false ; $TaskBarIcon.dispose()   

#            -OR-

# # console only version ( not ISE editor or visual Studio ), remove notifyicon ( and debug ) code to use this
# 
# # $t=(get-date).AddSeconds(30) ; while ( (Get-Date ) -lt $t ) { sleep -Seconds 1 }
# Write-Host -NoNewLine 'Press any key to exit...';
# # $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
# while ( -not [Console]::KeyAvailable) { sleep -Seconds 1 }
         
#            -OR-


# # DON'T USE - does not have DoEvents()
# 
# $job = Register-ObjectEvent -SourceIdentifier Disposed -InputObject $TaskBarIcon -EventName "Disposed" # -Action { }
# 
# Wait-Event -SourceIdentifier Disposed # -Timeout 10



#######################
#                     #
#     * cleanup *
#                     #
#######################

# close debug window

$Hash.F.close() 
$Hash.F.Dispose()


# Disable the events - does not dispose instance of class
 $EventHook.Kill()

 
# unregister all events
 Get-Event | Remove-Event
 Get-EventSubscriber -Force | Unregister-Event -Force
 Get-Job | Stop-Job
 Get-Job | Remove-Job


# get rid of the reference to instance
 Remove-Variable -Name EventHook

# will call .dispose() where applicable so the thing can clean up its own resources properly
 [GC]::Collect() 


 Write-Host 'done.'

sleep -Seconds 10
