#Requires -Version 5.1
# Starling bootstrap installer
# No prerequisites needed - downloads Python 3.12 and everything else automatically.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$INSTALL_DIR  = Join-Path $env:LOCALAPPDATA "Starling"
$REPO_ZIP_URL = "https://github.com/famousdrew/starling-voice-dictation/archive/refs/heads/main.zip"
$PYTHON_URL   = "https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"
$PYTHON_VER   = "3.12"

# ── Colours ───────────────────────────────────────────────────────────────────
$C_BG     = [System.Drawing.Color]::FromArgb(15,  15,  16)
$C_CARD   = [System.Drawing.Color]::FromArgb(26,  26,  30)
$C_ACCENT = [System.Drawing.Color]::FromArgb(74,  222, 128)
$C_ADIM   = [System.Drawing.Color]::FromArgb(22,  101, 52)
$C_TEXT   = [System.Drawing.Color]::FromArgb(240, 240, 240)
$C_DIM    = [System.Drawing.Color]::FromArgb(136, 136, 136)
$C_RED    = [System.Drawing.Color]::FromArgb(248, 113, 113)
$C_LOG    = [System.Drawing.Color]::FromArgb(12,  12,  14)

# ── Detect existing install ───────────────────────────────────────────────────
$existingInstall = Test-Path (Join-Path $INSTALL_DIR ".venv\Scripts\python.exe")

# ── Form ──────────────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Starling Setup"
$form.ClientSize      = New-Object System.Drawing.Size(500, 462)
$form.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox     = $false
$form.BackColor       = $C_BG
$form.ForeColor       = $C_TEXT
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)

# Try to load icon from an existing install; silently skip if not present yet
$iconPng = Join-Path $INSTALL_DIR "starling\assets\icon.png"
if (Test-Path $iconPng) {
    try {
        $bmp = New-Object System.Drawing.Bitmap($iconPng)
        $form.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    } catch {}
}

# ── Header ────────────────────────────────────────────────────────────────────
$header           = New-Object System.Windows.Forms.Panel
$header.Dock      = [System.Windows.Forms.DockStyle]::Top
$header.Height    = 78
$header.BackColor = $C_CARD

$pic           = New-Object System.Windows.Forms.PictureBox
$pic.Size      = New-Object System.Drawing.Size(52, 52)
$pic.Location  = New-Object System.Drawing.Point(20, 13)
$pic.SizeMode  = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$pic.BackColor = $C_CARD
if (Test-Path $iconPng) {
    try { $pic.Image = [System.Drawing.Image]::FromFile($iconPng) } catch {}
}
$header.Controls.Add($pic)

$lblTitle           = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "Starling"
$lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $C_TEXT
$lblTitle.Location  = New-Object System.Drawing.Point(82, 10)
$lblTitle.AutoSize  = $true
$header.Controls.Add($lblTitle)

$lblSub           = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Offline voice dictation for Windows"
$lblSub.ForeColor = $C_DIM
$lblSub.Location  = New-Object System.Drawing.Point(84, 46)
$lblSub.AutoSize  = $true
$header.Controls.Add($lblSub)

$form.Controls.Add($header)

# ── Status label ──────────────────────────────────────────────────────────────
$lblStatus           = New-Object System.Windows.Forms.Label
$lblStatus.Location  = New-Object System.Drawing.Point(20, 90)
$lblStatus.Size      = New-Object System.Drawing.Size(460, 20)
if ($existingInstall) {
    $lblStatus.Text      = "Existing installation found.  Click Update to apply any changes."
    $lblStatus.ForeColor = $C_ACCENT
} else {
    $lblStatus.Text      = "Click Install to begin.  (~4 GB download on first run.)"
    $lblStatus.ForeColor = $C_DIM
}
$form.Controls.Add($lblStatus)

# ── Progress bar ──────────────────────────────────────────────────────────────
$progress          = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 116)
$progress.Size     = New-Object System.Drawing.Size(460, 16)
$progress.Minimum  = 0
$progress.Maximum  = 100
$progress.Style    = [System.Windows.Forms.ProgressBarStyle]::Continuous
$form.Controls.Add($progress)

# ── Clean reinstall checkbox ──────────────────────────────────────────────────
$chkClean           = New-Object System.Windows.Forms.CheckBox
$chkClean.Text      = "Clean reinstall  (removes existing installation and re-downloads everything)"
$chkClean.ForeColor = $C_DIM
$chkClean.BackColor = $C_BG
$chkClean.Location  = New-Object System.Drawing.Point(20, 140)
$chkClean.Size      = New-Object System.Drawing.Size(460, 22)
$chkClean.Visible   = $existingInstall
$form.Controls.Add($chkClean)

# ── Log box ───────────────────────────────────────────────────────────────────
$log             = New-Object System.Windows.Forms.RichTextBox
$log.Location    = New-Object System.Drawing.Point(20, 170)
$log.Size        = New-Object System.Drawing.Size(460, 216)
$log.BackColor   = $C_LOG
$log.ForeColor   = $C_DIM
$log.Font        = New-Object System.Drawing.Font("Consolas", 8.5)
$log.ReadOnly    = $true
$log.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$log.ScrollBars  = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$form.Controls.Add($log)

# ── Button ────────────────────────────────────────────────────────────────────
$btn           = New-Object System.Windows.Forms.Button
$btn.Text      = if ($existingInstall) { "Update" } else { "Install" }
$btn.Location  = New-Object System.Drawing.Point(20, 402)
$btn.Size      = New-Object System.Drawing.Size(460, 42)
$btn.BackColor = $C_ADIM
$btn.ForeColor = $C_ACCENT
$btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btn.FlatAppearance.BorderSize = 0
$btn.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btn)

# ── Model choice panel (shown when no GPU is detected) ────────────────────────
$choicePanel           = New-Object System.Windows.Forms.Panel
$choicePanel.Location  = $log.Location
$choicePanel.Size      = $log.Size
$choicePanel.BackColor = $C_BG
$choicePanel.Visible   = $false
$form.Controls.Add($choicePanel)

$cpTitle           = New-Object System.Windows.Forms.Label
$cpTitle.Text      = "No NVIDIA GPU detected."
$cpTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$cpTitle.ForeColor = $C_TEXT
$cpTitle.Location  = New-Object System.Drawing.Point(0, 0)
$cpTitle.Size      = New-Object System.Drawing.Size(460, 24)
$choicePanel.Controls.Add($cpTitle)

$cpSub           = New-Object System.Windows.Forms.Label
$cpSub.Text      = "Choose your transcription model. You can change this later in Settings."
$cpSub.ForeColor = $C_DIM
$cpSub.Location  = New-Object System.Drawing.Point(0, 28)
$cpSub.Size      = New-Object System.Drawing.Size(460, 18)
$choicePanel.Controls.Add($cpSub)

$cpBtn1           = New-Object System.Windows.Forms.Button
$cpBtn1.Text      = "Fast  --  Whisper small  (~500 MB)`r`nNear real-time on modern CPUs. Good accuracy."
$cpBtn1.Location  = New-Object System.Drawing.Point(0, 56)
$cpBtn1.Size      = New-Object System.Drawing.Size(460, 60)
$cpBtn1.BackColor = $C_ADIM
$cpBtn1.ForeColor = $C_ACCENT
$cpBtn1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cpBtn1.FlatAppearance.BorderSize = 0
$cpBtn1.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$cpBtn1.Cursor    = [System.Windows.Forms.Cursors]::Hand
$choicePanel.Controls.Add($cpBtn1)

$cpBtn2           = New-Object System.Windows.Forms.Button
$cpBtn2.Text      = "Accurate  --  Whisper medium  (~1.5 GB)`r`nBetter accuracy, roughly 2x slower."
$cpBtn2.Location  = New-Object System.Drawing.Point(0, 128)
$cpBtn2.Size      = New-Object System.Drawing.Size(460, 60)
$cpBtn2.BackColor = [System.Drawing.Color]::FromArgb(22, 52, 101)
$cpBtn2.ForeColor = [System.Drawing.Color]::FromArgb(96, 165, 250)
$cpBtn2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cpBtn2.FlatAppearance.BorderSize = 0
$cpBtn2.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$cpBtn2.Cursor    = [System.Windows.Forms.Cursors]::Hand
$choicePanel.Controls.Add($cpBtn2)

# ── Shared state ──────────────────────────────────────────────────────────────
$sync = [hashtable]::Synchronized(@{
    Pct             = 0
    Status          = ""
    LogLine         = ""
    Marquee         = $false
    Done            = $false
    Success         = $false
    Error           = ""
    CleanInstall    = $false
    NeedModelChoice = $false
    ModelChoice     = ""
})

# ── Install work ──────────────────────────────────────────────────────────────
$installWork = {
    param([hashtable]$s, [string]$installDir, [string]$repoZipUrl, [string]$pythonUrl, [string]$pythonVer)

    function Step([string]$msg, [int]$pct) {
        $s.Pct = $pct; $s.Status = $msg; $s.LogLine = $msg
    }
    function Log([string]$msg) { if ($msg.Trim()) { $s.LogLine = $msg.Trim() } }

    function TryPython([string]$exe, [string[]]$extraArgs) {
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName  = $exe
            $allArgs       = $extraArgs + @("-c", "import sys; print(str(sys.version_info.major)+'.'+str(sys.version_info.minor))")
            $psi.Arguments = ($allArgs | ForEach-Object { "`"$_`"" }) -join ' '
            $psi.UseShellExecute        = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.CreateNoWindow         = $true
            $proc = [System.Diagnostics.Process]::Start($psi)
            if ($null -eq $proc) { return $null }
            if ($proc.WaitForExit(4000)) { return $proc.StandardOutput.ReadToEnd().Trim() }
            try { $proc.Kill() } catch {}
            return $null
        } catch { return $null }
    }

    function FindPython312 {
        # Check PATH candidates
        foreach ($cand in @("py", "python3.12", "python3", "python")) {
            $xtra = if ($cand -eq "py") { @("-3.12") } else { @() }
            if ((TryPython $cand $xtra) -eq $pythonVer) { return @{ Cli = $cand; Extra = $xtra } }
        }
        # Check known per-user install locations
        $knownPaths = @(
            "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python3.12\python.exe"
        )
        foreach ($p in $knownPaths) {
            if ((Test-Path $p) -and ((TryPython $p @()) -eq $pythonVer)) {
                return @{ Cli = $p; Extra = @() }
            }
        }
        return $null
    }

    try {
        # ── 1. Python 3.12 ────────────────────────────────────────────────────
        Step "Checking for Python 3.12..." 2
        $py = FindPython312

        if (-not $py) {
            # Try winget first (silent, no UAC needed)
            Step "Python 3.12 not found.  Installing via winget..." 4
            $wg = Get-Command winget -ErrorAction SilentlyContinue
            if ($wg) {
                & winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                # Reload PATH so newly installed python is visible
                $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                            [System.Environment]::GetEnvironmentVariable("PATH","User")
                $py = FindPython312
            }
        }

        if (-not $py) {
            # Fall back to direct download from python.org
            Step "Downloading Python 3.12 installer (~25 MB)..." 6
            $s.Marquee = $true
            $pyExe = Join-Path $env:TEMP "python-3.12-amd64.exe"
            (New-Object System.Net.WebClient).DownloadFile($pythonUrl, $pyExe)
            $s.Marquee = $false
            Step "Installing Python 3.12..." 10
            Start-Process $pyExe -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1" -Wait
            Remove-Item $pyExe -ErrorAction SilentlyContinue
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH","User")
            $py = FindPython312
        }

        if (-not $py) {
            $s.Error = "Could not install Python 3.12.  Please install it manually from python.org/downloads"
            $s.Done = $true; return
        }
        Log "Python 3.12 ready  ($($py.Cli))"

        $pyCli   = $py.Cli
        $pyExtra = $py.Extra

        # ── 2. Clean reinstall - wipe venv if requested ───────────────────────
        $venv   = Join-Path $installDir ".venv"
        $pip    = Join-Path $venv "Scripts\pip.exe"
        $python = Join-Path $venv "Scripts\python.exe"

        if ($s.CleanInstall -and (Test-Path $venv)) {
            Step "Removing existing installation..." 12
            Remove-Item $venv -Recurse -Force
            Log "Existing installation removed."
        }

        # ── 3. Download + extract repo ────────────────────────────────────────
        Step "Downloading Starling..." 14
        $s.Marquee = $true
        $zipPath     = Join-Path $env:TEMP "starling.zip"
        $extractPath = Join-Path $env:TEMP "starling_extract"
        (New-Object System.Net.WebClient).DownloadFile($repoZipUrl, $zipPath)
        $s.Marquee = $false
        Log "Download complete."

        Step "Extracting files..." 18
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue

        # GitHub zip extracts to e.g. "starling-main\" -- find that folder
        $extracted = Get-ChildItem $extractPath -Directory | Select-Object -First 1
        if (-not $extracted) { $s.Error = "Failed to extract downloaded files."; $s.Done = $true; return }

        # Copy source files to install dir, preserving .venv across updates
        if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
        foreach ($item in (Get-ChildItem $extracted.FullName)) {
            if ($item.Name -ne ".venv") {
                Copy-Item $item.FullName (Join-Path $installDir $item.Name) -Recurse -Force
            }
        }
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Log "Files installed to $installDir"

        # ── 4. Virtual environment ────────────────────────────────────────────
        Step "Creating virtual environment..." 22
        if (-not (Test-Path $venv)) {
            & $pyCli @pyExtra -m venv $venv 2>&1 | ForEach-Object { Log $_ }
            if ($LASTEXITCODE -ne 0) { $s.Error = "Failed to create virtual environment."; $s.Done = $true; return }
            Log "Virtual environment created."
        } else {
            Log "Virtual environment already exists, skipping."
        }

        # ── 5. pip + numpy ────────────────────────────────────────────────────
        Step "Upgrading pip..." 26
        & $pip install --quiet --upgrade pip 2>&1 | Out-Null
        Step "Installing numpy..." 28
        & $pip install --quiet "numpy>=2.0" 2>&1 | Out-Null
        Log "numpy ready."

        # ── 6. PyTorch (large download) ───────────────────────────────────────
        Step "Installing PyTorch with CUDA (downloading ~2.5 GB, please wait)..." 30
        $s.Marquee = $true
        & $pip install --quiet torch torchaudio --index-url https://download.pytorch.org/whl/cu128 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Log "cu128 unavailable, trying cu126..."
            & $pip install --quiet torch torchaudio --index-url https://download.pytorch.org/whl/cu126 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                $s.Marquee = $false
                $s.Error = "PyTorch install failed.  Check your internet connection."
                $s.Done = $true; return
            }
        }
        $s.Marquee = $false
        $cudaOk = & $python -c "import torch; print(torch.cuda.is_available())" 2>$null
        if ($cudaOk -eq "True") {
            $gpu = & $python -c "import torch; print(torch.cuda.get_device_name(0))" 2>$null
            Log "PyTorch ready.  GPU: $gpu"
        } else {
            Log "No NVIDIA GPU detected.  Waiting for model selection..."
            $s.NeedModelChoice = $true
            while ($s.ModelChoice -eq "") { Start-Sleep -Milliseconds 200 }
            $corrDir = Join-Path $env:APPDATA "Starling"
            if (-not (Test-Path $corrDir)) { New-Item -ItemType Directory -Path $corrDir | Out-Null }
            $cfg = "{`"backend`": `"whisper`", `"whisper_model`": `"$($s.ModelChoice)`"}"
            $cfg | Out-File (Join-Path $corrDir "config.json") -Encoding utf8
            Log "Model set to Whisper $($s.ModelChoice)."
        }
        Step "PyTorch ready." 62

        # ── 7. Starling + NeMo (large download) ───────────────────────────────
        Step "Installing Starling and NeMo toolkit (downloading ~1 GB, please wait)..." 65
        $s.Marquee = $true
        & $pip install --quiet -e $installDir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $s.Marquee = $false
            $s.Error = "pip install failed."
            $s.Done = $true; return
        }
        $s.Marquee = $false
        Log "Starling and NeMo ready."
        Step "Dependencies ready." 88

        # ── 8. Corrections dictionary ─────────────────────────────────────────
        Step "Installing corrections dictionary..." 90
        $corrDir = Join-Path $env:APPDATA "Starling"
        if (-not (Test-Path $corrDir)) { New-Item -ItemType Directory -Path $corrDir | Out-Null }
        $src  = Join-Path $installDir "corrections.json"
        $dest = Join-Path $corrDir "corrections.json"
        if (-not (Test-Path $dest)) { Copy-Item $src $dest; Log "corrections.json installed." }
        else { Log "corrections.json already present, skipping." }

        # ── 9. App icon ───────────────────────────────────────────────────────
        Step "Generating icon..." 93
        & $python -c "from starling.assets import app_icon_ico_path; app_icon_ico_path()" 2>&1 | Out-Null
        Log "Icon generated."

        # ── 10. Shortcuts ─────────────────────────────────────────────────────
        Step "Creating shortcuts..." 96
        $launcherPath = Join-Path $installDir "launch.vbs"
        $runPs1       = Join-Path $installDir "run.ps1"
        $vbsContent   = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & "$runPs1" & """", 0, False
"@
        $vbsContent | Out-File -FilePath $launcherPath -Encoding ascii

        $icoPath = Join-Path $installDir "starling\assets\icon.ico"
        $wsh = New-Object -ComObject WScript.Shell

        $desk = [System.Environment]::GetFolderPath("Desktop")
        $lnk = $wsh.CreateShortcut((Join-Path $desk "Starling.lnk"))
        $lnk.TargetPath = "wscript.exe"; $lnk.Arguments = "`"$launcherPath`""
        $lnk.WorkingDirectory = $installDir; $lnk.IconLocation = $icoPath
        $lnk.Description = "Starling voice dictation"; $lnk.Save()

        $sMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
        $lnk2 = $wsh.CreateShortcut((Join-Path $sMenu "Starling.lnk"))
        $lnk2.TargetPath = "wscript.exe"; $lnk2.Arguments = "`"$launcherPath`""
        $lnk2.WorkingDirectory = $installDir; $lnk2.IconLocation = $icoPath
        $lnk2.Description = "Starling voice dictation"; $lnk2.Save()

        Log "Shortcuts created on Desktop and Start Menu."
        Step "Done!" 100
        $s.Success = $true

    } catch {
        $s.Error = $_.Exception.Message
    } finally {
        $s.Done = $true
    }
}

# ── Poll timer ────────────────────────────────────────────────────────────────
$timer          = New-Object System.Windows.Forms.Timer
$timer.Interval = 120

$timer.Add_Tick({
    if ($sync.LogLine -ne "") {
        $log.SelectionStart  = $log.TextLength
        $log.SelectionLength = 0
        $log.SelectedText    = "$($sync.LogLine)`n"
        $log.ScrollToCaret()
        $sync.LogLine = ""
    }
    if ($sync.Marquee -and $progress.Style -ne [System.Windows.Forms.ProgressBarStyle]::Marquee) {
        $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $progress.MarqueeAnimationSpeed = 25
    } elseif (-not $sync.Marquee -and $progress.Style -ne [System.Windows.Forms.ProgressBarStyle]::Continuous) {
        $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    }
    if (-not $sync.Marquee -and $sync.Pct -gt $progress.Value) {
        $progress.Value = [Math]::Min($sync.Pct, 100)
    }
    if ($sync.Status -ne "") { $lblStatus.Text = $sync.Status }

    if ($sync.NeedModelChoice -and -not $choicePanel.Visible) {
        $log.Visible         = $false
        $choicePanel.Visible = $true
        $lblStatus.Text      = "Choose your transcription model to continue:"
    }

    if ($sync.Done) {
        $timer.Stop()
        $chkClean.Visible = $false
        if ($sync.Success) {
            $progress.Style      = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $progress.Value      = 100
            $lblStatus.ForeColor = $C_ACCENT
            $lblStatus.Text      = "Setup complete!  Starling is ready to use."
            # Reload icon now that install dir exists
            $iconPngNow = Join-Path $INSTALL_DIR "starling\assets\icon.png"
            if ((Test-Path $iconPngNow) -and ($pic.Image -eq $null)) {
                try { $pic.Image = [System.Drawing.Image]::FromFile($iconPngNow) } catch {}
            }
            $btn.Text    = "Launch Starling"
            $btn.Enabled = $true
        } else {
            $progress.Style      = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $lblStatus.ForeColor = $C_RED
            $lblStatus.Text      = "Error: $($sync.Error)"
            $chkClean.Visible    = $existingInstall
            $btn.Text    = "Retry"
            $btn.Enabled = $true
        }
    }
})

# ── Model choice buttons ──────────────────────────────────────────────────────
$cpBtn1.Add_Click({
    $choicePanel.Visible  = $false
    $log.Visible          = $true
    $sync.ModelChoice     = "small.en"
    $sync.NeedModelChoice = $false
})

$cpBtn2.Add_Click({
    $choicePanel.Visible  = $false
    $log.Visible          = $true
    $sync.ModelChoice     = "medium.en"
    $sync.NeedModelChoice = $false
})

# ── Button ────────────────────────────────────────────────────────────────────
$btn.Add_Click({
    if ($btn.Text -eq "Launch Starling") {
        $launcher = Join-Path $INSTALL_DIR "launch.vbs"
        Start-Process "wscript.exe" -ArgumentList "`"$launcher`""
        $form.Close()
        return
    }

    $btn.Enabled         = $false
    $btn.Text            = "Working..."
    $lblStatus.ForeColor = $C_TEXT
    $lblStatus.Text      = "Starting up..."
    $chkClean.Visible    = $false
    $log.Clear()
    $progress.Value = 0
    $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous

    $sync.Pct          = 0
    $sync.Status       = ""
    $sync.LogLine      = ""
    $sync.Marquee      = $false
    $sync.Done         = $false
    $sync.Success      = $false
    $sync.Error        = ""
    $sync.CleanInstall = $chkClean.Checked

    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $null = $ps.AddScript($installWork)
    $null = $ps.AddParameter("s",          $sync)
    $null = $ps.AddParameter("installDir", $INSTALL_DIR)
    $null = $ps.AddParameter("repoZipUrl", $REPO_ZIP_URL)
    $null = $ps.AddParameter("pythonUrl",  $PYTHON_URL)
    $null = $ps.AddParameter("pythonVer",  $PYTHON_VER)
    $ps.BeginInvoke() | Out-Null

    $timer.Start()
})

[void]$form.ShowDialog()
