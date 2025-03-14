@echo off

REM ---Zürich---
REM 3000
REM set bbox="8.526693,47.360906,8.558626,47.379975"
REM set file_name=shadow_ZH_3000

REM 2000
set bbox="8.530263,47.364824,8.547132,47.374609"
set file_name=alti_ZH_2000

REM 1000
REM set bbox="8.539149,47.371556,8.543999,47.373329"
REM set file_name=shadow_ZH_1000

REM Random Hafen für Taras
REM set bbox="8.529181,47.363503,8.545914,47.372378"
REM set file_name=shadow_ZH

REM Random Bereich an Grenze (Grösser als 10000x10000)
REM set bbox="8.410652,47.475967,8.663885,47.630464"
REM set file_name=shadow_ZH

REM 5000
REM set bbox="8.517042,47.356551,8.568996,47.388941"
REM set file_name=alti_ZH_5000

REM 10000
REM set bbox="8.475953,47.344112,8.598270,47.428853"
REM set file_name=shadow_ZH_10000

REM Kanton
REM set bbox="8.357680,47.159445,8.984941,47.694451"
REM set file_name=shadow_kanton_zurich

REM set bbox="8.535543,47.372867,8.553769,47.380680"
REM set file_name=poster_zurich

REM ---Rapperswil---
REM 10000
REM set bbox="8.764465,47.163260,8.886602,47.244968"
REM set file_name=shadow_Rapperswil_10000

REM 1000
REM set bbox="8.815159,47.224125,8.817759,47.225689"
REM set file_name=shadow_Rapperswil_10000

REM Whole switzerland
REM set bbox="5.9559,45.818,10.4921,47.8084"
REM set file_name=alti-switzerland


REM Alti or shadow?
set output_function=shadows

REM horizon?
set with_horizon=false

if /i "%output_function%"=="shadows" (
	call generate_shadows.bat %bbox% %file_name% %with_horizon%
) else (
	call generate_alti.bat %bbox% %file_name%
)

pause
