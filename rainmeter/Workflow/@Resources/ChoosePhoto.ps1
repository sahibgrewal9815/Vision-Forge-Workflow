param([string]$Res)
# Opens a Windows file picker, crops the chosen image to the widget's photo shape,
# saves it inside @Resources\Photos and points Variables.inc at it.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$owner = New-Object System.Windows.Forms.Form
$owner.TopMost = $true
$owner.ShowInTaskbar = $false
$owner.StartPosition = 'CenterScreen'
$owner.Size = New-Object System.Drawing.Size(1,1)
$owner.Opacity = 0
$owner.Show()
$owner.Activate()

$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title = 'Choose a photo for the Workflow widget'
$dlg.Filter = 'Images|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.tif;*.tiff|All files|*.*'
$result = $dlg.ShowDialog($owner)
$owner.Close()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }

$Res = $Res.TrimEnd('\')
$dir = Join-Path $Res 'Photos'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

try {
    $src = [System.Drawing.Image]::FromFile($dlg.FileName)
} catch {
    [System.Windows.Forms.MessageBox]::Show('That file is not a picture Windows can open.','Workflow') | Out-Null
    exit 0
}

# Respect phone-photo rotation (EXIF orientation)
try {
    $prop = $src.GetPropertyItem(0x0112)
    switch ([int]$prop.Value[0]) {
        3 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
} catch {}

# Cover-crop to the photo area's shape (312 x 164), saved at 3x for sharpness
$tw = 936; $th = 492
$scale = [Math]::Max($tw / $src.Width, $th / $src.Height)
$cw = [int]($tw / $scale); $ch = [int]($th / $scale)
$cx = [int](($src.Width - $cw) / 2); $cy = [int](($src.Height - $ch) / 2)

$bmp = New-Object System.Drawing.Bitmap($tw, $th)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $tw, $th)), (New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $src.Dispose()

$name = 'photo_' + (Get-Date -Format 'yyyyMMddHHmmss') + '.jpg'
$dest = Join-Path $dir $name
$jpg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
$bmp.Save($dest, $jpg, $ep)
$bmp.Dispose()

# Point the widget at the new photo
$vars = Join-Path $Res 'Variables.inc'
$lines = Get-Content -LiteralPath $vars
$lines = $lines | ForEach-Object { if ($_ -match '^Photo=') { "Photo=#@#Photos\$name" } else { $_ } }
Set-Content -LiteralPath $vars -Value $lines -Encoding ASCII

# Tidy up older photos
Get-ChildItem -LiteralPath $dir -Filter 'photo_*.jpg' | Where-Object { $_.Name -ne $name } | Remove-Item -Force -ErrorAction SilentlyContinue
