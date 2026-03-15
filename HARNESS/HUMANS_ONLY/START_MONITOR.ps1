# Start the Harness HUMANS_ONLY frontend: run the local server and open the page in the default browser.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HarnessDir = Split-Path -Parent $ScriptDir
$ServeScript = Join-Path $ScriptDir "serve.py"

$Port = 8765
$Url = "http://localhost:$Port/HUMANS_ONLY/"

Start-Process python -ArgumentList $ServeScript -WorkingDirectory $HarnessDir
Start-Sleep -Seconds 1
Start-Process $Url
