$root = Get-Location
$pages = Get-ChildItem -Path $root -Filter *.html
foreach ($page in $pages) {
    $path = $page.FullName
    $content = Get-Content -Path $path -Raw

    # Normalize DOCTYPE and html tag
    $content = $content -replace '<!DOCTYPE\s+index\.html>', '<!DOCTYPE html>'
    $content = $content -replace '<!DOCTYPE html>\s*<!DOCTYPE html>', '<!DOCTYPE html>'
    $content = $content -replace '<html>','<html lang="en">'
    $content = $content -replace '<html lang="en">\s*<html lang="en">','<html lang="en">'
    $content = $content -replace '</html>\s*</html>','</html>'

    # Extract existing title or use default
    $titleMatch = [regex]::Match($content, '<title>(.*?)</title>', 'Singleline')
    $pageTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { 'GradLink Hub' }

    # Build the normalized head
    $normalizedHead = @"
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
  <title>$pageTitle</title>
  <link rel=\"stylesheet\" href=\"css/main.css\">
</head>
"@

    if ($content -match '(?s)<head>.*?</head>') {
        $content = [regex]::Replace($content, '(?s)<head>.*?</head>', [regex]::Escape($normalizedHead))
    } else {
        $content = $normalizedHead + "`r`n" + $content
    }

    # Fix script path if needed
    $content = $content -replace 'src=\"script\.js\"', 'src=\"js/script.js\"'

    # Add gallery section only to index.html if missing
    if ($page.Name -eq 'index.html') {
        if ($content -notmatch '<section class=\"gallery\"') {
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
            $content = $content -replace '(?s)(<section class=\"stats\">)', "$gallery$1"
        }
        if ($content -notmatch 'id=\"lightboxOverlay\"') {
            $lightbox = @"
  <div id=\"lightboxOverlay\" class=\"lightbox-overlay\" onclick=\"closeLightbox()\">
    <div class=\"lightbox-content\" onclick=\"event.stopPropagation()\">
      <button class=\"lightbox-close\" onclick=\"closeLightbox()\">×</button>
      <img id=\"lightboxImage\" src=\"\" alt=\"Expanded gallery image\">
      <p id=\"lightboxCaption\"></p>
    </div>
  </div>
"@
            $content = $content -replace '(?s)(</footer>\s*)', "$1$lightbox"
        }
    }

    Set-Content -Path $path -Value $content -Encoding utf8
}

# Add gallery CSS if missing
$cssPath = Join-Path $root 'css\main.css'
$css = Get-Content -Path $cssPath -Raw
if ($css -notmatch '\.gallery\s*\{') {
    $css += "`r`n/* Gallery Lightbox Styles */`r`n.gallery { background: rgba(255,255,255,0.95); padding: 2rem 1.5rem; }`r`n.gallery .container { max-width: 1120px; margin: 0 auto; }`r`n.gallery h2 { margin-bottom: 1.5rem; color: var(--primary); }`r`n.gallery-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); }`r`n.gallery-thumb { width: 100%; height: 250px; object-fit: cover; border-radius: 1rem; cursor: pointer; transition: transform 0.25s ease, box-shadow 0.25s ease; }`r`n.gallery-thumb:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(3,43,100,0.18); }`r`n.lightbox-overlay { position: fixed; inset: 0; display: none; align-items: center; justify-content: center; background: rgba(0,0,0,0.75); z-index: 9999; padding: 1.5rem; }`r`n.lightbox-overlay.active { display:flex; }`r`n.lightbox-content { position: relative; max-width: 900px; width: 100%; background: #fff; border-radius: 1.25rem; overflow: hidden; padding: 1rem; box-shadow: 0 30px 60px rgba(0,0,0,0.25); }`r`n.lightbox-close { position: absolute; top: 1rem; right: 1rem; background: rgba(0,0,0,0.6); color: #fff; border: none; width: 2.5rem; height: 2.5rem; border-radius: 50%; font-size: 1.5rem; cursor: pointer; }`r`n#lightboxImage { width: 100%; height: auto; display: block; border-radius: 0.75rem; }`r`n#lightboxCaption { margin-top: 0.75rem; color: var(--muted); font-size: var(--fs-sm); }"
    Set-Content -Path $cssPath -Value $css -Encoding utf8
}

# Add JS lightbox functions if missing
$jsPath = Join-Path $root 'js\script.js'
$jsContent = Get-Content -Path $jsPath -Raw
if ($jsContent -notmatch 'function openLightbox\(') {
    $jsContent += "`r`n// Gallery lightbox support`r`nfunction openLightbox(img) { const overlay = document.getElementById('lightboxOverlay'); const lightboxImage = document.getElementById('lightboxImage'); const caption = document.getElementById('lightboxCaption'); if (!overlay || !lightboxImage || !caption) return; lightboxImage.src = img.src; caption.textContent = img.alt || 'Gallery image'; overlay.classList.add('active'); }`r`nfunction closeLightbox() { const overlay = document.getElementById('lightboxOverlay'); if (overlay) overlay.classList.remove('active'); }"
    Set-Content -Path $jsPath -Value $jsContent -Encoding utf8
}
