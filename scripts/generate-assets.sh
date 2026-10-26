#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_LOGO="$ROOT_DIR/www/assets/logo.jpg"
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

# Génère logo-transparent.png par démixage alpha si absent
if [ ! -f "$TRANSPARENT_LOGO" ]; then
  convert "$SRC_LOGO" -depth 8 rgb:/tmp/sj_logo.rgb
  DIMS=$(identify -format "%w %h" "$SRC_LOGO")
  python3 - $DIMS << 'PYEOF'
import sys
w, h = int(sys.argv[1]), int(sys.argv[2])
rgb = open("/tmp/sj_logo.rgb", "rb").read()
out = bytearray(w * h * 4)
t_bg, t_fg = 242.0, 22.0
span = t_bg - t_fg
for i in range(w * h):
    r, g, b = rgb[i*3], rgb[i*3+1], rgb[i*3+2]
    m = min(r, g, b)
    if m >= t_bg:
        out[i*4:i*4+4] = b"\x00\x00\x00\x00"
    elif m <= t_fg:
        out[i*4:i*4+4] = bytes((r, g, b, 255))
    else:
        a = (t_bg - m) / span
        inv = 255.0 * (1.0 - a)
        out[i*4] = max(0, min(255, int(round((r - inv) / a))))
        out[i*4+1] = max(0, min(255, int(round((g - inv) / a))))
        out[i*4+2] = max(0, min(255, int(round((b - inv) / a))))
        out[i*4+3] = max(0, min(255, int(round(a * 255.0))))
open("/tmp/sj_logo.rgba", "wb").write(out)
PYEOF
  convert -size "${DIMS/ /x}" -depth 8 rgba:/tmp/sj_logo.rgba -trim +repage PNG32:"$TRANSPARENT_LOGO"
  rm -f /tmp/sj_logo.rgb /tmp/sj_logo.rgba
fi

echo "Génération des ressources maîtresses (resources/ et www/assets/)..."

# Icône carrée principale 1024x1024 sur dégradé horizon (sans canal alpha, compatible Apple App Store)
convert -size 1024x1024 gradient:"#d4e6f9-#f2e4d2" \
  \( "$TRANSPARENT_LOGO" -filter Lanczos -resize 780x780 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/resources/icon-only.png"

# Avant-plan d'icône adaptative Android 1024x1024 (zone de sécurité 66dp respectée, zéro halo blanc)
convert -size 1024x1024 xc:none \
  \( "$TRANSPARENT_LOGO" -filter Lanczos -resize 530x530 \) \
  -gravity center -composite PNG32:"$ROOT_DIR/resources/icon-foreground.png"
convert -size 1024x1024 gradient:"#d4e6f9-#f2e4d2" -alpha off PNG24:"$ROOT_DIR/resources/icon-background.png"

# Splash screen universel 2732x2732 sur le nouveau dégradé horizon
convert -size 2732x2732 gradient:"#cbe2f7-#ead7c0" \
  \( "$TRANSPARENT_LOGO" -filter Lanczos -resize 680x680 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/resources/splash.png"
cp "$ROOT_DIR/resources/splash.png" "$ROOT_DIR/resources/splash-dark.png"

# Icônes PWA / Web
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 512x512 -alpha off PNG24:"$ROOT_DIR/www/assets/icon-512.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 192x192 -alpha off PNG24:"$ROOT_DIR/www/assets/icon-192.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 180x180 -alpha off PNG24:"$ROOT_DIR/www/assets/apple-touch-icon.png"
convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize 64x64 -alpha off PNG24:"$ROOT_DIR/www/assets/favicon.png"
convert -size 512x512 gradient:"#d4e6f9-#f2e4d2" \
  \( "$TRANSPARENT_LOGO" -filter Lanczos -resize 310x310 \) \
  -gravity center -composite -alpha off PNG24:"$ROOT_DIR/www/assets/icon-maskable-512.png"

# Icônes et Splash Android
ANDROID_RES="$ROOT_DIR/android/app/src/main/res"
if [ -d "$ANDROID_RES" ]; then
  echo "Génération des icônes et splash screens Android..."
  rm -f "$ANDROID_RES/drawable-v24/ic_launcher_foreground.xml" "$ANDROID_RES/drawable/ic_launcher_background.xml"

  gen_mipmap() {
    local density="$1"
    local launcher_px="$2"
    local fg_px="$3"
    local logo_round_px=$(( launcher_px * 68 / 100 ))
    local dir="$ANDROID_RES/mipmap-$density"
    mkdir -p "$dir"

    convert "$ROOT_DIR/resources/icon-only.png" -filter Lanczos -resize "${launcher_px}x${launcher_px}" -alpha off PNG24:"$dir/ic_launcher.png"
    convert "$ROOT_DIR/resources/icon-foreground.png" -filter Lanczos -resize "${fg_px}x${fg_px}" PNG32:"$dir/ic_launcher_foreground.png"

    local half=$(( launcher_px / 2 ))
    convert -size "${launcher_px}x${launcher_px}" gradient:"#d4e6f9-#f2e4d2" \
      \( "$TRANSPARENT_LOGO" -filter Lanczos -resize "${logo_round_px}x${logo_round_px}" \) \
      -gravity center -composite \
      \( -size "${launcher_px}x${launcher_px}" xc:none -fill white -draw "circle ${half},${half} ${half},0" \) \
      -alpha off -compose CopyOpacity -composite PNG32:"$dir/ic_launcher_round.png"
  }

  gen_mipmap "mdpi"    48  108
  gen_mipmap "hdpi"    72  162
  gen_mipmap "xhdpi"   96  216
  gen_mipmap "xxhdpi"  144 324
  gen_mipmap "xxxhdpi" 192 432

  gen_splash() {
    local folder="$1"
    local w="$2"
    local h="$3"
    local min_dim=$(( w < h ? w : h ))
    local logo_sz=$(( min_dim * 48 / 100 ))
    mkdir -p "$ANDROID_RES/$folder"
    convert -size "${w}x${h}" gradient:"#cbe2f7-#ead7c0" \
      \( "$TRANSPARENT_LOGO" -filter Lanczos -resize "${logo_sz}x${logo_sz}" \) \
      -gravity center -composite -alpha off \
      PNG24:"$ANDROID_RES/$folder/splash.png"
  }

  gen_splash "drawable"              480  320
  gen_splash "drawable-land-mdpi"    480  320
  gen_splash "drawable-land-hdpi"    800  480
  gen_splash "drawable-land-xhdpi"   1280 720
  gen_splash "drawable-land-xxhdpi"  1600 960
  gen_splash "drawable-land-xxxhdpi" 1920 1280
  gen_splash "drawable-port-mdpi"    320  480
  gen_splash "drawable-port-hdpi"    480  800
  gen_splash "drawable-port-xhdpi"   720  1280
  gen_splash "drawable-port-xxhdpi"  960  1600
  gen_splash "drawable-port-xxxhdpi" 1280 1920
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

echo "Toutes les icônes et écrans de démarrage Saint Jacquet Distribution ont été générés avec succès !"
