param(
    [Alias("f")]
    [string]$FilePath,
    [string]$URL,
    [Alias("h", "help", "?")]
    [switch]$Help
)

$DEFAULT_PATH = "%USERPROFILE%\Music\yt-mp3"
$CONFIG_PATH = Join-Path $PSScriptRoot "yt-mp3-config.json"

function Show-Help{
    Write-Host "Usage: ytmp3 [-f folder_path] url"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -f, --folder   Specify the folder to save downloaded MP3 files. If not provided, the default path will be used."
    Write-Host "  -h, --help     Show this help message and exit."
}

if ($Help -or (-not $URL -and -not $FilePath)) {
    Show-Help
    exit 0
}

function Get-SaveDir {
    if (Test-Path -path $CONFIG_PATH) {
        try {
            $config = Get-Content -Path $CONFIG_PATH | ConvertFrom-Json
            if ($config.SAVE_DIR) {
                return [string]$config.SAVE_DIR
            }
        } catch {
            Write-Warning "Warning: Failed to read config file. Using default path."
        }
    }
    return $DEFAULT_PATH
}

function Set-SaveDir([string]$path) {
    @{ SAVE_DIR = $path } | ConvertTo-Json | Set-Content -Path $CONFIG_PATH -Encoding UTF8
}

if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Error "Error: yt-dlp is not installed or not in PATH."
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "Error: ffmpeg is not installed or not in PATH."
    exit 1
}

$SAVE_DIR = if ($Folder) { $Folder } else { Get-SaveDir }
if ($Folder) {
    if (-not (Test-Path -Path $SAVE_DIR)) {
        New-Item -ItemType Directory -Path $SAVE_DIR -Force | Out-Null
    }
    Set-SaveDir -path $SAVE_DIR
    Write-Host "Default save folder updated to: $SAVE_DIR"

    if (-not $URL) {
        Write-Host "No URL provided. Exiting."
        exit 0
    }
}

if (-not $URL) {
    Write-Error "Usage: ytmp3 [-f folder_path] url"
    exit 1
}

if (-not (Test-Path -Path $SAVE_DIR)) {
    New-Item -ItemType Directory -Path $SAVE_DIR -Force | Out-Null
}

write-Host "Downloading audio from $URL..."

yt-dlp -x --audio-format mp3 --audio-quality 0 -o (Join-Path $SAVE_DIR "%(title)s.%(ext)s") $URL

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: yt-dlp failed to download the audio."
    exit 1
}

write-Host "Download completed. Audio saved to $SAVE_DIR."
