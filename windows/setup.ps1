<#PSScriptInfo
.VERSION 1.0
.AUTHOR martshaw
.COPYRIGHT 2020
.TAGS Windows, Web Development,
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES Installs Chocolatey, Node, Gitr.
#>

<#

.DESCRIPTION
 Setup a web development environment with Git, Node and VS Code heavily influenced by https://github.com/duluca/web-dev-environment-setup/blob/master/setup-windows-dev-env.ps1
#>
Param()

# This script is intentionally kept simple to demonstrate basic automation techniques.

Write-Output "You must run this script in an elevated command shell, using 'Run as Administator'"

$title = "Setup Web Development Environment"
$message = "Select the appropriate option to continue (Absolutely NO WARRANTIES or GUARANTEES are provided):"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Install Software using Chocolatey", `
  "Setup development environment."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", `
  "Do not execute script."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result) {
  0 {
    Write-Output "Installing chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Output "Refreshing environment variables. If rest of the script fails, restart elevated shell and rerun script."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Output "Assuming chocolatey is already installed"
    Write-Output "Installing Git & GitHub Desktop"
    choco.exe upgrade git -y

    Write-Output "Installing NodeJS and NVS"
    choco.exe upgrade nodejs-lts nvs -y

    Write-Output "Installing Docker"
    choco.exe upgrade docker-cli docker-for-windows -y

    Write-Output "Installing VS Code"
    choco.exe upgrade VisualStudioCode -y

    Write-Output "Installing Spotify"
    choco.exe upgrade spotify -y

    RefreshEnv.cmd
    Write-Output "Results:"
    Write-Output "Verify installation of GitHub Desktop and VS Code manually."
    $dockerVersion = docker.exe --version
    Write-Output "docker: $dockerVersion"
    $gitVersion = git.exe --version
    Write-Output "git: $gitVersion"
    $nodeVersion = node.exe -v
    Write-Output "Node: $nodeVersion"
    $npmVersion = npm.cmd -v
    Write-Output "npm: $npmVersion"

  }
  1 { "Aborted." }
}
