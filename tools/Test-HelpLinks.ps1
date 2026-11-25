<#
.SYNOPSIS
    Verifies the help links of the app: the app.json links and the context-sensitive help link of every page.

.DESCRIPTION
    The app.json links follow the documentation rules of bifrost-support (DOCUMENTATION-RULES.md, Addresses and
    Context-sensitive help):

      help, privacyStatement, EULA   must point at the public site, https://docs.bifrost.origo.is/.
      contextSensitiveHelpUrl        the help instance of the app, <site>{0}/help/<app>/, when the app has pages.
                                     An app without pages has no help instance and points at its own page,
                                     <site>{0}/<app>/ (documentation rules; Architect 24.11.2026, #39).

    Every page and page extension under app/src must declare ContextSensitiveHelpPage, and the help
    page it names must exist on the documentation site (businesscentralal/bifrost) in both locales:

      en-US  help/<app>/<slug>.md
      is-IS  i18n/is-IS/docusaurus-plugin-content-docs-help-<app>/current/<slug>.md

    Business Central opens <contextSensitiveHelpUrl with the user's locale><slug>, so a missing file
    in either locale is a broken Help link for those users. When the app has no pages there is nothing to
    look up on the site, and DocsPath is not needed.

.PARAMETER DocsPath
    Path to a checkout of businesscentralal/bifrost. Required when the app has pages.

.PARAMETER AppFolder
    The AL app folder (default: ../app next to this script).

.PARAMETER DocsApp
    The documentation app id the pages belong to (default: quality-management).

.EXAMPLE
    ./tools/Test-HelpLinks.ps1 -DocsPath D:\Git\Public\bifrost
#>
param(
    [string]$DocsPath = '',
    [string]$AppFolder = (Join-Path $PSScriptRoot '..\app'),
    [string]$DocsApp = 'quality-management',
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

if ($SelfTest) {
    $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
    $fixtureApp = Join-Path $fixtureRoot 'app'
    $fixtureDocs = Join-Path $fixtureRoot 'docs'
    $scriptPath = $PSCommandPath
    try {
        New-Item -ItemType Directory -Path (Join-Path $fixtureApp 'src') -Force | Out-Null
        $english = Join-Path $fixtureDocs 'help/quality-management'
        $icelandic = Join-Path $fixtureDocs 'i18n/is-IS/docusaurus-plugin-content-docs-help-quality-management/current'
        New-Item -ItemType Directory -Path $english, $icelandic -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $english 'inspection.md') -Value '# Inspection'
        Set-Content -LiteralPath (Join-Path $icelandic 'inspection.md') -Value '# Skoðun'
        $cases = @(
            @{ Name = 'App without pages: help instance URL refused'; Slug = 'quality-management'; Url = 'https://docs.bifrost.origo.is/{0}/help/quality-management/'; Page = $false; MissingTranslation = $false; Expected = $false },
            @{ Name = 'App without pages: own page accepted'; Slug = 'quality-management'; Url = 'https://docs.bifrost.origo.is/{0}/quality-management/'; Page = $false; MissingTranslation = $false; Expected = $true },
            @{ Name = 'Wrong help instance refused'; Slug = 'quality-management'; Url = 'https://docs.bifrost.origo.is/{0}/help/other/'; Page = $false; MissingTranslation = $false; Expected = $false },
            @{ Name = 'Bilingual page links accepted'; Slug = 'quality-management'; Url = 'https://docs.bifrost.origo.is/{0}/help/quality-management/'; Page = $true; MissingTranslation = $false; Expected = $true },
            @{ Name = 'Missing Icelandic page refused'; Slug = 'quality-management'; Url = 'https://docs.bifrost.origo.is/{0}/help/quality-management/'; Page = $true; MissingTranslation = $true; Expected = $false },
            @{ Name = 'Other pageless app keeps its landing URL'; Slug = 'other'; Url = 'https://docs.bifrost.origo.is/{0}/other/'; Page = $false; MissingTranslation = $false; Expected = $true }
        )
        foreach ($case in $cases) {
            $manifest = @{ help = 'https://docs.bifrost.origo.is/en-us/quality-management/'; privacyStatement = 'https://docs.bifrost.origo.is/en-us/licensing/privacy/'; EULA = 'https://docs.bifrost.origo.is/en-us/licensing/eula/'; contextSensitiveHelpUrl = $case.Url }
            $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $fixtureApp 'app.json')
            $pagePath = Join-Path $fixtureApp 'src/Inspection.Page.al'
            Remove-Item -LiteralPath $pagePath -ErrorAction SilentlyContinue
            if ($case.Page) {
                Set-Content -LiteralPath $pagePath -Value "page 50100 `"Inspection`" { ContextSensitiveHelpPage = 'inspection'; }"
            }
            $translatedPage = Join-Path $icelandic 'inspection.md'
            Set-Content -LiteralPath $translatedPage -Value '# Skoðun'
            if ($case.MissingTranslation) { Remove-Item -LiteralPath $translatedPage }
            $passed = $true
            try {
                & $scriptPath -AppFolder $fixtureApp -DocsPath $fixtureDocs -DocsApp $case.Slug *> $null
            } catch {
                $passed = $false
            }
            if ($passed -ne $case.Expected) { throw "Self-test failed: $($case.Name)" }
        }
        Write-Host "$($cases.Count) help-link regression cases passed."
    } finally {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    return
}
$siteRoot = 'https://docs.bifrost.origo.is/'
$problems = [System.Collections.Generic.List[string]]::new()

$pages = @(Get-ChildItem -LiteralPath (Join-Path $AppFolder 'src') -Recurse -Filter '*.al' | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        $header = [regex]::Match($text, '(?m)^\s*(page|pageextension)\s+(\d+)\s+"([^"]+)"')
        if ($header.Success) { [pscustomobject]@{ Header = $header; Text = $text } }
    })

$appJson = Get-Content -LiteralPath (Join-Path $AppFolder 'app.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($property in 'help', 'privacyStatement', 'EULA') {
    $value = [string]$appJson.$property
    if (-not $value.StartsWith($siteRoot)) { $problems.Add("app.json $property is '$value' - it must start with $siteRoot") }
}
$helpUrl = [string]$appJson.contextSensitiveHelpUrl
$hasHelpInstance = $pages.Count -gt 0
if (-not $hasHelpInstance) {
    $expected = "$siteRoot{0}/$DocsApp/"
    if ($helpUrl -ne $expected) { $problems.Add("app.json contextSensitiveHelpUrl is '$helpUrl', but the app has no pages and so no help instance - point it at the app's own page, $expected") }
} else {
    $expected = "$siteRoot{0}/help/$DocsApp/"
    if ($helpUrl -ne $expected) { $problems.Add("app.json contextSensitiveHelpUrl is '$helpUrl' - it must be $expected") }
}
if ($pages.Count -gt 0) {
    if ($DocsPath -eq '') { throw "The app has $($pages.Count) page(s): pass -DocsPath with a checkout of businesscentralal/bifrost." }
    $enDir = Join-Path $DocsPath "help/$DocsApp"
    $isDir = Join-Path $DocsPath "i18n/is-IS/docusaurus-plugin-content-docs-help-$DocsApp/current"
    foreach ($dir in $enDir, $isDir) {
        if (-not (Test-Path -LiteralPath $dir)) { throw "Help folder not found: $dir" }
    }
    foreach ($page in $pages) {
        $header = $page.Header
        $name = "$($header.Groups[1].Value) $($header.Groups[2].Value) `"$($header.Groups[3].Value)`""
        $help = [regex]::Match($page.Text, "ContextSensitiveHelpPage\s*=\s*'([^']*)'")
        if (-not $help.Success) {
            # A page extension inherits the help of the page it extends.
            if ($header.Groups[1].Value -eq 'page') { $problems.Add("$name has no ContextSensitiveHelpPage") }
            continue
        }
        $slug = $help.Groups[1].Value
        if ($slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            $problems.Add("$name uses '$slug' - use a lower-case kebab-case slug without '#' or '/'")
            continue
        }
        if (-not (Test-Path -LiteralPath (Join-Path $enDir "$slug.md"))) { $problems.Add("$name -> '$slug': missing en-US help/$DocsApp/$slug.md") }
        if (-not (Test-Path -LiteralPath (Join-Path $isDir "$slug.md"))) { $problems.Add("$name -> '$slug': missing is-IS help page $slug.md") }
    }
}

Write-Host "Checked the app.json links and $($pages.Count) page(s)"
if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Host "::error::$_" }
    throw "$($problems.Count) help link problem(s)."
}
if (-not $hasHelpInstance) {
    Write-Host "The app has no pages and no help instance; help, privacyStatement, EULA and contextSensitiveHelpUrl point at the app's pages on $siteRoot."
} elseif ($pages.Count -eq 0) {
    Write-Host "The app has no pages; contextSensitiveHelpUrl points at its release help instance on $siteRoot."
} else {
    Write-Host 'Every page links to a help page that exists in en-US and is-IS.'
}
