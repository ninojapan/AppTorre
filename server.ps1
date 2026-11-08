# =====================================================================
#  Cronologia Guzzi Twr - Server HTTP locale in PowerShell puro
#  Nessuna dipendenza esterna: solo PowerShell integrato di Windows.
#  Stessa meccanica di avvio di "Gestione O.S.L. Nave TRIESTE".
#
#  Database locale (cartella DATI accanto a questo script):
#    DATI\config.json                 archivio A/C, eventi, impostazioni
#    DATI\cronologia\AAAA-MM-GG.json  una cronologia per ogni giorno
#    DATI\backup\                     copia di sicurezza ad ogni salvataggio
# =====================================================================

$ErrorActionPreference = "Stop"

# ------------------------- Configurazione ----------------------------
$Port     = 5040
$AppTitle = "Cronologia Guzzi Twr"
$HtmlFile = "Cronologia Guzzi Twr.html"
$Version  = "1.0"

# Cartella dello script (tutto e' relativo a questa cartella -> portabile)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ScriptDir)) { $ScriptDir = (Get-Location).Path }
$ScriptDirFull = [System.IO.Path]::GetFullPath($ScriptDir)

$DataDir    = Join-Path $ScriptDir "DATI"
$DayDir     = Join-Path $DataDir "cronologia"
$BackupDir  = Join-Path $DataDir "backup"
$ConfigFile = Join-Path $DataDir "config.json"
$PidFile    = Join-Path $DataDir "server.pid"

foreach ($d in @($DataDir, $DayDir, $BackupDir)) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

# UTF-8 SENZA BOM ovunque
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Tabella MIME types
$MimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".htm"  = "text/html; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".gif"  = "image/gif"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
}

# --------------------------- Funzioni --------------------------------

function Read-TextFileUtf8($path) {
  if (Test-Path $path -PathType Leaf) {
    $content = [System.IO.File]::ReadAllText($path, $Utf8NoBom)
    # rimuovi eventuale BOM residuo (U+FEFF) e fai trim
    $content = $content.TrimStart([char]0xFEFF)
    return $content.Trim()
  }
  return ""
}

function Save-WithBackup($path, $text) {
  # 1) copia di sicurezza della versione precedente in DATI\backup
  if (Test-Path $path -PathType Leaf) {
    $bk = Join-Path $BackupDir ([System.IO.Path]::GetFileName($path) + ".backup")
    [System.IO.File]::Copy($path, $bk, $true)
  }
  # 2) scrittura su file temporaneo e sostituzione: il file dati non resta
  #    mai scritto a meta' (es. mancanza corrente durante il salvataggio)
  $tmp = "$path.tmp"
  [System.IO.File]::WriteAllText($tmp, $text, $Utf8NoBom)
  try {
    if (Test-Path $path -PathType Leaf) { [System.IO.File]::Replace($tmp, $path, $null) }
    else { [System.IO.File]::Move($tmp, $path) }
  }
  catch {
    # fallback per dischi/cartelle di rete che non supportano Replace
    [System.IO.File]::Copy($tmp, $path, $true)
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }
}

function Get-RequestBody($request) {
  $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
  $body = $reader.ReadToEnd()
  $reader.Close()
  return $body.TrimStart([char]0xFEFF).Trim()
}

function Send-ByteResponse($response, $bytes, $contentType, $status = 200) {
  $response.StatusCode = $status
  $response.ContentType = $contentType
  $response.Headers.Add("Cache-Control", "no-store")
  $response.ContentLength64 = $bytes.Length
  $response.OutputStream.Write($bytes, 0, $bytes.Length)
  $response.OutputStream.Close()
}

function Send-JsonResponse($response, $json, $status = 200) {
  $bytes = $Utf8NoBom.GetBytes($json)
  Send-ByteResponse $response $bytes "application/json; charset=utf-8" $status
}

function Send-Error($response, $message, $status = 400) {
  Send-JsonResponse $response ('{"status":"error","message":"' + $message + '"}') $status
}

function Test-DayKey($d) {
  # accetta solo date AAAA-MM-GG (nessun percorso / traversal possibile)
  return (-not [string]::IsNullOrWhiteSpace($d)) -and ($d -match '^\d{4}-\d{2}-\d{2}$')
}

function Get-DayFile($d) { return (Join-Path $DayDir "$d.json") }

function Get-DayFiles {
  $list = @()
  foreach ($f in (Get-ChildItem -Path $DayDir -Filter "*.json" -File | Sort-Object Name)) {
    if ($f.BaseName -match '^\d{4}-\d{2}-\d{2}$') { $list += $f }
  }
  return $list
}

function Get-DaysIndex {
  # { "AAAA-MM-GG": numero_eventi, ... } solo per i giorni con cronologia
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append("{")
  $first = $true
  foreach ($f in (Get-DayFiles)) {
    $txt = Read-TextFileUtf8 $f.FullName
    $n = ([regex]::Matches($txt, '"ts"\s*:')).Count
    if ($n -gt 0) {
      if (-not $first) { [void]$sb.Append(",") }
      [void]$sb.Append('"' + $f.BaseName + '":' + $n)
      $first = $false
    }
  }
  [void]$sb.Append("}")
  return $sb.ToString()
}

function Get-RangeJson($from, $to) {
  # { "AAAA-MM-GG": [ ...eventi... ], ... } per i giorni nell'intervallo
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append("{")
  $first = $true
  foreach ($f in (Get-DayFiles)) {
    $k = $f.BaseName
    if ($from -and ([string]::CompareOrdinal($k, $from) -lt 0)) { continue }
    if ($to   -and ([string]::CompareOrdinal($k, $to)   -gt 0)) { continue }
    $txt = Read-TextFileUtf8 $f.FullName
    if (-not $txt.StartsWith("[")) { continue }
    if (-not $first) { [void]$sb.Append(",") }
    [void]$sb.Append('"' + $k + '":' + $txt)
    $first = $false
  }
  [void]$sb.Append("}")
  return $sb.ToString()
}

function ConvertTo-JsonString($s) {
  return '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Send-StaticFile($response, $path) {
  if ($path -eq "/" -or [string]::IsNullOrWhiteSpace($path)) { $path = "/$HtmlFile" }
  $relative = [System.Uri]::UnescapeDataString($path.TrimStart("/"))
  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir $relative))

  # niente file fuori dalla cartella dell'app; fallback alla SPA
  if (-not $fullPath.StartsWith($ScriptDirFull, [System.StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path $fullPath -PathType Leaf)) {
    $fullPath = Join-Path $ScriptDir $HtmlFile
  }

  if (Test-Path $fullPath -PathType Leaf) {
    $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
    $ct  = $MimeTypes[$ext]
    if (-not $ct) { $ct = "application/octet-stream" }
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    Send-ByteResponse $response $bytes $ct 200
  }
  else {
    $bytes = $Utf8NoBom.GetBytes("404 - File non trovato")
    Send-ByteResponse $response $bytes "text/plain; charset=utf-8" 404
  }
}

# --------------------------- Avvio server ----------------------------

$http   = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$http.Prefixes.Add($prefix)

try {
  $http.Start()
}
catch {
  Write-Host "ERRORE: impossibile avviare il server sulla porta $Port" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  Write-Host ""
  Write-Host "Suggerimento: la porta potrebbe essere gia' in uso. Chiudi altre istanze e riprova." -ForegroundColor Yellow
  Write-Host "Premi INVIO per chiudere..."
  Read-Host | Out-Null
  exit 1
}

# PID del server: serve ad APRI_APP.bat per chiudere SOLO questa istanza
# (senza toccare altri server PowerShell, es. OSL TRIESTE)
[System.IO.File]::WriteAllText($PidFile, [string]$PID, $Utf8NoBom)
try { $Host.UI.RawUI.WindowTitle = "$AppTitle - Server" } catch { }

# ---------------------------- Banner ---------------------------------
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      $AppTitle - Server locale"                    -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   App:          " -NoNewline; Write-Host "http://localhost:$Port" -ForegroundColor Green
Write-Host "   Database:     $DataDir"  -ForegroundColor Gray
Write-Host "   Cronologie:   $DayDir"   -ForegroundColor Gray
Write-Host "   Backup:       $BackupDir" -ForegroundColor Gray
Write-Host ""
Write-Host "   Per FERMARE il server: premi " -NoNewline; Write-Host "CTRL+C" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------- Loop richieste ----------------------------
try {
  while ($http.IsListening) {
    $response = $null
    try {
      $context  = $http.GetContext()
      $request  = $context.Request
      $response = $context.Response

      $path   = $request.Url.AbsolutePath
      $method = $request.HttpMethod

      # ------------------------- ROUTING API -------------------------
      if ($path -eq "/api/ping") {
        Send-JsonResponse $response '{"status":"ok"}'
      }
      elseif ($path -eq "/api/info" -and $method -eq "GET") {
        $json = '{"app":' + (ConvertTo-JsonString $AppTitle) + ',"version":' + (ConvertTo-JsonString $Version) +
                ',"dataDir":' + (ConvertTo-JsonString $DataDir) + '}'
        Send-JsonResponse $response $json
      }
      elseif ($path -eq "/api/config" -and $method -eq "GET") {
        $data = Read-TextFileUtf8 $ConfigFile
        if ([string]::IsNullOrWhiteSpace($data)) { $data = "{}" }
        Send-JsonResponse $response $data
      }
      elseif ($path -eq "/api/config" -and $method -eq "POST") {
        $body = Get-RequestBody $request
        if (-not $body.StartsWith("{")) { Send-Error $response "config non valida" }
        else {
          Save-WithBackup $ConfigFile $body
          Send-JsonResponse $response '{"status":"ok"}'
        }
      }
      elseif ($path -eq "/api/days" -and $method -eq "GET") {
        Send-JsonResponse $response (Get-DaysIndex)
      }
      elseif ($path -eq "/api/day" -and $method -eq "GET") {
        $d = $request.QueryString["d"]
        if (-not (Test-DayKey $d)) { Send-Error $response "data non valida" }
        else {
          $data = Read-TextFileUtf8 (Get-DayFile $d)
          if (-not $data.StartsWith("[")) { $data = "[]" }
          Send-JsonResponse $response $data
        }
      }
      elseif ($path -eq "/api/day" -and $method -eq "POST") {
        $d = $request.QueryString["d"]
        $body = Get-RequestBody $request
        if (-not (Test-DayKey $d)) { Send-Error $response "data non valida" }
        elseif (-not $body.StartsWith("[")) { Send-Error $response "cronologia non valida" }
        else {
          $file = Get-DayFile $d
          if ($body -match '^\[\s*\]$') {
            # giorno svuotato: tolgo il file (resta la copia in backup)
            if (Test-Path $file -PathType Leaf) {
              [System.IO.File]::Copy($file, (Join-Path $BackupDir "$d.json.backup"), $true)
              Remove-Item $file -Force
            }
          }
          else {
            Save-WithBackup $file $body
          }
          Send-JsonResponse $response '{"status":"ok"}'
        }
      }
      elseif ($path -eq "/api/range" -and $method -eq "GET") {
        $from = $request.QueryString["from"]
        $to   = $request.QueryString["to"]
        if ($from -and -not (Test-DayKey $from)) { $from = $null }
        if ($to   -and -not (Test-DayKey $to))   { $to = $null }
        Send-JsonResponse $response (Get-RangeJson $from $to)
      }
      elseif ($path.StartsWith("/api/")) {
        Send-Error $response "endpoint sconosciuto" 404
      }
      else {
        # ----------------------- File statici ------------------------
        Send-StaticFile $response $path
      }
    }
    catch {
      # Un errore su UNA richiesta non deve uccidere il server
      Write-Host ("Errore richiesta: " + $_.Exception.Message) -ForegroundColor Yellow
      if ($response -ne $null) {
        try {
          $response.StatusCode = 500
          $response.Close()
        } catch { }
      }
    }
  }
}
finally {
  if ($http.IsListening) { $http.Stop() }
  $http.Close()
  Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  Write-Host ""
  Write-Host "Server fermato" -ForegroundColor Yellow
}
