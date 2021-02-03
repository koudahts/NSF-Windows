echo off
setlocal ENABLEDELAYEDEXPANSION

set DATALINK=https://www.dropbox.com/sh/bua2vks8clnl2ha/AABceXAc2W61d6V_rsBEYpy5a/cmu-arctic-data-set.tar
set FILENAME=cmu-arctic-data-set

if not EXIST "%~dp0\..\DATA\%FILENAME%\" (
   echo DATA DownLoad
   curl -OL %DATALINK%
   if EXIST "cmu-arctic-data-set.tar" (
      tar -xf %FILENAME%.tar
   ) else (
     echo Cannot download %FILENAME%.tar Please contact the author
     exit
   )
) else (
  goto :NSF
)

set Arr[0]=bdl
set Arr[1]=slt
set Arr[2]=clb
set Arr[3]=rms

for /l %%I in (0,1,3) do (
    curl -OL http://festvox.org/cmu_arctic/cmu_arctic/packed/cmu_us_!Arr[%%I]!_arctic-0.95-release.zip
)

Call :UnzipFile

for /l %%I in (0,1,3) do (
   set add=!Arr[%%I]!_
   dir /b /s /a-d %~dp0cmu_us_!Arr[%%I]!_arctic\wav > file.list
   for /f %%J in (file.list) do (
       ren %%J !add!%%~nJ%%~xJ
       move %%~dpJ!Arr[%%I]!_*.wav %~dp0cmu-arctic-data-set\wav_16k
   )
   del /f /q file.list
)

set script_dir=%~dp0
pushd %script_dir%..
set PARENT_PATH=%CD%
popd
echo %~dp0cmu-arctic-data-set %PARENT_PATH%\DATA
move %~dp0cmu-arctic-data-set %PARENT_PATH%\DATA\

rd /s /q cmu_us_bdl_arctic
rd /s /q cmu_us_clb_arctic
rd /s /q cmu_us_rms_arctic
rd /s /q cmu_us_slt_arctic

del /Q cmu_us_bdl_arctic-0.95-release.zip
del /Q cmu_us_clb_arctic-0.95-release.zip
del /Q cmu_us_rms_arctic-0.95-release.zip
del /Q cmu_us_slt_arctic-0.95-release.zip
del /Q cmu-arctic-data-set.tar



:NSF

rem try pre-trained model

set carrent_path=%~dp0
pushd %carrent_path%..\..
set pa_path1=%CD%
popd

set PYTHONPATH=%pa_path1%;%PYTHONPATH%

if EXIST "%~dp0\..\DATA\%FILENAME%\" (
   echo Try pre-trained model
   python main.py --inference --trained-model __pre_trained/trained_network.pt --output-dir __pre_trained/outpu
   echo Please check generated waveforms from pre-trained model in ./__pre_trained/output
 ) else (
   echo Cannot find ..\DATA\%FILENAME%. Please contact the author
)

rem train model

if EXIST "%~dp0\..\DATA\%FILENAME%\" (
   echo Train a new model
   echo Training will take several hours. Please don't quit this job.
   echo Please check log_train and log_err for monitoring the training process.
   python main.py --num-workers 10 > log_train 2>log_err
) else (
   echo Cannot find ..\DATA\%FILENAME%. Please contact the author
)

rem generate using trained model

if EXIST "%~dp0\..\DATA\%FILENAME%\" (
   echo Model is trained
   echo Generate waveform
   python main.py --inference --trained-model trained_network.pt --output-dir output
) else (
   echo Cannot find ..\DATA\%FILENAME%. Please contact the author
)

echo end

exit /b


:UnZipFile

set vbs="_.vbs"

if exist %vbs% del /f /q %vbs%
>>%vbs% echo Option Explicit
>>%vbs% echo dim objShell, objWshShell, objFolder, ZipFile, i
>>%vbs% echo Set objShell = CreateObject("shell.application")
>>%vbs% echo Set objWshShell = WScript.CreateObject("WScript.Shell")
>>%vbs% echo Set ZipFile = objShell.NameSpace (WScript.Arguments(0)).items
>>%vbs% echo Set objFolder = objShell.NameSpace (objWshShell.CurrentDirectory)
>>%vbs% echo objFolder.CopyHere ZipFile,^&H14


for /l %%I in (0,1,3) do (
    cmd /c Cscript.exe %vbs% %~dp0cmu_us_!Arr[%%I]!_arctic-0.95-release.zip
)

del /f /q %vbs%


endlocal
