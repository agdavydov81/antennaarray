@echo off
for /f "tokens=2" %%G in ('tasklist /NH /FI "imagename eq MATLAB.exe"') do "%~dp0\SetPriority.exe" %%G 1 1>nul
