Add-Type -AssemblyName System.Drawing
Add-Type -Path "AForge.Video.dll"
Add-Type -Path "AForge.Video.DirectShow.dll"

$a912 = $false

$a111 = New-Object AForge.Video.DirectShow.FilterInfoCollection([AForge.Video.DirectShow.FilterCategory]::VideoInputDevice)

if ($a111.Count -eq 0) {
    Write-Host "x001"
    return
}

$a222 = New-Object AForge.Video.DirectShow.VideoCaptureDevice($a111[0].MonikerString)

$a333 = {
    if ($script:a912) { return }

    $a555 = $args[1]
    $a666 = $a555.Frame.Clone()

    $a777 = [System.IO.Path]::GetTempPath()
    if (-not (Test-Path $a777)) {
        New-Item -Path $a777 -ItemType Directory | Out-Null
    }

    $a888 = Join-Path $a777 "a999.jpg"
    $a666.Save($a888)
    $script:a912 = $true

    Write-Host "x004: $a888"

    $a666.Dispose()
}

Register-ObjectEvent -InputObject $a222 -EventName "NewFrame" -Action $a333 | Out-Null

$a222.Start()
Write-Host "x002"
Start-Sleep -Seconds 5
$a222.SignalToStop()
$a222.WaitForStop()
Write-Host "x003"
