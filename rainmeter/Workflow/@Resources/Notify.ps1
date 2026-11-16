param([string]$Title, [string]$Body)
# Windows pop-up when a project's time is up
function Esc([string]$s) { [System.Security.SecurityElement]::Escape($s) }
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    $xml = "<toast duration='long'><visual><binding template='ToastGeneric'><text>$(Esc $Title)</text><text>$(Esc $Body)</text></binding></visual><audio src='ms-winsoundevent:Notification.Reminder'/></toast>"
    $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $doc.LoadXml($xml)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Body, $Title, 'OK', 'Information') | Out-Null
}
