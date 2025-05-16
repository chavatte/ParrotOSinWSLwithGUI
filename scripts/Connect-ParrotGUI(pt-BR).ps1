# Copyright (c) 2025 João Carlos Chavatte (DEV Chavatte)
#
# This code is part of the Parrot OS Security com GUI no WSL2 project.
# It is licensed under the MIT License.
# See LICENSE file for details.

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Connect-ParrotGUI {
  [CmdletBinding()]
  param (
    [string]$DistroName = "Parrot" 
  )

  Write-Host "Tentando conectar à GUI do WSL: ${DistroName}..."

  try {
    Write-Host "Verificando/Iniciando serviço XRDP em ${DistroName} usando 'service' (pode pedir senha sudo)..."
    $statusOutput = wsl -d $DistroName -- sudo service xrdp status
    if ($statusOutput -match "is running") {
      Write-Host "Serviço XRDP já está ativo."
    }
    else {
      Write-Host "Serviço XRDP não parece estar ativo. Tentando iniciar com 'sudo service xrdp start'..."
      wsl -d $DistroName -- sudo service xrdp start
      Start-Sleep -Seconds 3 
      $statusOutputAfterStart = wsl -d $DistroName -- sudo service xrdp status
      if ($statusOutputAfterStart -match "is running") {
        Write-Host "Serviço XRDP iniciado com sucesso."
      }
      else {
        Write-Warning "Falha ao iniciar/confirmar o serviço XRDP em ${DistroName} com 'service'. A conexão RDP pode falhar. Verifique manualmente."
      }
    }
  }
  catch {
    Write-Warning "Ocorreu um erro ao tentar verificar/iniciar o serviço XRDP em ${DistroName} com 'service'."
    Write-Warning "Certifique-se de que o XRDP está instalado."
    Write-Warning "Você pode precisar iniciá-lo manualmente: wsl -d ${DistroName} -- sudo service xrdp start"
  }

  Write-Host "Obtendo endereço IP para ${DistroName}..."
  $ipAddress = $null 
  try {
    $ipOutputLines = wsl -d $DistroName -- ip -4 addr show eth0
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Falha ao executar 'ip addr show eth0' em ${DistroName}. A distro está rodando e acessível?"
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
    Write-Error "Falha ao executar comando no WSL para obter IP. Erro: $($_.Exception.Message)"
    Write-Host "Verifique se a distribuição '${DistroName}' está em execução e acessível."
    return 
  }

  if (-not [string]::IsNullOrWhiteSpace($ipAddress)) {
    Write-Host "Endereço IP encontrado para ${DistroName}: ${ipAddress}"
    Write-Host "Iniciando Conexão de Área de Trabalho Remota para ${ipAddress} (tela cheia)..."
    try {
      Start-Process mstsc.exe -ArgumentList "/v:${ipAddress} /f" -ErrorAction Stop 
    }
    catch {
      Write-Error "Falha ao iniciar a Conexão de Área de Trabalho Remota (mstsc.exe). Erro: $($_.Exception.Message)"
      Write-Host "Verifique se o mstsc.exe está acessível no seu sistema."
    }
  }
  else {
    Write-Error "Não foi possível obter o endereço IP para ${DistroName}."
    Write-Host "Verifique os seguintes pontos:"
    Write-Host "1. A instância WSL '${DistroName}' está em execução? (Use: wsl -l -v)"
    Write-Host "2. Dentro do '${DistroName}', a rede (interface eth0) está ativa e com IP? (Use: wsl -d ${DistroName} -- ip addr show eth0)"
    Write-Host "3. Dentro do '${DistroName}', o XRDP está instalado? O comando 'sudo service xrdp start' funciona manualmente?"
  }
}