#!/usr/bin/env pwsh
param([string]$url)

$ErrorActionPreference = 'SilentlyContinue' # показываем только свои сообщения

# === Константы ===
$script:LogPath    = '/var/log/web_checks/script.log'
$script:Ports      = @(80, 443)
$script:Iterations = 3

# === Общая функция логирования ===
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )
    $ts = (Get-Date -Format s)
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $script:LogPath -Value $line
}

# === Доп. функции ===
function CalcTime {
    param([double[]]$TimesMs)
    if (-not $TimesMs -or $TimesMs.Count -eq 0) { Write-Log "Нет данных для расчёта среднего времени" 'WARN'; return }
    $avg = [Math]::Round(($TimesMs | Measure-Object -Average).Average, 2)
    Write-Log "Среднее время ответа: $avg мс" 'INFO'
}

function CalcWeight {
    param([long[]]$SizesBytes)
    if (-not $SizesBytes -or $SizesBytes.Count -eq 0) { Write-Log "Нет данных для расчёта среднего размера" 'WARN'; return }
    $avg = [Math]::Round(($SizesBytes | Measure-Object -Average).Average, 0)
    Write-Log "Средний размер ответа: $avg байт" 'INFO'
}

# === Основная функция ===
function WebRequest {
    param([string]$url)

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Log "Не передан параметр URL. Пример: pwsh ./web_check.ps1 https://mail.ru" 'ERROR'
        return
    }

    if ($url -notmatch '^[a-z]+://') { $url = 'https://' + $url }

    try { $u = [Uri]$url }
    catch { Write-Log "Некорректный URL: $url" 'ERROR'; return }

    $hostName = $u.Host
    Write-Log "Старт проверки доступности: $hostName (порты: $($script:Ports -join ', '), итераций: $script:Iterations)" 'INFO'

    $times = @()
    $sizes = @()
    $timeoutSec = 10

    foreach ($port in $script:Ports) {
        for ($i = 1; $i -le $script:Iterations; $i++) {
            $scheme = if ($port -eq 80) { 'http' } else { 'https' }
            $probeUri = "{0}://{1}:{2}/" -f $scheme, $hostName, $port

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $resp = $null
            try {
                $resp = Invoke-WebRequest -Uri $probeUri -TimeoutSec $timeoutSec `
                    -MaximumRedirection 5 -Headers @{ 'User-Agent' = 'Mozilla/5.0' } `
                    -ErrorAction Stop
            } catch {
                $sw.Stop()
                Write-Log "[port $port][#$i] Ошибка выполнения запроса ($probeUri). Сайт недоступен." 'ERROR'
                return
            }
            $sw.Stop()

            if (-not $resp) {
                Write-Log "[port $port][#$i] Пустой ответ. Сайт недоступен." 'ERROR'
                return
            }

            $code = [int]$resp.StatusCode
            $desc = if ($resp.PSObject.Properties.Name -contains 'StatusDescription') {
                $resp.StatusDescription
            } elseif ($resp.BaseResponse -and $resp.BaseResponse.ReasonPhrase) {
                $resp.BaseResponse.ReasonPhrase
            } else { '' }

            if ($code -ne 200) {
                Write-Log "[port $port][#$i] Код ответа: $code $desc — ошибка. Ожидали 200." 'ERROR'
                return
            }

            $ms   = [Math]::Round($sw.Elapsed.TotalMilliseconds, 2)
            $size = $resp.RawContentLength
            if (-not $size -or $size -lt 0) { $size = [Text.Encoding]::UTF8.GetByteCount($resp.Content) }

            $times += $ms
            $sizes += [long]$size
            Write-Log "[port $port][#$i] 200 OK — время: ${ms}мс; размер: ${size} байт." 'INFO'
        }
    }

    Write-Log "Все итерации успешны по портам 80 и 443." 'INFO'
    CalcTime   -TimesMs    $times
    CalcWeight -SizesBytes $sizes
}

# === Точка входа ===
WebRequest -url $url
