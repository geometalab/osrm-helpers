@echo off

set url=%1

r.import input=%url% output=surface --overwrite

pause

