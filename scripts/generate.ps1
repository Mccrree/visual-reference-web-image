[CmdletBinding(DefaultParameterSetName = 'Generate')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Generate')]
    [string]$Prompt,

    [Parameter(Mandatory = $true, ParameterSetName = 'Generate')]
    [string]$Output,

    [Parameter(ParameterSetName = 'Generate')]
    [ValidatePattern('^[1-9][0-9]{2,4}x[1-9][0-9]{2,4}$')]
    [string]$Size = '1024x1024',

    [Parameter(ParameterSetName = 'Generate')]
    [ValidateSet('png', 'jpeg', 'webp')]
    [string]$Format,

    [Parameter(ParameterSetName = 'Generate')]
    [Alias('Reference')]
    [string[]]$SubjectReference,

    [Parameter(ParameterSetName = 'Generate')]
    [string[]]$StyleReference,

    [Parameter(ParameterSetName = 'Generate')]
    [string[]]$CompositionReference,

    [Parameter(ParameterSetName = 'Generate')]
    [string]$Profile = 'relay',

    [Parameter(ParameterSetName = 'Generate')]
    [string]$Project = '',

    [Parameter(ParameterSetName = 'Generate')]
    [ValidateRange(30, 900)]
    [int]$Timeout = 300,

    [Parameter(ParameterSetName = 'Generate')]
    [ValidateRange(0, 600)]
    [int]$StallTimeout = 120,

    [Parameter(ParameterSetName = 'Generate')]
    [switch]$KeepConversation,

    [Parameter(ParameterSetName = 'Generate')]
    [switch]$Force,

    [Parameter(Mandatory = $true, ParameterSetName = 'Doctor')]
    [switch]$Doctor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $skillRoot '..\..'))
$workspaceOwnerProfile = [IO.Directory]::GetParent(
    [IO.Directory]::GetParent($workspaceRoot).FullName
).FullName
$runtimeProfile = [Environment]::GetFolderPath('UserProfile')

$imageUseCandidates = @(
    (Join-Path $PSScriptRoot 'image-use-local.py'),
    (Join-Path $workspaceOwnerProfile '.codex\skills\image-use\image-use'),
    (Join-Path $runtimeProfile '.codex\skills\image-use\image-use')
)
$imageUsePath = $imageUseCandidates | Where-Object {
    Test-Path -LiteralPath $_ -PathType Leaf
} | Select-Object -First 1
if (-not $imageUsePath) {
    throw "image-use is not installed. Checked: $($imageUseCandidates -join ', ')"
}

$pythonCandidates = @(
    (Join-Path $workspaceOwnerProfile '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'),
    (Join-Path $runtimeProfile '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
)
$pythonPath = $pythonCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $pythonPath) {
    foreach ($pythonName in @('python3', 'python')) {
        $pythonCommand = Get-Command $pythonName -ErrorAction SilentlyContinue
        if ($pythonCommand) {
            $pythonPath = $pythonCommand.Source
            break
        }
    }
}
if (-not $pythonPath) {
    throw 'Python 3.10 or newer was not found.'
}

$workspaceChromeUse = Join-Path $workspaceRoot 'tools\chrome-use\chrome-use.exe'
if (Test-Path -LiteralPath $workspaceChromeUse -PathType Leaf) {
    $chromeUseDirectory = Split-Path -Parent $workspaceChromeUse
} else {
    $chromeUseCommand = Get-Command 'chrome-use' -ErrorAction SilentlyContinue
    if (-not $chromeUseCommand) {
        throw "chrome-use was not found in $workspaceChromeUse or PATH."
    }
    $chromeUseDirectory = Split-Path -Parent $chromeUseCommand.Source
}

# Keep the locally verified compatibility patch stable during this run.
$env:IMAGE_USE_NO_AUTO_UPDATE = '1'
$env:PATH = $chromeUseDirectory + [IO.Path]::PathSeparator + $env:PATH
$workspaceRelayDirectory = Join-Path $workspaceOwnerProfile '.chrome-use'
if (Test-Path -LiteralPath $workspaceRelayDirectory -PathType Container) {
    $env:CHROME_USE_RELAY_DIR = $workspaceRelayDirectory
}
$workspaceImageUseConfig = Join-Path $workspaceRoot '.image-use-config'
if (-not (Test-Path -LiteralPath $workspaceImageUseConfig -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $workspaceImageUseConfig | Out-Null
}
$env:XDG_CONFIG_HOME = $workspaceImageUseConfig
$env:IMAGE_USE_WEB_LOCK = Join-Path $workspaceImageUseConfig 'chatgpt-web.lock'

# The bundled Codex Python runtime rebuilds PATH when it starts on Windows.
# Re-apply the local chrome-use directory inside Python before image-use runs.
$pythonBootstrap = @'
import os
import runpy
import sys

image_use_path = sys.argv.pop(1)
chrome_use_directory = sys.argv.pop(1)
os.environ["PATH"] = chrome_use_directory + os.pathsep + os.environ.get("PATH", "")
sys.argv[0] = image_use_path
runpy.run_path(image_use_path, run_name="__main__")
'@

if ($Doctor) {
    & $pythonPath -X utf8 -c $pythonBootstrap $imageUsePath $chromeUseDirectory doctor
    exit $LASTEXITCODE
}

$referenceCount = @($SubjectReference | Where-Object { $_ }).Count +
    @($StyleReference | Where-Object { $_ }).Count +
    @($CompositionReference | Where-Object { $_ }).Count
if ($referenceCount -gt 4) {
    throw "image-use accepts at most 4 attached references; received $referenceCount"
}

if ([IO.Path]::IsPathRooted($Output)) {
    $outputPath = [IO.Path]::GetFullPath($Output)
} else {
    $outputPath = [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Output))
}
$workspacePrefix = $workspaceRoot.TrimEnd('\') + '\'
if (-not $outputPath.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Output must stay inside the workspace: $workspaceRoot"
}
if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    throw "Output already exists. Choose another path or pass -Force: $outputPath"
}

$outputDirectory = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$arguments = @(
    '-X', 'utf8', '-c', $pythonBootstrap, $imageUsePath, $chromeUseDirectory, $Prompt,
    '--backend', 'web',
    '--profile', $Profile,
    '--project', $Project,
    '-o', $outputPath,
    '--size', $Size,
    '--timeout', $Timeout,
    '--stall-timeout', $StallTimeout,
    '--quiet'
)
if ($Format) {
    $arguments += @('--format', $Format)
}
foreach ($referencePath in $SubjectReference) {
    $arguments += @('--ref', [IO.Path]::GetFullPath($referencePath))
}
foreach ($referencePath in $StyleReference) {
    $arguments += @('--style-ref', [IO.Path]::GetFullPath($referencePath))
}
foreach ($referencePath in $CompositionReference) {
    $arguments += @('--composition-ref', [IO.Path]::GetFullPath($referencePath))
}
if ($KeepConversation) {
    $arguments += '--keep-conversation'
}

$imageUseOutput = & $pythonPath @arguments
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    exit $exitCode
}
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "image-use exited successfully but did not create $outputPath"
}
Write-Output $outputPath
