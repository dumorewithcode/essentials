#Requires -Version 5

<#
.SYNOPSIS
    Script to install windows apps
.DESCRIPTION
    The intent of this script is to help install many apps after a reformat 
    instead of doing it manually using the Windows Package Manager(winget)
.PARAMETER FilePath
    Path to where you saved your list of app ids
.EXAMPLE
    PS C:\Scripts> .\essentials.ps1 -FilePath C:\Scripts\{FILENAME}.txt
.NOTES
    Author: @a3kSec
.LINK
    https://github.com/a3kSec/essentials.ps1
#>

param(
        [Parameter(Mandatory = $true)][string]$FilePath
    )

function WindowsNeedsToUpdate () {
    $current_live_build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber -as [int]
    $current_installed_build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild -as [int]
    if($current_live_build -gt $current_installed_build){
        $true
    }
}

function UpdateWindows () {
    try{    
        Install-Module PSWindowsUpdate -Scope CurrentUser
        Import-Module PSWindowsUpdate
        Get-WindowsUpdate
    }
    catch{
        Write-Host "Could not update windows. Something went wrong." -ForegroundColor Red
    }
}

function InstallWinget ($url, $outfile) {
    try{
        $net = New-Object System.Net.WebClient
        Write-Host "Downloading winget" -ForegroundColor Yellow
        $net.DownloadFile($url,$outfile)
        Write-Host "Installing winget" -ForegroundColor Yellow
        Add-AppxPackage $outfile
        Write-Host "winget installed. Rerun script to install apps that you specified in your preferred app_id file." -ForegroundColor Green
        Remove-Item -Path $outfile
    }
    catch{
        Write-Host "Error downloading file. Rerun script." -ForegroundColor Red
        exit 1
    }
}

function SanitizeAppID ($string) {
    $sanitized = $string -replace '[^a-zA-Z0-9\.]',''
    $sanitized.Trim("."," ")
}

function InstallApps ($filepath) {
    if ([System.IO.File]::Exists($filepath)) {
        foreach ($line in [System.IO.File]::ReadLines($filepath)) {
            $str = SanitizeAppID $line
            winget.exe install --id=$str -e
        }
    }
    else {
        Write-Host "No such file path." -ForegroundColor Red
    }
}

if (WindowsNeedsToUpdate) {
    $question = Read-Host "Windows is not the latest version, would you like to update?(yes/no)"

    $answer = switch ($question) {
        'yes'   { $true }
        'y'   { $true }
        'no'    { $false }
        'n'    { $false }
        default {Write-Host 'Not updating windows.' -ForegroundColor Red}
    }
    if ($answer) {
        UpdateWindows
    }
}

if (Get-Command winget.exe) {
    InstallApps $FilePath
}
else
{
    $url = "https://github.com/microsoft/winget-cli/releases/download/v0.2.2941-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
    $outfile = "$PSScriptRoot/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
    $question = Read-Host "winget is required, would you like to install?(yes/no)"
    
    $answer = switch ($question) {
        'yes'   { $true }
        'y'   { $true }
        'no'    { $false }
        'n'    { $false }
        default {Write-Host 'winget is required to continue.' -ForegroundColor Red}
    }
    
    if ($answer) {
        InstallWinget $url $outfile
    }
}