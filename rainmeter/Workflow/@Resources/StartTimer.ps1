param([string]$Url, [string]$Key, [string]$Id)
# Starts a project's timer (uses the server's clock)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$body = @{ p_id = $Id } | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri ($Url.TrimEnd('/') + '/rest/v1/rpc/start_timer') `
  -Headers @{ apikey = $Key } -ContentType 'application/json' -Body $body | Out-Null
