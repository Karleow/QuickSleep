@echo off

REM If DebugMode is not 0, don't go to sleep.
set "DebugMode=0"

REM Name of the link on your desktop to this QuickSleep batch file.
set "shortcutName=QuickSleep.lnk"

REM --- Icon Configuration ---
REM Path to a Windows system DLL that contains various icons.
REM 'imageres.dll' has many modern icons. 'shell32.dll' has older, more classic icons.
REM You can change this number to pick a different icon.
REM Common values:
REM   - imageres.dll,96
REM   - shell32.dll,27 ( 112 / 215 )
set "iconSource=%SystemRoot%\System32\shell32.dll"
REM The index (number) of the icon within the specified DLL.
set "iconIndex=215"

set "TargetScreen=external"
REM WakeUpMode, 0=enable wake events, 1=disable wake events
set "WakeUpMode=0"

REM End of configuration.

title "Change Screen & Sleep"

setlocal

REM --- Configuration for the Shortcut ---
REM The full path to this batch file. %~dpnx0 expands to drive, path, name, and extension.
set "batchFile=%~dpnx0"
REM The directory where this batch file is located, which will be the shortcut's working directory.
set "batchDir=%~dp0"
REM The directory where the shortcut will be created.
set "shortcutTargetDir=%USERPROFILE%\Desktop"
REM The full path where the shortcut will be created.
set "shortcutPath=%shortcutTargetDir%\%shortcutName%"

REM Check if the shortcut already exists to avoid recreating it every time
REM This check is now part of the main execution. It will only create the shortcut if it's missing.
if not exist "%shortcutPath%" (
    echo.
    echo --- Setting up Shortcut ---
    echo Shortcut not found. Creating it now on your Desktop...
    
    REM Create a temporary VBScript file (.vbs) to build the shortcut.
    REM Parentheses are escaped with ^ because this code is inside an IF block.
    (
    echo Set WshShell = WScript.CreateObject("WScript.Shell"^)
    echo Set oShellLink = WshShell.CreateShortcut(WScript.Arguments(0^)^)
    echo oShellLink.TargetPath = WScript.Arguments(1^)
    echo oShellLink.WorkingDirectory = WScript.Arguments(2^)
    echo oShellLink.IconLocation = WScript.Arguments(3^) ^& "," ^& WScript.Arguments(4^)
    echo oShellLink.Save
    echo Set oShellLink = Nothing
    echo Set WshShell = Nothing
    ) > "%TEMP%\create_shortcut.vbs"

    REM Execute the VBScript using cscript (Windows Script Host)
    cscript //nologo "%TEMP%\create_shortcut.vbs" "%shortcutPath%" "%batchFile%" "%batchDir%" "%iconSource%" "%iconIndex%"

    REM Clean up the temporary VBScript file
    del "%TEMP%\create_shortcut.vbs" >nul 2>&1

    REM Verify if the shortcut was successfully created and provide feedback
    if exist "%shortcutPath%" (
        echo Success! Shortcut created. The script will now continue with its main task.
    ) else (
        echo Failed to create shortcut.
        echo Ensure you have permissions to write to: "%shortcutTargetDir%"
        echo Also, check the 'iconSource' and 'iconIndex' values.
    )
)

endlocal

echo.
echo Checking if DisplaySwitch.exe is available...
where DisplaySwitch.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: DisplaySwitch.exe not found. This command is standard on Windows.
    echo Please ensure you are running this on a Windows operating system.
    pause
    exit /b 1
)

echo.
echo Attempting to switch to TARGET SCREEN MODE(%TargetScreen%) ...
REM DisplaySwitch.exe /external will attempt to activate ONLY the external/second monitor.
REM Your primary display might turn off. This assumes a second monitor is connected and detected.
DisplaySwitch.exe /%TargetScreen%

REM Give the system a moment to apply the display change
timeout /t 3 >nul

if %DebugMode% neq 0 (
    echo.
    echo Debug, don't acturally sleep.
    pause
    exit /b 0
)

echo.
echo Display command sent. Now putting the computer to sleep...
REM The following command puts the computer to sleep: (0=sleep, 1=force immediately, 0=wake events enabled)
rundll32.exe powrprof.dll,SetSuspendState 0,1,%WakeUpMode%

echo If the computer did not go to sleep, ensure sleep is enabled in Power Options.
echo This window will close automatically.
timeout /t 5 >nul
exit /b 0