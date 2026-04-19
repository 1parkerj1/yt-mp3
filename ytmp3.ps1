param(
    [Parameter(Mandatory=$true)]
    [string]$URL
)

$SAVE_DIR = "C:\Users\parker\Music\sounds\samples\yt-potential"

if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Error "Error: yt-dlp is not installed or not in PATH."
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "Error: ffmpeg is not installed or not in PATH."
    exit 1
}

if (-not (Test-Path -Path $SAVE_DIR)) {
    New-Item -ItemType Directory -Path $SAVE_DIR | Out-Null
}

write-Host "Downloading audio from $URL..."

yt-dlp `
    -x `
    --audio-format mp3 `
    --audio-quality 0 `
    -o "$SAVE_DIR\%(title)s.%(ext)s" `
    $URL

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: yt-dlp failed to download the audio."
    exit 1
}

write-Host "Download completed. Audio saved to $SAVE_DIR."
