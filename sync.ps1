<#
.SYNOPSIS
    Automated Git synchronization engine for downloader-scripts.

.DESCRIPTION
    sync.ps1 — Reliable synchronization script for https://github.com/Aaradhya-Dev-Tamrakar/downloader-scripts
    - Runs pre-commit secret scanning (API keys, tokens, credentials).
    - Checks and reports branch status.
    - Formats clean conventional commits automatically or uses custom message (-m).
    - Safely rebases with --autostash and pushes to origin.

.PARAMETER Message
    Custom commit message (e.g. -m "feat: add video quality selector").
    Alias: -m. If omitted, an automatic conventional commit is generated.

.PARAMETER PullOnly
    Pull remote updates with --rebase --autostash without staging or committing.

.PARAMETER PushOnly
    Pushes existing local commits without creating new commits.

.PARAMETER NoPush
    Stages and commits changes locally without pushing to remote origin.

.PARAMETER WhatIf
    Dry-run mode: previews changes and secret scan without modifying git state.

.PARAMETER Status
    Displays repository status and unpushed commits.

.EXAMPLE
    .\sync.ps1
    .\sync.ps1 -m "feat(presets): add 1080p profile"
    .\sync.ps1 -PullOnly
    .\sync.ps1 -WhatIf
#>

[CmdletBinding()]
param (
    [Alias("m")]
    [string]$Message,

    [switch]$PullOnly,

    [switch]$PushOnly,

    [switch]$NoPush,

    [switch]$WhatIf,

    [switch]$Status
)

$ErrorActionPreference = "Stop"

$TargetRemoteName = "origin"
$TargetRemoteUrl  = "https://github.com/Aaradhya-Dev-Tamrakar/downloader-scripts.git"

function Write-Status {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

function Write-Notice {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Yellow)
}

function Write-Success {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Green)
}

function Write-Fail {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Red)
}

function Ensure-RemoteConfigured {
    $existingRemotes = @(git remote)
    if ($existingRemotes -notcontains $TargetRemoteName) {
        Write-Status "Adding remote '$TargetRemoteName' ($TargetRemoteUrl)..."
        git remote add $TargetRemoteName $TargetRemoteUrl
    }
    else {
        $currentUrl = (git remote get-url $TargetRemoteName 2>$null)
        if ($currentUrl) { $currentUrl = $currentUrl.Trim() }
        $cleanCurrent = $currentUrl -replace '\.git$', ''
        $cleanTarget  = $TargetRemoteUrl -replace '\.git$', ''
        if ($cleanCurrent -ne $cleanTarget) {
            Write-Notice "Updating remote '$TargetRemoteName' URL to $TargetRemoteUrl..."
            git remote set-url $TargetRemoteName $TargetRemoteUrl
        }
    }
}

function Find-StagedSecrets {
    $stagedDiff = git diff --cached -U0 2>$null
    if (-not $stagedDiff) { return @() }

    $addedLines = @($stagedDiff | Where-Object { $_ -match '^\+[^+]' } | ForEach-Object { $_.Substring(1) })
    if ($addedLines.Count -eq 0) { return @() }

    $secretPatterns = @(
        'AKIA[0-9A-Z]{16}',                                              # AWS Access Key
        'sk-[a-zA-Z0-9]{20,}',                                           # OpenAI API Key
        'sk-ant-[a-zA-Z0-9\-]{20,}',                                     # Anthropic API Key
        'ghp_[a-zA-Z0-9]{36}',                                           # GitHub Personal Token
        'github_pat_[a-zA-Z0-9_]{20,}',                                  # GitHub Fine-grained PAT
        'AIza[0-9A-Za-z\-_]{35}',                                        # Google / Gemini API Key
        'xox[baprs]-[0-9a-zA-Z\-]{10,}',                                 # Slack Token
        '-----BEGIN (RSA|EC|OPENSSH|PGP|DSA)? ?PRIVATE KEY-----',        # Private Keys
        '(?i)(api[_-]?key|secret|password|token|passwd)\s*[:=]\s*[''"][^''"\s]{8,}[''"]' # Generic Secrets
    )

    $hits = @()
    foreach ($line in $addedLines) {
        foreach ($pattern in $secretPatterns) {
            if ($line -match $pattern) {
                $snippet = $line.Trim()
                $hits += [PSCustomObject]@{
                    Pattern = $pattern
                    Snippet = $snippet.Substring(0, [Math]::Min(60, $snippet.Length))
                }
                break
            }
        }
    }

    return @($hits)
}

function Get-AutoCommitMessage {
    $stagedFiles = @(git diff --cached --name-only)
    if ($stagedFiles.Count -eq 0) {
        return "chore: routine repository synchronization"
    }

    if ($stagedFiles -contains "sync.ps1" -and $stagedFiles.Count -eq 1) {
        return "chore(sync): update sync automation script"
    }
    if ($stagedFiles -contains ".gitignore" -and $stagedFiles.Count -eq 1) {
        return "chore(git): update .gitignore exclusions"
    }
    if ($stagedFiles -contains "README.md" -and $stagedFiles.Count -eq 1) {
        return "docs: update documentation"
    }

    $scripts = @($stagedFiles | Where-Object { $_ -match '\.(ps1|bat|cmd|sh|py)$' })
    if ($scripts.Count -gt 0) {
        return "feat(downloader): update automation scripts and download presets"
    }

    return "chore: update repository files ($($stagedFiles.Count) changed)"
}

# --- Main Flow ---
try {
    Ensure-RemoteConfigured

    $currentBranch = (git branch --show-current 2>$null)
    if (-not $currentBranch) {
        $currentBranch = "main"
    }

    if ($Status) {
        Write-Status "=== Downloader Scripts Repository Status ==="
        Write-Status "Active Branch: $currentBranch"
        git status -s
        $unpushed = @(git log "$($TargetRemoteName)/$($currentBranch)..HEAD" --oneline 2>$null)
        if ($unpushed.Count -gt 0) {
            Write-Notice "Unpushed Commits ($($unpushed.Count)):"
            $unpushed | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        } else {
            Write-Success "All commits pushed to $TargetRemoteName/$currentBranch."
        }
        return
    }

    if ($PullOnly) {
        Write-Status "Pulling latest updates with --rebase --autostash..."
        git pull --rebase --autostash $TargetRemoteName $currentBranch
        Write-Success "Pull completed."
        return
    }

    if ($PushOnly) {
        Write-Status "Pushing existing commits to $TargetRemoteName/$currentBranch..."
        git push $TargetRemoteName $currentBranch
        Write-Success "Push completed."
        return
    }

    # Stage all tracked & untracked non-ignored changes
    git add -A

    # Pre-commit secret scanning
    $secrets = Find-StagedSecrets
    if ($secrets.Count -gt 0) {
        Write-Fail "SECURITY ALERT: Potential secrets detected in staged diff!"
        foreach ($s in $secrets) {
            Write-Fail "  Pattern: $($s.Pattern) | Match: $($s.Snippet)"
        }
        git reset HEAD 2>$null | Out-Null
        throw "Aborting commit due to detected secrets."
    }

    $stagedChanges = @(git diff --cached --name-only)
    if ($stagedChanges.Count -eq 0) {
        Write-Status "Working tree clean; checking for unpushed commits..."
        $unpushed = @(git log "$($TargetRemoteName)/$($currentBranch)..HEAD" --oneline 2>$null)
        if ($unpushed.Count -gt 0) {
            Write-Status "Pushing $($unpushed.Count) unpushed commit(s)..."
            if (-not $WhatIf -and -not $NoPush) {
                git push $TargetRemoteName $currentBranch
                Write-Success "Pushed successfully."
            }
        } else {
            Write-Success "Repository is fully clean and up to date."
        }
        return
    }

    # Determine commit message
    $finalMsg = $Message
    if ([string]::IsNullOrWhiteSpace($finalMsg)) {
        $finalMsg = Get-AutoCommitMessage
    }

    if ($WhatIf) {
        Write-Notice "[WhatIf] Dry-run preview:"
        Write-Notice "  Branch: $currentBranch"
        Write-Notice "  Commit Message: $finalMsg"
        Write-Notice "  Staged Files: $($stagedChanges -join ', ')"
        git reset HEAD 2>$null | Out-Null
        return
    }

    Write-Status "Committing changes ($($stagedChanges.Count) file(s))..."
    git commit -m $finalMsg

    if ($NoPush) {
        Write-Success "Committed locally (push skipped via -NoPush)."
        return
    }

    # Pull rebase before push
    Write-Status "Syncing with remote..."
    git pull --rebase --autostash $TargetRemoteName $currentBranch 2>$null | Out-Null

    Write-Status "Pushing to $TargetRemoteName/$currentBranch..."
    git push $TargetRemoteName $currentBranch
    Write-Success "Successfully synchronized with $TargetRemoteUrl"
}
catch {
    Write-Fail "Sync failed: $_"
    exit 1
}
