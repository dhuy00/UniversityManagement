#Requires -Version 5.1
<#
.SYNOPSIS
    Logical backup of the university PostgreSQL database via pg_dump.

.DESCRIPTION
    Produces a compressed, consistent snapshot of the university database
    using pg_dump.  Designed to be run from CI or by an operator on the
    host that has the docker CLI installed.

    Output files are written to ./backups/<timestamp>/.  The script
    keeps the latest 7 snapshots by default (older directories are
    pruned).

.PARAMETER Container
    Name of the PostgreSQL container. Defaults to 'university-postgres'.

.PARAMETER Database
    Name of the database. Defaults to 'university_management'.

.PARAMETER User
    PostgreSQL user used by pg_dump.  Defaults to 'postgres'.

.PARAMETER KeepLast
    Number of recent backups to retain.  Defaults to 7.

.PARAMETER OutDir
    Destination directory.  Defaults to ./backups relative to the script
    location.

.EXAMPLE
    .\backup.ps1
    .\backup.ps1 -KeepLast 14
#>

[CmdletBinding()]
param(
    [string]$Container = 'university-postgres',
    [string]$Database = 'university_management',
    [string]$User = 'postgres',
    [int]$KeepLast = 7,
    [string]$OutDir = "$PSScriptRoot/../../backups"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker is required on PATH."
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$destDir = Join-Path $OutDir $timestamp
New-Item -ItemType Directory -Path $destDir -Force | Out-Null

$env:PGPASSWORD = $env:POSTGRES_PASSWORD
if (-not $env:PGPASSWORD) {
    $env:PGPASSWORD = '123'
}

Write-Host "Backing up $Database@$Container to $destDir"

docker exec -e PGPASSWORD=$env:PGPASSWORD $Container pg_dump `
    -U $User `
    -d $Database `
    --format=custom `
    --no-owner `
    --no-privileges `
    --compress=9 `
    | Set-Content -Encoding ascii -Path "$destDir/backup.dump"

if ($LASTEXITCODE -ne 0) {
    throw "pg_dump failed with exit code $LASTEXITCODE"
}

Get-ChildItem -Path $OutDir -Directory |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -Skip $KeepLast |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

Write-Host "Backup complete: $destDir"
