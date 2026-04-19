param(
    [Parameter()]
    [Alias("f")]
    [string]$Folder,

    [Parameter(Position = 0)]
    [string]$URL,

    [Alias("h","?")]
    [switch]$Help
)

$DEFAULT_PATH = Join-Path $env:USERPROFILE "Music\yt-mp3"
$CONFIG_DIR   = Join-Path $env:APPDATA "yt-mp3"
$CONFIG_PATH  = Join-Path $CONFIG_DIR "config.json"

function Show-Help {
    Write-Host ""
    Write-Host "  yt-mp3 -f `"C:\Path\To\Folder`" (Set default save folder)"
    Write-Host ""
    Write-Host "  yt-mp3 `"https://youtube.com/...`" (Download audio from YouTube video)"
    Write-Host ""
    Write-Host "  If no folder has been set yet, the default will be:"
    Write-Host "  $DEFAULT_PATH"
    Write-Host ""
}

function Ensure-ConfigDir {
    if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
    }
}

function Get-SaveDir {
    if (Test-Path $CONFIG_PATH) {
        try {
            $config = Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json
            if ($config.SaveDir -and $config.SaveDir.Trim() -ne "") {
                if (Test-IsUrl $config.SaveDir) {
                    Write-Warning "Config save folder is invalid (URL). Resetting to default: $DEFAULT_PATH"
                } else {
                    return $config.SaveDir
                }
            }
        }
        catch {
            Write-Warning "Could not read config. Falling back to default folder."
        }
    }

    if (-not (Test-Path $DEFAULT_PATH)) {
        New-Item -ItemType Directory -Path $DEFAULT_PATH -Force | Out-Null
    }

    Set-SaveDir $DEFAULT_PATH
    return $DEFAULT_PATH
}

function Set-SaveDir([string]$Path) {
    Ensure-ConfigDir

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error "Save folder cannot be empty."
        exit 1
    }

    if (Test-IsUrl $Path) {
        Write-Error "Invalid save folder: '$Path' looks like a URL. Use -f with a local folder path."
        exit 1
    }

    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Write-Error "Could not create/access save folder '$Path'. $($_.Exception.Message)"
        exit 1
    }

    @{ SaveDir = $Path } | ConvertTo-Json | Set-Content -Path $CONFIG_PATH -Encoding UTF8
}

function Test-Dependency([string]$CommandName) {
    return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Test-IsUrl([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    return $Value -match '^[a-zA-Z][a-zA-Z0-9+\-.]*://'
}

if ($Help -or (-not $Folder -and -not $URL)) {
    Show-Help
    exit 0
}

if (-not (Test-Dependency "yt-dlp")) {
    Write-Error "yt-dlp is not installed or not in PATH."
    exit 1
}

if (-not (Test-Dependency "ffmpeg")) {
    Write-Error "ffmpeg is not installed or not in PATH."
    exit 1
}

if ($Folder) {
    Set-SaveDir $Folder
    Write-Host "Default save folder set to: $Folder"
    exit 0
}

if ($URL) {
    $SaveDir = Get-SaveDir

    if (Test-IsUrl $SaveDir) {
        Write-Error "Saved folder is invalid ('$SaveDir'). Run: yt-mp3 -f ""C:\Path\To\Folder"""
        exit 1
    }

    Write-Host "Downloading audio from $URL..."

    yt-dlp --quiet --no-warnings --no-progress `
        -x --audio-format mp3 --audio-quality 0 `
        -o (Join-Path $SaveDir "%(title)s.%(ext)s") `
        $URL

    if ($LASTEXITCODE -ne 0) {
        Write-Error "yt-dlp failed to download the audio."
        exit 1
    }

    Write-Host "Download completed. Audio saved to $SaveDir."
    exit 0
}