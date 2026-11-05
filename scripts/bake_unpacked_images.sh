#!/usr/bin/env bash
#
# ColorOS ROM Porting Tool: Bake O-Reality Audio & Spatializer Fixes into Unpacked Images
#
# Usage:
#   ./scripts/bake_unpacked_images.sh /path/to/unpacked_rom_root
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROM_ROOT="${1:-}"

if [ -z "$ROM_ROOT" ] || [ ! -d "$ROM_ROOT" ]; then
    echo "Usage:"
    echo "  $0 <path_to_unpacked_rom_directory>"
    echo
    echo "Example:"
    echo "  $0 ~/unpacked_coloros"
    exit 1
fi

ROM_ROOT="$(readlink -f "$ROM_ROOT")"

echo "============================================================"
echo " Baking ColorOS O-Reality Audio & Spatializer into Unpacked ROM"
echo " ROM Directory: $ROM_ROOT"
echo "============================================================"

# Resolve partition locations
VENDOR_DIR=""
if [ -d "$ROM_ROOT/vendor" ]; then
    VENDOR_DIR="$ROM_ROOT/vendor"
elif [ -d "$ROM_ROOT/VENDOR" ]; then
    VENDOR_DIR="$ROM_ROOT/VENDOR"
else
    VENDOR_DIR="$ROM_ROOT"
fi

ODM_DIR=""
if [ -d "$ROM_ROOT/odm" ]; then
    ODM_DIR="$ROM_ROOT/odm"
elif [ -d "$ROM_ROOT/ODM" ]; then
    ODM_DIR="$ROM_ROOT/ODM"
else
    ODM_DIR="$VENDOR_DIR"
fi

MY_PRODUCT_DIR=""
if [ -d "$ROM_ROOT/my_product" ]; then
    MY_PRODUCT_DIR="$ROM_ROOT/my_product"
elif [ -d "$ROM_ROOT/MY_PRODUCT" ]; then
    MY_PRODUCT_DIR="$ROM_ROOT/MY_PRODUCT"
elif [ -d "$ROM_ROOT/product" ]; then
    MY_PRODUCT_DIR="$ROM_ROOT/product"
else
    MY_PRODUCT_DIR="$ROM_ROOT"
fi

# 1. Install Feature Permissions
echo "[1/6] Installing OPlus AudioX feature permissions into my_product/etc/permissions/..."
mkdir -p "$MY_PRODUCT_DIR/etc/permissions"
cp -f "$SCRIPT_DIR/permissions/oplus.product.features_audiox.xml" "$MY_PRODUCT_DIR/etc/permissions/"
cp -f "$SCRIPT_DIR/permissions/oplus.product.feature_multimedia_unique.xml" "$MY_PRODUCT_DIR/etc/permissions/"
chmod 0644 "$MY_PRODUCT_DIR/etc/permissions/oplus.product.features_audiox.xml" "$MY_PRODUCT_DIR/etc/permissions/oplus.product.feature_multimedia_unique.xml"
echo "  -> Permissions installed."

# 2. Install Audio Effects Configuration
echo "[2/6] Installing audio_effects_config.xml into vendor/etc/ and odm/etc/..."
mkdir -p "$VENDOR_DIR/etc" "$ODM_DIR/etc"
cp -f "$SCRIPT_DIR/audio_effects/vendor_audio_effects_config.xml" "$VENDOR_DIR/etc/audio_effects_config.xml"
cp -f "$SCRIPT_DIR/audio_effects/odm_audio_effects_config.xml" "$ODM_DIR/etc/audio_effects_config.xml"
chmod 0644 "$VENDOR_DIR/etc/audio_effects_config.xml" "$ODM_DIR/etc/audio_effects_config.xml"
echo "  -> Audio effects configuration installed."

# 3. Install Soundfx Libraries
echo "[3/6] Installing OPlus AudioX & Spatializer AIDL shared libraries..."
mkdir -p "$VENDOR_DIR/lib64/soundfx" "$VENDOR_DIR/lib64"
mkdir -p "$ODM_DIR/lib64/soundfx" "$ODM_DIR/lib64"

cp -f "$SCRIPT_DIR/soundfx/libOplusAudioxAidl.so" "$VENDOR_DIR/lib64/soundfx/"
cp -f "$SCRIPT_DIR/soundfx/libOplusSpatializerAidl.so" "$VENDOR_DIR/lib64/soundfx/"
cp -f "$SCRIPT_DIR/soundfx/liboplus_audiox.so" "$VENDOR_DIR/lib64/"

cp -f "$SCRIPT_DIR/soundfx/libOplusAudioxAidl.so" "$ODM_DIR/lib64/soundfx/"
cp -f "$SCRIPT_DIR/soundfx/libOplusSpatializerAidl.so" "$ODM_DIR/lib64/soundfx/"
cp -f "$SCRIPT_DIR/soundfx/liboplus_audiox.so" "$ODM_DIR/lib64/"

chmod 0644 "$VENDOR_DIR/lib64/soundfx/"*.so "$VENDOR_DIR/lib64/liboplus_audiox.so"
chmod 0644 "$ODM_DIR/lib64/soundfx/"*.so "$ODM_DIR/lib64/liboplus_audiox.so"
echo "  -> Shared libraries installed."

# 4. Install Spatializer Room Models
echo "[4/6] Installing spatializer room models..."
mkdir -p "$ODM_DIR/etc/spatializer" "$VENDOR_DIR/etc/spatializer"
cp -rf "$SCRIPT_DIR/spatializer/"* "$ODM_DIR/etc/spatializer/"
cp -rf "$SCRIPT_DIR/spatializer/"* "$VENDOR_DIR/etc/spatializer/"
chmod -R 0644 "$ODM_DIR/etc/spatializer/"* "$VENDOR_DIR/etc/spatializer/"*
echo "  -> Spatializer models installed."

# 5. Install AudioX Acoustic Profiles
echo "[5/6] Installing AudioX acoustic tuning parameters..."
mkdir -p "$ODM_DIR/etc/audio/audiox_param" "$VENDOR_DIR/etc/audio/audiox_param"
cp -rf "$SCRIPT_DIR/audiox_param/"* "$ODM_DIR/etc/audio/audiox_param/"
cp -rf "$SCRIPT_DIR/audiox_param/"* "$VENDOR_DIR/etc/audio/audiox_param/"
chmod -R 0644 "$ODM_DIR/etc/audio/audiox_param/"* "$VENDOR_DIR/etc/audio/audiox_param/"*
echo "  -> AudioX tuning parameters installed."

# 6. Append System Properties
echo "[6/6] Injecting O-Reality & Spatializer system properties..."
PROP_SRC="$SCRIPT_DIR/props/oreality_audio.prop"
TARGET_PROP=""
if [ -d "$ROM_ROOT/odm" ] && [ -f "$ROM_ROOT/odm/etc/build.prop" ]; then
    TARGET_PROP="$ROM_ROOT/odm/etc/build.prop"
elif [ -f "$VENDOR_DIR/build.prop" ]; then
    TARGET_PROP="$VENDOR_DIR/build.prop"
fi

if [ -n "$TARGET_PROP" ] && [ -f "$PROP_SRC" ]; then
    echo "" >> "$TARGET_PROP"
    echo "# ColorOS O-Reality Audio & Spatializer Properties" >> "$TARGET_PROP"
    cat "$PROP_SRC" >> "$TARGET_PROP"
    echo "  -> Properties injected into $TARGET_PROP"
fi

echo "============================================================"
echo " O-Reality Audio & Spatializer successfully baked into unpacked ROM."
echo "============================================================"
