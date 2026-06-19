$root = Get-Location
$pages = Get-ChildItem -Path $root -Filter *.html
foreach ($page in $pages) {
    $path = $page.FullName
    $content = Get-Content -Path $path -Raw
    
    # normalize DOCTYPE and html
    $content = $content -replace '<!DOCTYPE\s+index\.html>', '<!DOCTYPE html>'
    $content = $content -replace '<!DOCTYPE html>\s*<!DOCTYPE html>', '<!DOCTYPE html>'
    $content = $content -replace '<html>','<html lang="en">'
    $content = $content -replace '<html lang="en">\s*<html lang="en">','<html lang="en">'
    $content = $content -replace '</html>\s*</html>','</html>'

    # determine page title
    $titleMatch = [regex]::Match($content, '<title>(.*?)</title>', 'Singleline')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { 'GradLink Hub' }

    # build head
    $head = @"
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <meta name=\"description\" content=\"GradLink Hub connects graduates with jobs, skills, and mentorship in South Africa.\">
  <meta name=\"keywords\" content=\"graduate jobs, student careers, South Africa jobs, skill development, mentorship\">
  <meta name=\"robots\" content=\"index, follow\">
  <meta property=\"og:title\" content=\"GradLink Hub\">
  <meta property=\"og:description\" content=\"GradLink Hub connects graduates with jobs, skills, and mentorship in South Africa.\">
  <meta property=\"og:type\" content=\"website\">
  <meta property=\"og:url\" content=\"https://example.com/\">
  <meta property=\"og:image\" content=\"https://source.unsplash.com/featured/?students,career\">
  <meta name=\"twitter:card\" content=\"summary_large_image\">
  <meta name=\"twitter:title\" content=\"GradLink Hub\">
  <meta name=\"twitter:description\" content=\"GradLink Hub connects graduates with jobs, skills, and mentorship in South Africa.\">
  <meta name=\"twitter:image\" content=\"https://source.unsplash.com/featured/?students,career\">
  <title>$title</title>
  <link rel=\"stylesheet\" href=\"css/main.css\">
</head>
"@

    if ($content -match '(?s)<head>.*?</head>') {
        $content = [regex]::Replace($content, '(?s)<head>.*?</head>', [regex]::Escape($head))
    } else {
        $content = $head + "`r`n" + $content
    }

    # ensure external JS path
    $content = $content -replace 'src=\"script\.js\"', 'src=\"js/script.js\"'

    Set-Content -Path $path -Value $content -Encoding utf8
}

# Add homepage gallery and lightbox markup
$indexPath = Join-Path $root 'index.html'
$index = Get-Content -Path $indexPath -Raw
if ($index -notmatch '<section class=\"gallery\"') {
    $gallery = @"
  <section class=\"gallery\">
    <div class=\"container\">
      <h2>Gallery</h2>
      <div class=\"gallery-grid\">
        <img src=\"https://source.unsplash.com/featured/?graduation\" alt=\"Graduation success\" class=\"gallery-thumb\" onclick=\"openLightbox(this)\">
        <img src=\"https://source.unsplash.com/featured/?students\" alt=\"Students learning\" class=\"gallery-thumb\" onclick=\"openLightbox(this)\">
        <img src=\"https://source.unsplash.com/featured/?career\" alt=\"Career guidance\" class=\"gallery-thumb\" onclick=\"openLightbox(this)\">
        <img src=\"https://source.unsplash.com/featured/?mentor\" alt=\"Mentorship session\" class=\"gallery-thumb\" onclick=\"openLightbox(this)\">
      </div>
    </div>
  </section>
"@
    $index = $index -replace '(?s)(<section class=\"stats\">)', "$gallery$1"
}
if ($index -notmatch 'id=\"lightboxOverlay\"') {
    $lightbox = @"
  <div id=\"lightboxOverlay\" class=\"lightbox-overlay\" onclick=\"closeLightbox()\">
    <div class=\"lightbox-content\" onclick=\"event.stopPropagation()\">
      <button class=\"lightbox-close\" onclick=\"closeLightbox()\">×</button>
      <img id=\"lightboxImage\" src=\"\" alt=\"Expanded gallery image\">
      <p id=\"lightboxCaption\"></p>
    </div>
  </div>
"@
    $index = $index -replace '(?s)(</footer>\s*)', "$1$lightbox"
}
Set-Content -Path $indexPath -Value $index -Encoding utf8

# Add CSS styles if missing
$cssPath = Join-Path $root 'css\main.css'
$css = Get-Content -Path $cssPath -Raw
if ($css -notmatch '\.gallery\s*\{') {
    $css += "`r`n/* Gallery Lightbox Styles */`r`n.gallery { background: rgba(255,255,255,0.95); padding: 2rem 1.5rem; }`r`n.gallery .container { max-width: 1120px; margin: 0 auto; }`r`n.gallery h2 { margin-bottom: 1.5rem; color: var(--primary); }`r`n.gallery-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); }`r`n.gallery-thumb { width: 100%; height: 250px; object-fit: cover; border-radius: 1rem; cursor: pointer; transition: transform 0.25s ease, box-shadow 0.25s ease; }`r`n.gallery-thumb:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(3,43,100,0.18); }`r`n.lightbox-overlay { position: fixed; inset: 0; display: none; align-items: center; justify-content: center; background: rgba(0,0,0,0.75); z-index: 9999; padding: 1.5rem; }`r`n.lightbox-overlay.active { display:flex; }`r`n.lightbox-content { position: relative; max-width: 900px; width: 100%; background: #fff; border-radius: 1.25rem; overflow: hidden; padding: 1rem; box-shadow: 0 30px 60px rgba(0,0,0,0.25); }`r`n.lightbox-close { position: absolute; top: 1rem; right: 1rem; background: rgba(0,0,0,0.6); color: #fff; border: none; width: 2.5rem; height: 2.5rem; border-radius: 50%; font-size: 1.5rem; cursor: pointer; }`r`n#lightboxImage { width: 100%; height: auto; display: block; border-radius: 0.75rem; }`r`n#lightboxCaption { margin-top: 0.75rem; color: var(--muted); font-size: var(--fs-sm); }"
    Set-Content -Path $cssPath -Value $css -Encoding utf8
}

# Add JS functions if missing
$jsPath = Join-Path $root 'js\script.js'
$js = Get-Content -Path $jsPath -Raw
if ($js -notmatch 'function openLightbox\(') {
    $js += "`r`n// Gallery lightbox support`r`nfunction openLightbox(img) { const overlay = document.getElementById('lightboxOverlay'); const lightboxImage = document.getElementById('lightboxImage'); const caption = document.getElementById('lightboxCaption'); if (!overlay || !lightboxImage || !caption) return; lightboxImage.src = img.src; caption.textContent = img.alt || 'Gallery image'; overlay.classList.add('active'); }`r`nfunction closeLightbox() { const overlay = document.getElementById('lightboxOverlay'); if (overlay) overlay.classList.remove('active'); }"
    Set-Content -Path $jsPath -Value $js -Encoding utf8
}

# Ensure documents folder exists
$docsPath = Join-Path $root 'documents'
if (-not (Test-Path $docsPath)) { New-Item -ItemType Directory -Path $docsPath | Out-Null }

# Create a simple PDF document
$pdfPath = Join-Path $docsPath 'Part 2 improvements.pdf'
$stream = [System.Text.Encoding]::ASCII.GetBytes('%PDF-1.4`r`n1 0 obj`r`n<< /Type /Catalog /Pages 2 0 R >>`r`nendobj`r`n2 0 obj`r`n<< /Type /Pages /Kids [3 0 R] /Count 1 >>`r`nendobj`r`n3 0 obj`r`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>`r`nendobj`r`n4 0 obj`r`n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>`r`nendobj`r`n5 0 obj`r`n<< /Length 202 >>`r`nstream`r
BT`r
/F1 18 Tf`r
72 740 Td`r
(Part 2 improvements) Tj`r
0 -28 Td`r
/F1 12 Tf`r
(External JavaScript file added under js/script.js.) Tj`r
0 -16 Td`r
(SEO metadata added to all pages.) Tj`r
0 -16 Td`r
(Gallery lightbox added to the homepage.) Tj`r
0 -16 Td`r
(Documents folder contains this PDF.) Tj`r
ET`r
endstream`r
endobj`r
xref`r
0 6`r
0000000000 65535 f `r
0000000010 00000 n `r
0000000061 00000 n `r
0000000118 00000 n `r
0000000199 00000 n `r
0000000284 00000 n `r
trailer`r
<< /Size 6 /Root 1 0 R >>`r
startxref`r
378`r
%%EOF`r
')
[System.IO.File]::WriteAllBytes($pdfPath, $stream)
