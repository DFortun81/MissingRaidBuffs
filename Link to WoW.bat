:: Run this batch script to link the MissingRaidBuffs addon with all non-PTR versions of the game.
:: If it does NOT report "Linking using root WoW folder: ..." in the command output, then make sure to add your personal WoW install directory
:: into the :do_links label of the script similar to existing examples
@echo off
SETLOCAL
pushd %~dp0

:: Set the target folder name (case-insensitive match)
set "TargetName=World of Warcraft"
set "MatchedDir="
set "Name="
set "Parent="

:: Start from the batch’s directory (without trailing backslash)
set "Dir=%~dp0"
if "%Dir:~-1%"=="\" set "Dir=%Dir:~0,-1%"

:Up
:: Extract folder name and parent
for %%F in ("%Dir%") do (
    set "Name=%%~nxF"
    set "Parent=%%~dpF"
)

:: Compare
if /I "%Name%"=="%TargetName%" (
    set "MatchedDir=%Dir%"
    goto :Found
)

:: If we’re at root, stop
if "%Parent:~-2%"==":\" goto :NotFound

:: Move up one level
set "Dir=%Parent:~0,-1%"

goto :Up

:Found
echo Found target folder: %MatchedDir%
goto :do_links

:NotFound
echo Target folder "%TargetName%" not found in folder heirarchy above this file
goto :do_links

:do_links
if defined MatchedDir (
    call :link_wowfolder "%MatchedDir%"
) else (
    call :link_wowfolder "C:\Program Files\World of Warcraft"
    call :link_wowfolder "C:\Program Files (x86)\World of Warcraft"
    call :link_wowfolder "..\World of Warcraft"
    call :link_wowfolder "..\Blizzard\World of Warcraft"
    call :link_wowfolder "F:\World of Warcraft"
)
call :report_taskcomplete
EXIT /B 0

:link_wowfolder
if exist "%~1\" (
    echo "Linking using root WoW folder: %~1"
    call :link_expansion "%~1\_anniversary_"
    call :link_expansion "%~1\_classic_"
    call :link_expansion "%~1\_classic_era_"
    call :link_expansion "%~1\_classic_beta_"
    call :link_expansion "%~1\_classic_ptr_"
    call :link_expansion "%~1\_classic_era_ptr_"
    call :link_expansion "%~1\_retail_"
    call :link_expansion "%~1\_beta_"
    call :link_expansion "%~1\_ptr_"
    call :link_expansion "%~1\_xptr_"
)
EXIT /B 0

:link_expansion
if exist "%~1\" (
    echo Linking Expansion "%~1\"
    if exist "%~1\Interface\AddOns\MissingRaidBuffs" (
        rmdir /s /q "%~1\Interface\AddOns\MissingRaidBuffs"
    )
    if NOT exist "%~1\Interface\AddOns\MissingRaidBuffs" (
        if NOT exist "%~1\Interface" (
            mkdir "%~1\Interface"
        )
        if NOT exist "%~1\Interface\AddOns" (
            mkdir "%~1\Interface\AddOns"
        )
        mklink /J "%~1\Interface\AddOns\MissingRaidBuffs" "%cd%"
    )
)
EXIT /B 0

:report_taskcomplete
echo Task Complete!
set /p DUMMY=Hit ENTER to close...
EXIT /B 0
