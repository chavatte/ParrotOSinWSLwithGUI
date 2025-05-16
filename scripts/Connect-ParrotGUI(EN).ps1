# Copyright (c) 2025 João Carlos Chavatte (DEV Chavatte)
#
# This code is part of the Parrot OS Security com GUI no WSL2 project.
# It is licensed under the MIT License.
# See LICENSE file for details.

function Connect-ParrotGUI {
  [CmdletBinding()]
  param (
    [string]$DistroName = "Parrot" 
  )

  Write-Host "Attempting to connect to WSL GUI: ${DistroName}..."

  try {
    Write-Host "Checking/Starting XRDP service in ${DistroName} using 'service' (may prompt for sudo password)..."
    $statusOutput = wsl -d $DistroName -- sudo service xrdp status
    if ($statusOutput -match "is running") {
      Write-Host "XRDP service is already active."
    }
    else {
      Write-Host "XRDP service does not seem to be active. Attempting to start with 'sudo service xrdp start'..."
      wsl -d $DistroName -- sudo service xrdp start
      Start-Sleep -Seconds 3 
      $statusOutputAfterStart = wsl -d $DistroName -- sudo service xrdp status
      if ($statusOutputAfterStart -match "is running") {
        Write-Host "XRDP service started successfully."
      }
      else {
        Write-Warning "Failed to start/confirm XRDP service in ${DistroName} with 'service'. RDP connection might fail. Check manually."
      }
    }
  }
  catch {
    Write-Warning "An error occurred while trying to check/start XRDP service in ${DistroName} with 'service'."
    Write-Warning "Ensure XRDP is installed."
    Write-Warning "You may need to start it manually: wsl -d ${DistroName} -- sudo service xrdp start"
  }

  Write-Host "Getting IP address for ${DistroName}..."
  $ipAddress = $null 
  try {
    $ipOutputLines = wsl -d $DistroName -- ip -4 addr show eth0
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to execute 'ip addr show eth0' in ${DistroName}. Is the distro running and accessible?"
    }
    else {
      foreach ($line in $ipOutputLines) {
        if ($line -match 'inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/') {
          $ipAddress = $matches[1]
          break 
        }
      }
    }
  }
  catch {
    Write-Error "Failed to execute command in WSL to get IP. Error: $($_.Exception.Message)"
    Write-Host "Verify that the '${DistroName}' distribution is running and accessible."
    return 
  }

  if (-not [string]::IsNullOrWhiteSpace($ipAddress)) {
    Write-Host "IP address found for ${DistroName}: ${ipAddress}"
    Write-Host "Starting Remote Desktop Connection to ${ipAddress} (fullscreen)..."
    try {
      Start-Process mstsc.exe -ArgumentList "/v:${ipAddress} /f" -ErrorAction Stop 
    }
    catch {
      Write-Error "Failed to start Remote Desktop Connection (mstsc.exe). Error: $($_.Exception.Message)"
      Write-Host "Verify that mstsc.exe is accessible on your system."
    }
  }
  else {
    Write-Error "Could not get IP address for ${DistroName}."
    Write-Host "Please check the following:"
    Write-Host "1. Is the WSL instance '${DistroName}' running? (Use: wsl -l -v)"
    Write-Host "2. Inside '${DistroName}', is the network (eth0 interface) active and has an IP? (Use: wsl -d ${DistroName} -- ip addr show eth0)"
    Write-Host "3. Inside '${DistroName}', is XRDP installed? Does 'sudo service xrdp start' work manually?"
  }
}