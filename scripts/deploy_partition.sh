#!/usr/bin/env bash
#
# Automated deployment script for on-partition installation of O-Reality Audio.
# Deploys configurations, soundfx libraries, models, and properties via ADB root.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================"
echo " Deploying ColorOS O-Reality Audio & Spatializer Fixes"
echo "============================================================"

# Check ADB root / su
if ! adb shell "su -c 'id'" >/dev/null 2>&1; then
    echo "ERROR: Root access (su) via ADB is required for on-partition deployment."
    exit 2
fi

# Remount partitions and apply files
echo "[1/4] Remounting partitions rw and pushing files..."
adb shell "su -c '
set -e
mount -o remount,rw /vendor
mount -o remount,rw /odm
mount -o remount,rw /my_product 2>/dev/null || true
'"

# Push permissions
adb push "$SCRIPT_DIR/permissions/." "/my_product/etc/permissions/"
adb shell "su -c 'chmod 0644 /my_product/etc/permissions/oplus.product.features_audiox.xml /my_product/etc/permissions/oplus.product.feature_multimedia_unique.xml && chcon u:object_r:system_file:s0 /my_product/etc/permissions/oplus.product.features_audiox.xml'"

# Push audio_effects configs
adb push "$SCRIPT_DIR/audio_effects/vendor_audio_effects_config.xml" "/vendor/etc/audio_effects_config.xml"
adb push "$SCRIPT_DIR/audio_effects/odm_audio_effects_config.xml" "/odm/etc/audio_effects_config.xml"
adb shell "su -c 'chmod 0644 /vendor/etc/audio_effects_config.xml /odm/etc/audio_effects_config.xml && chcon u:object_r:vendor_configs_file:s0 /vendor/etc/audio_effects_config.xml /odm/etc/audio_effects_config.xml'"

# Push libraries
adb push "$SCRIPT_DIR/soundfx/libOplusAudioxAidl.so" "/vendor/lib64/soundfx/"
adb push "$SCRIPT_DIR/soundfx/libOplusSpatializerAidl.so" "/vendor/lib64/soundfx/"
adb push "$SCRIPT_DIR/soundfx/liboplus_audiox.so" "/vendor/lib64/"
adb push "$SCRIPT_DIR/soundfx/libOplusAudioxAidl.so" "/odm/lib64/soundfx/"
adb push "$SCRIPT_DIR/soundfx/libOplusSpatializerAidl.so" "/odm/lib64/soundfx/"
adb push "$SCRIPT_DIR/soundfx/liboplus_audiox.so" "/odm/lib64/"

adb shell "su -c '
chmod 0644 /vendor/lib64/soundfx/*.so /vendor/lib64/liboplus_audiox.so /odm/lib64/soundfx/*.so /odm/lib64/liboplus_audiox.so
chcon u:object_r:vendor_file:s0 /vendor/lib64/soundfx/*.so /vendor/lib64/liboplus_audiox.so /odm/lib64/soundfx/*.so /odm/lib64/liboplus_audiox.so
'"

# Push spatializer models & audiox_param
echo "[2/4] Pushing spatializer models and acoustic profiles..."
adb push "$SCRIPT_DIR/spatializer/." "/odm/etc/spatializer/"
adb push "$SCRIPT_DIR/spatializer/." "/vendor/etc/spatializer/"
adb push "$SCRIPT_DIR/audiox_param/." "/odm/etc/audio/audiox_param/"
adb push "$SCRIPT_DIR/audiox_param/." "/vendor/etc/audio/audiox_param/"

adb shell "su -c '
chmod -R 0644 /odm/etc/spatializer/* /vendor/etc/spatializer/* /odm/etc/audio/audiox_param/* /vendor/etc/audio/audiox_param/*
chcon -R u:object_r:vendor_configs_file:s0 /odm/etc/spatializer /vendor/etc/spatializer /odm/etc/audio/audiox_param /vendor/etc/audio/audiox_param
sync
'"

echo "[3/4] Restarting audioserver and atlasservice..."
adb shell "su -c '
pkill -f audioserver || true
pkill -f atlasservice || true
pkill -f android.hardware.audio.service || true
'"

echo "[4/4] Deployment complete. To ensure all audio policies reload, reboot:"
echo "  adb reboot"
echo "============================================================"
