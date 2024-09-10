@echo off

setlocal enabledelayedexpansion

for /f "tokens=1,2" %%a in ('yara32.exe -C yara_rule.yarac -r %1 ^| sort') do (
    if not defined zip_name (
        set "zip_name=%%a.zip"
    )

    set "file_path=%%b"

    if defined file_list (
        set "file_list=!file_list!,"!file_path!""
    )
    if not defined file_list (
        set "file_list="!file_path!""
    )
)

if not defined zip_name (
    echo No matches found
) else (
    powershell -command "Compress-Archive -Path !file_list! -DestinationPath !zip_name!"
)
