@echo off


REM Set variables
set bbox=%1
set alti_name=%2

set data_dir=%CD%\the8

set output_folder=%CD%\output


REM Try to remove the output folder
if exist "%output_folder%" (
	:retry_output_folder
	rmdir /s /q "%output_folder%"
	if errorlevel 1 (
		echo WARNING: Unable to delete output_folder. It may be in use. Retrying in 5 seconds...
		timeout /t 5
		goto retry_output_folder
	)
)
mkdir "%output_folder%"


REM Start: Use already downloaded data?
set /p use_existing="Do you want to use already downloaded TIF-files (y/n)? "
if /i "%use_existing%"=="y" (
	echo Using TIF-files...
	
	REM Set starting timer
	set startTime=%time%
) else (
	REM REM Try to remove the data_dir
	REM if exist "%data_dir%" (
		REM :retry_data_dir
		REM rmdir /s /q "%data_dir%"
		REM if errorlevel 1 (
			REM echo WARNING: Unable to delete data_dir. It may be in use. Retrying in 5 seconds...
			REM timeout /t 5
			REM goto retry_data_dir
		REM )
	REM )
	REM mkdir "%data_dir%"

	REM REM Set starting timer
	REM set startTime=%time%
	REM echo generate alti...

	REM set jsonname=swissalti3d-raster_data.json
	
    REM REM URL
    REM set next_url="https://data.geo.admin.ch/api/stac/v0.9/collections/ch.swisstopo.swissalti3d/items?bbox=%bbox%"
    
    REM REM REM :download_loop
	REM REM :download_loop
    REM wget %next_url% -O files/%jsonname%
    
    REM REM REM Download GeoTIFFs from JSON
    REM python download_tiffs.py "%jsonname%"
    REM python find_next_link.py "%jsonname%"

	REM set downloadtifTime=%time%
	REM call :GetDuration %startTime% %downloadtifTime%
	REM echo Downloading tifs time: %duration% seconds
	REM echo ------------------------------
	REM echo:
)

REM Call Python script to download GeoTIFFs
set mergedStartTime=%time%
set mergename=alti_all
python merge_tiffs.py "%mergename%.tif"
set mergedEndTime=%time%
call :GetDuration %mergedStartTime% %mergedEndTime%
echo Merging tifs time: %duration% seconds
echo ------------------------------
echo:

echo %data_dir%\%mergename%.tif

REM Calculate alti files (calc="A" for meters and calc="A*100")
gdal_calc.py -A "%data_dir%\%mergename%.tif" --outfile="%output_folder%\%alti_name%_temp.tif" --calc="A*100" --NoDataValue=-9999
del "%data_dir%\%mergename%.tif"
REM gdalwarp -overwrite -s_srs EPSG:2056 -t_srs EPSG:4326 -r near -of AAIGrid -ot Float32 "%output_folder%\%alti_name%_temp.tif" "%output_folder%\%alti_name%.asc"
gdalwarp -overwrite -s_srs EPSG:2056 -t_srs EPSG:4326 -r near -of GTIFF -co TILED=YES -ot UInt32 "%output_folder%\%alti_name%_temp.tif" "%output_folder%\%alti_name%.tif"

set endTime=%time%
call :GetDuration %startTime% %endTime%


REM Output the total execution time
echo Total script execution time: %duration% seconds
exit /b
	

:GetDuration
    setlocal
    set start=%1
    set end=%2

    REM Split the start and end times into hours, minutes, and seconds
    for /f "tokens=1-3 delims=:.," %%a in ("%start%") do (
        set startHour=%%a
        set startMinute=%%b
        set startSecond=%%c
    )

    for /f "tokens=1-3 delims=:.," %%a in ("%end%") do (
        set endHour=%%a
        set endMinute=%%b
        set endSecond=%%c
    )

    REM Remove leading zeros from hours, minutes, and seconds
    set /a startHour=1%startHour% - 100
    set /a startMinute=1%startMinute% - 100
    set /a startSecond=1%startSecond% - 100

    set /a endHour=1%endHour% - 100
    set /a endMinute=1%endMinute% - 100
    set /a endSecond=1%endSecond% - 100

    REM Convert start time to seconds
    set /a startSeconds=(startHour * 3600) + (startMinute * 60) + startSecond

    REM Convert end time to seconds
    set /a endSeconds=(endHour * 3600) + (endMinute * 60) + endSecond

    REM Calculate duration in seconds
    set /a duration=endSeconds - startSeconds
    if %duration% lss 0 (
        set /a duration=duration + 86400
    )

    endlocal & set duration=%duration%
    exit /b