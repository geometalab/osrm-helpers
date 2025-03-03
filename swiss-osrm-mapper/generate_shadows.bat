@echo off

REM Set variables
set bbox=%1
set shadow_name=%2
set with_horizon=%3

set data_dir=%CD%\files

set output_folder=%CD%\output

echo generate shadows...

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
	echo Using TIF-file s...
	
	REM Set starting timer
	set startTime=%time%
) else (
	REM Set starting timer
	set startTime=%time%

	REM Clean up old files by removing and recreating the directories
	echo Cleaning up old directories...
	echo ------------------------------
	echo:

	REM Try to remove the data_dir
	if exist "%data_dir%" (
		:retry_data_dir
		rmdir /s /q "%data_dir%"
		if errorlevel 1 (
			echo WARNING: Unable to delete data_dir. It may be in use. Retrying in 5 seconds...
			timeout /t 5
			goto retry_data_dir
		)
	)
	mkdir "%data_dir%"

	set jsonname=swisssurface3d-raster_data.json
	
    REM URL
    set next_url="https://data.geo.admin.ch/api/stac/v0.9/collections/ch.swisstopo.swisssurface3d-raster/items?bbox=%bbox%&limit=100"
    
    REM REM :download_loop
	REM :download_loop
    wget %next_url% -O files/%jsonname%
    
    REM REM Download GeoTIFFs from JSON
    python source\download_tiffs.py "%jsonname%"
    python source\find_next_link.py "%jsonname%"

    REM Set download time
    set downloadtifTime=%time%
    call :GetDuration %startTime% %downloadtifTime%
    echo Downloading TIF files time: %duration% seconds
    echo ------------------------------
    echo:

)

REM Call Python script to download GeoTIFFs
set mergedStartTime=%time%
set mergename=surface_all
python source\merge_tiffs.py "%mergename%.tif"
set mergedEndTime=%time%
call :GetDuration %mergedStartTime% %mergedEndTime%
echo Merging tifs time: %duration% seconds
echo ------------------------------
echo:


REM Import surface into the grass gis environment
set importedStartTime=%time%
call importing_surface.bat %data_dir%\surface_all.tif

echo r.import done!
set importedEndTime=%time%
call :GetDuration %importedStartTime% %importedEndTime%
echo Importing whole surface time: %duration% seconds
echo ------------------------------
echo:

REM Setting region
set settingRegionStartTime=%time%
g.region raster=surface res=2

echo g.region done!
set settingRegionEndTime=%time%
call :GetDuration %settingRegionStartTime% %settingRegionEndTime%
echo Setting region time: %duration% seconds
echo ------------------------------
echo:

REM Conditionally calculate horizon maps if with_horizon is set to true
set horizonStartTime=%time%
if /i "%with_horizon%"=="true" (
	echo Calculating horizon maps...
	for /l %%a in (0, 45, 360) do (
		r.horizon elevation=surface output=horizon direction=%%a --overwrite
	)
	
	echo Horizon maps done!
	set horizonEndTime=%time%
	call :GetDuration %horizonStartTime% %horizonEndTime%
	echo Calculating horizon time: %duration% seconds
	echo ------------------------------
	echo:
)


REM Calculate slope and aspect from surface
set slopeAspectStartTime=%time%
r.slope.aspect --overwrite elevation=surface slope=slope aspect=aspect

echo g.slope.aspect done!
set slopeAspectEndTime=%time%
call :GetDuration %slopeAspectStartTime% %slopeAspectEndTime%
echo Calculating slope and aspect time: %duration% seconds
echo ------------------------------
echo:

REM Run r.sun with elevation, aspect, and slope maps
set sunStartTime=%time%
if /i "%with_horizon%"=="true" (
	REM Run r.sun with horizon maps
	r.sun --overwrite elevation=surface aspect=aspect slope=slope day=214 time=16 glob_rad=%shadow_name% horizon_basename=horizon horizon_step=45
) else (
	REM Run r.sun without horizon maps
	r.sun --overwrite elevation=surface aspect=aspect slope=slope day=214 time=16 glob_rad=%shadow_name%
)

echo r.sun done!
set sunEndTime=%time%
call :GetDuration %sunStartTime% %sunEndTime%
echo Calculating shadows time: %duration% seconds
echo ------------------------------
echo:

REM Check if the shadows map contains valid data
g.region raster=%shadow_name%
r.info map=%shadow_name%


REM Export the shadows map from GRASS GIS to a GeoTIFF file
set convertedStartTime=%time%
echo Exporting shadows map to shadows.tif...

REM r.rescale input=%shadow_name% output=shadow_rescaled to=0,253 --overwrite	

r.out.gdal input=%shadow_name% output="%data_dir%\shadows.tif" --overwrite 

if not exist "%data_dir%\shadows.tif" (
	echo ERROR: shadows.tif not generated.
	exit /b 1
)

REM Convert shadows to asc file and download
gdalwarp -overwrite -s_srs EPSG:2056 -t_srs EPSG:4326 -r near -of AAIGrid -ot Int32 -dstnodata -9999 "%data_dir%\shadows.tif" "%output_folder%\%shadow_name%.asc"
gdalwarp -overwrite -s_srs EPSG:2056 -t_srs EPSG:4326 -r near -of GTiff -ot Int32 -dstnodata -9999 "%data_dir%\shadows.tif" "%output_folder%\%shadow_name%.tif"

REM Problems are clip and round
REM gdal_calc.py -A "%data_dir%\shadows.tif" --outfile="%output_folder%\shadows_temp.tif" --calc="round(clip(A, 0, 253))" --NoDataValue=254
REM gdalwarp -overwrite -s_srs EPSG:2056 -t_srs EPSG:4326 -r near -of AAIGrid "%output_folder%\shadows_temp.tif" "%output_folder%\%shadow_name%.asc"

REM Problem is black border because of transforming
REM gdalwarp -s_srs EPSG:2056 -t_srs EPSG:4326 -r near "%data_dir%\shadows.tif" "%output_folder%\%shadow_name%_transformed.tif"
REM gdal_translate -of AAIGrid -a_nodata -254 -scale 0 1000 0 253 -ot Int16 "%output_folder%\%shadow_name%_transformed.tif" "%output_folder%\%shadow_name%.asc"


echo Converting done!
set convertedEndime=%time%
call :GetDuration %convertedStartTime% %convertedEndime%
echo Converting and downloading shadow as asc file time: %duration% seconds
echo ------------------------------
echo:


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
	
