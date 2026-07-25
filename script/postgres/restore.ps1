#Requires -Version 5.1
<#
.SYNOPSIS
    Restore a logical backup produced by backup.ps1.

.DESCRIPTION
    Drops and re-creates the target database, then loads the dump
    using pg_restore.  The script refuses to run unless -Force is
    passed because the operation is destructive.

.PARAMETER BackupPath
    Path to the backup.dump file (or the directory containing one).

.PARAMETER Container
    Name of the PostgreSQL container. Defaults to 'university-postgres'.

.PARAMETER Database
    Name of the database to restore into.  Defaults to
    'university_management'.

.PARAMETER User
    PostgreSQL user used by pg_restore.  Defaults to 'postgres'.

.EXAMPLE
    .\restore.ps1 -BackupPath ./backups/20260725-120000/backup.dump
    .\restore.ps1 -BackupPath ./backups/20260725-120000 -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupPath,
    [string]$Container = 'university-postgres',
    [string]$Database = 'university_management',
    [string]$User = 'postgres',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker is required on PATH."
}

if ((Test-Path -PathType Container $BackupPath)) {
    $BackupPath = Join-Path $BackupPath 'backup.dump'
}

if (-not (Test-Path $BackupPath)) {
    throw "Backup file not found: $BackupPath"
}

if (-not $Force) {
    throw "Refusing to restore without -Force. This will DROP the database."
}

$env:PGPASSWORD = $env:POSTGRES_PASSWORD
if (-not $env:PGPASSWORD) {
    $env:PGPASSWORD = '123'
}

Write-Host "Restoring $BackupPath to $Database@$Container"

docker exec -e PGPASSWORD=$env:PGPASSWORD $Container psql `
    -U $User `
    -d postgres `
    -c "DROP DATABASE IF EXISTS $Database;"

docker exec -e PGPASSWORD=$env:PGPASSWORD $Container psql `
    -U $User `
    -d postgres `
    -c "CREATE DATABASE $Database;"

Get-Content -Raw $BackupPath | docker exec -i -e PGPASSWORD=$env:PGPASSWORD $Container pg_restore `
    -U $User `
    -d $Database `
    --no-owner `
    --no-privileges `
    --clean=false `
    --if-exists=false

if ($LASTEXITCODE -ne 0) {
    throw "pg_restore failed with exit code $LASTEXITCODE"
}

Write-Host "Restore complete"
