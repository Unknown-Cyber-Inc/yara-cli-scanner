@echo off

setlocal enabledelayedexpansion

set /a count=0

REM Create/overwrite match outfile
set outfile=%cd%\matches_out.txt
echo.>%outfile%

for %%f in (*.yarac) do (
    set cliout=cli_output-%%f.txt
    REM Run yara command at low priority
    REM Using `cmd` seems to be necessary to get `start` to actually run the whole block
    REM Otherwise I suspect it might have been piping the start command output (nothing)
    REM instead of running the whole line under start (and therefore piping the yara output)
    start /low /wait cmd /c yara64.exe -C %%f -r %1 ^| sort ^> !cliout!
    
    for /f "tokens=1,2" %%a in (!cliout!) do (
        if not defined zip_name (
            set "zip_name=found"
        )
        REM Add match line to output match text file
        echo %%a %%b>>!outfile!

        set "file_path=%%b"

        REM If we have a match list, see if we want to append another file to it
        if defined file_list (
            echo.!file_list! | findstr /C:"%%b">nul && (
                REM File already seen, do not append it again
                echo Duplicate file %%b
            ) || (
                REM File not seen, append it to the file list
                set "file_list=!file_list! "!file_path!""
            )
        )

        REM If we don't have a match list, start one
        if not defined file_list (
            set "file_list="!file_path!""
        )

        set /a count+=1
    )
    
    if exist !cliout! del !cliout!
)

REM Grab first listed MAC Address and Source
REM findstr "\-" used to throw away header line, as all MAC addresses will have the "-"
for /f "tokens=1,3 delims=," %%a in ('"getmac /v /fo csv | findstr "\-""') do (
    if not defined mac (
        set mac=%%b
        set mactype=%%a
    )
)
REM Fallback values if no MAC Addresses found
if not defined mac (
    set mac="unknown"
    set mactype="unknown"
)

REM zip_name was used as a check for any matches found before we stopped using the
REM yara rule name, so am still using it as an easy check.
if not defined zip_name (
    set "zip_name="%cd%\Windows_!mac!_detections_0.zip""
    REM 7z will create an empty archive if no valid filepaths are passed to it
    REM May add randomization to the fake filename as well if desired later
    7za a -tzip -pinfected !zip_name! thisfiledoesntexist.gibberish
) else (
    set "zip_name="%cd%\Windows_!mac!_detections_!count!.zip""
    7za a -tzip -pinfected !zip_name! !file_list!
)

if exist %outfile% del %outfile%
