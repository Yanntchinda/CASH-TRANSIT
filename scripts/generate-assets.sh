#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_LOGO="$ROOT_DIR/www/assets/logo.jpg"
HD_LOGO="$ROOT_DIR/resources/logo-hd-transparent.png"
TRANSPARENT_LOGO="$ROOT_DIR/www/assets/logo-transparent.png"

if ! command -v convert >/dev/null 2>&1; then
  echo "Erreur : ImageMagick (convert) est requis pour régénérer les icônes." >&2
  exit 1
fi

if [ ! -f "$SRC_LOGO" ]; then
  echo "Erreur : Logo source introuvable ($SRC_LOGO)" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/resources" "$ROOT_DIR/www/assets"

echo "Génération du logo maître Ultra-HD sans flou (2293x2454)..."
convert "$SRC_LOGO" -filter Lanczos -resize 400% -depth 8 rgb:/tmp/sj_logo4x_sharp.rgb
convert "$SRC_LOGO" -blur 0x1.6 -filter Lanczos -resize 400% -depth 8 rgb:/tmp/sj_logo4x_chroma.rgb
DIMS4=$(convert "$SRC_LOGO" -filter Lanczos -resize 400% -format "%w %h" info:)

python3 - $DIMS4 << 'PYEOF'
import sys

w, h = int(sys.argv[1]), int(sys.argv[2])
sharp = open("/tmp/sj_logo4x_sharp.rgb", "rb").read()
chroma = open("/tmp/sj_logo4x_chroma.rgb", "rb").read()
out = bytearray(w * h * 4)

for i in range(w * h):
    idx = i * 3
    r, g, b = sharp[idx], sharp[idx+1], sharp[idx+2]
    m = min(r, g, b)

    if m >= 180:
        out[i*4:i*4+4] = b"\x00\x00\x00\x00"
        continue
    elif m <= 108:
        alpha = 1.0
    else:
        t = (180.0 - m) / (180.0 - 108.0)
        alpha = t * t * (3.0 - 2.0 * t)

    rc, gc, bc = chroma[idx], chroma[idx+1], chroma[idx+2]
    mc = min(rc, gc, bc)
    cov = max(0.06, min(1.0, (255.0 - mc) / 245.0))
    inv = 255.0 * (1.0 - cov)
    rf = max(0.0, min(255.0, (rc - inv) / cov))
    gf = max(0.0, min(255.0, (gc - inv) / cov))
    bf = max(0.0, min(255.0, (bc - inv) / cov))

    sat = max(rf, gf, bf) - min(rf, gf, bf)
    lum = 0.299 * rf + 0.587 * gf + 0.114 * bf

    if sat < 50 and lum < 95:
        rf, gf, bf = 24.0, 24.0, 26.0
    elif rf > bf + 40 and rf > gf + 40:
        rf, gf, bf = 200.0, 25.0, 34.0
    else:
        gb = gf / max(1.0, bf)
        t_cyan = max(0.0, min(1.0, (gb - 0.635) / (0.675 - 0.635)))
        t_cyan = t_cyan * t_cyan * (3.0 - 2.0 * t_cyan)
        rf = 11.0 * (1.0 - t_cyan) + 0.0 * t_cyan
        gf = 113.0 * (1.0 - t_cyan) + 163.0 * t_cyan
        bf = 190.0 * (1.0 - t_cyan) + 232.0 * t_cyan

    out[i*4] = int(round(rf))
    out[i*4 + 1] = int(round(gf))
    out[i*4 + 2] = int(round(bf))
    out[i*4 + 3] = int(round(alpha * 255.0))

open("/tmp/sj_logo4x_clean.rgba", "wb").write(out)
PYEOF

convert -size "${DIMS4/ /x}" -depth 8 rgba:/tmp/sj_logo4x_clean.rgba -trim +repage \
  -strip -define png:compression-level=9 PNG32:"$HD_LOGO"
rm -f /tmp/sj_logo4x_sharp.rgb /tmp/sj_logo4x_chroma.rgb /tmp/sj_logo4x_clean.rgba

# Logo Retina HD pour la page de connexion Web/PWA (1150x1231)
convert "$HD_LOGO" -filter Lanczos -resize 1150x1250 -strip -define png:compression-level=9 PNG32:"$TRANSPARENT_LOGO"

echo "Génération des ressources maîtresses (resources/ et www/assets/)..."

# Icône carrée principale 1024x1024 sur dégradé horizon (sans canal alpha, compatible Apple App Store)
convert -size 1024x1024 gradient:"#d4e6f9-#f2e4d2" \
  \( "$HD_LOGO" -filter Lanczos -resize 790x790 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/resources/icon-only.png"

# Avant-plan d'icône adaptative Android 1024x1024 (zone de sécurité 66dp respectée)
convert -size 1024x1024 xc:none \
  \( "$HD_LOGO" -filter Lanczos -resize 540x540 \) \
  -gravity center -composite PNG32:"$ROOT_DIR/resources/icon-foreground.png"
convert -size 1024x1024 gradient:"#d4e6f9-#f2e4d2" -alpha off PNG24:"$ROOT_DIR/resources/icon-background.png"

# Splash screen universel 2732x2732 Ultra-HD
convert -size 2732x2732 gradient:"#cbe2f7-#ead7c0" \
  \( "$HD_LOGO" -filter Lanczos -resize 860x860 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/resources/splash.png"
cp "$ROOT_DIR/resources/splash.png" "$ROOT_DIR/resources/splash-dark.png"

# Icônes PWA / Web
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 512x512 -alpha off PNG24:"$ROOT_DIR/www/assets/icon-512.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 192x192 -alpha off PNG24:"$ROOT_DIR/www/assets/icon-192.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 180x180 -alpha off PNG24:"$ROOT_DIR/www/assets/apple-touch-icon.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 64x64 -alpha off PNG24:"$ROOT_DIR/www/assets/favicon.png"
convert -size 512x512 gradient:"#d4e6f9-#f2e4d2" \
  \( "$HD_LOGO" -filter Lanczos -resize 316x316 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/www/assets/icon-maskable-512.png"

# Icônes et Splash Android
ANDROID_RES="$ROOT_DIR/android/app/src/main/res"
if [ -d "$ANDROID_RES" ]; then
  echo "Génération des icônes, splash_logo HD (288dp) et splash screens Android..."
  rm -f "$ANDROID_RES/drawable-v24/ic_launcher_foreground.xml" "$ANDROID_RES/drawable/ic_launcher_background.xml"

  gen_mipmap() {
    local density="$1"
    local launcher_px="$2"
    local fg_px="$3"
    local splash_box_px="$4"
    local logo_round_px=$(( launcher_px * 68 / 100 ))
    local splash_logo_px=$(( splash_box_px * 53 / 100 ))
    local dir="$ANDROID_RES/mipmap-$density"
    local draw_dir="$ANDROID_RES/drawable-$density"
    mkdir -p "$dir" "$draw_dir"

    convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize "${launcher_px}x${launcher_px}" -alpha off PNG24:"$dir/ic_launcher.png"
    convert "$ROOT_DIR/resources/icon-foreground.png" -filter Lanczos -resize "${fg_px}x${fg_px}" PNG32:"$dir/ic_launcher_foreground.png"

    # Logo dédié haute résolution pour Android 12+ Theme.SplashScreen (288dp natif : jusqu'à 1152x1152 px sans aucun étirement !)
    convert -size "${splash_box_px}x${splash_box_px}" xc:none \
      \( "$HD_LOGO" -filter Lanczos -resize "${splash_logo_px}x${splash_logo_px}" \) \
      -gravity center -composite -strip -define png:compression-level=9 PNG32:"$draw_dir/splash_logo.png"

    local half=$(( launcher_px / 2 ))
    convert -size "${launcher_px}x${launcher_px}" gradient:"#d4e6f9-#f2e4d2" \
      \( "$HD_LOGO" -filter Lanczos -resize "${logo_round_px}x${logo_round_px}" \) \
      -gravity center -composite \
      \( -size "${launcher_px}x${launcher_px}" xc:none -fill white -draw "circle ${half},${half} ${half},0" \) \
      -alpha off -compose CopyOpacity -composite PNG32:"$dir/ic_launcher_round.png"
  }

  gen_mipmap "mdpi"    48  288 288
  gen_mipmap "hdpi"    72  432 432
  gen_mipmap "xhdpi"   96  576 576
  gen_mipmap "xxhdpi"  144 864 864
  gen_mipmap "xxxhdpi" 192 1152 1152

  gen_splash() {
    local folder="$1"
    local w="$2"
    local h="$3"
    local min_dim=$(( w < h ? w : h ))
    local logo_sz=$(( min_dim * 50 / 100 ))
    mkdir -p "$ANDROID_RES/$folder"
    convert -size "${w}x${h}" gradient:"#cbe2f7-#ead7c0" \
      \( "$HD_LOGO" -filter Lanczos -resize "${logo_sz}x${logo_sz}" \) \
      -gravity center -composite -alpha off \
      PNG24:"$ANDROID_RES/$folder/splash.png"
  }

  gen_splash "drawable"              1080 1920
  gen_splash "drawable-land-mdpi"    480  320
  gen_splash "drawable-land-hdpi"    800  480
  gen_splash "drawable-land-xhdpi"   1280 720
  gen_splash "drawable-land-xxhdpi"  1920 1080
  gen_splash "drawable-land-xxxhdpi" 2560 1440
  gen_splash "drawable-port-mdpi"    320  480
  gen_splash "drawable-port-hdpi"    480  800
  gen_splash "drawable-port-xhdpi"   720  1280
  gen_splash "drawable-port-xxhdpi"  1080 1920
  gen_splash "drawable-port-xxxhdpi" 1440 2560
fi

# Icône et Splash iOS
IOS_ASSETS="$ROOT_DIR/ios/App/App/Assets.xcassets"
if [ -d "$IOS_ASSETS" ]; then
  echo "Génération des icônes et splash screens iOS..."
  cp "$ROOT_DIR/resources/icon-only.png" "$IOS_ASSETS/AppIcon.appiconset/AppIcon-512@2x.png"
  cp "$ROOT_DIR/resources/splash.png" "$IOS_ASSETS/Splash.imageset/splash-2732x2732.png"
  cp "$ROOT_DIR/resources/splash.png" "$IOS_ASSETS/Splash.imageset/splash-2732x2732-1.png"
  cp "$ROOT_DIR/resources/splash.png" "$IOS_ASSETS/Splash.imageset/splash-2732x2732-2.png"
fi

echo "Toutes les icônes et écrans de démarrage Ultra-HD Saint Jacquet Distribution ont été générés avec succès !"
