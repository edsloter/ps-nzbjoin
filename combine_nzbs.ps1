# Ensure the console output handles special characters cleanly
$OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        True-XML NZB Merger Utility (PowerShell)   " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Ask for input files
Write-Host "Step 1: Input the NZB files you want to combine." -ForegroundColor Yellow
Write-Host "You can type/paste individual file names, paths, or drag-and-drop them."
Write-Host "Separate multiple files with a space."
Write-Host ""
$rawInput = Read-Host "Enter all NZB files"

if ([string]::IsNullOrWhiteSpace($rawInput)) {
    Write-Host "`n[ERROR] No input provided. Exiting." -ForegroundColor Red
    Pause; exit
}

# Regex to accurately parse file paths with spaces by looking for the .nzb extension
$inputFiles = New-Object System.Collections.Generic.List[string]
$matches = [regex]::Matches($rawInput, '(?i)"([^"]+?\.nzb)"|([^\s"]+?\.nzb)|"([^"]+?)"|([^\s"]+)')

$currentPart = ""
foreach ($m in $matches) {
    $token = $m.Value.Trim('"')
    if ([string]::IsNullOrEmpty($token)) { continue }

    if ($currentPart -eq "") {
        $currentPart = $token
    } else {
        $currentPart = "$currentPart $token"
    }

    if ($currentPart -like "*.nzb") {
        $inputFiles.Add($currentPart)
        $currentPart = ""
    }
}

if ($inputFiles.Count -eq 0) {
    Write-Host "`n[ERROR] No valid .nzb files detected. Exiting." -ForegroundColor Red
    Pause; exit
}

# 2. Ask for Output Path and File Name
Write-Host "`n---------------------------------------------------" -ForegroundColor Cyan
Write-Host "Step 2: Define the output combined file." -ForegroundColor Yellow
Write-Host "Provide a folder path and file name (e.g., C:\Downloads\Combined File.nzb)"
Write-Host ""
$outputPath = Read-Host "Enter destination path and file name"
$outputPath = $outputPath.Trim('"')

if ([string]::IsNullOrWhiteSpace($outputPath)) {
    Write-Host "`n[ERROR] No destination path provided. Exiting." -ForegroundColor Red
    Pause; exit
}

# 3. Ask about deleting original files
Write-Host "`n---------------------------------------------------" -ForegroundColor Cyan
Write-Host "Step 3: Cleanup Options" -ForegroundColor Yellow
$deleteConfirm = Read-Host "Would you like to remove the original source files? (Y/N)"

Write-Host "`n---------------------------------------------------" -ForegroundColor Cyan
Write-Host "Processing... Building valid XML structures.`n" -ForegroundColor Green

try {
    # Define your exact 3-line header requirements securely without escaping bugs
    $header = @(
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<nzb xmlns="http://suckit.org">'
    )
    
    # Write initial headers cleanly
    [System.IO.File]::WriteAllLines($outputPath, $header)
    
    # Iterate through all input files and merge payloads safely
    foreach ($p in $inputFiles) {
        if (Test-Path $p) {
            Write-Host "Extracting files from: $(Split-Path $p -Leaf)" -ForegroundColor Gray
            $txt = [System.IO.File]::ReadAllText($p)
            $fileMatches = [regex]::Matches($txt, '(?s)<file\b.*?<\/file>')
            foreach ($m in $fileMatches) {
                [System.IO.File]::AppendAllText($outputPath, $m.Value + [Environment]::NewLine)
            }
        } else {
            Write-Host "[WARNING] File not found, skipping: $p" -ForegroundColor Yellow
        }
    }
    
    # Append final ending root tag
    [System.IO.File]::AppendAllText($outputPath, '</nzb>' + [Environment]::NewLine)
    
    # Optional cleanup of source documents
    if ($deleteConfirm -imatch '^y$|^yes$') {
        Write-Host "`nCleaning up original files..." -ForegroundColor Yellow
        foreach ($p in $inputFiles) {
            if (Test-Path $p) {
                Remove-Item -Path $p -Force
                Write-Host "Deleted: $(Split-Path $p -Leaf)" -ForegroundColor Gray
            }
        }
    }

    Write-Host "`n[SUCCESS] Compliant NZB file built with singular global root tags!" -ForegroundColor Green
}
catch {
    Write-Host "`n[ERROR] Script failed to generate file: $_" -ForegroundColor Red
}

Write-Host ""
Pause
