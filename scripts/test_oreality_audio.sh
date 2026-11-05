#!/usr/bin/env bash
#
# Diagnostic script to verify O-Reality Audio and Spatializer status via ADB.
#

set -euo pipefail

echo "============================================================"
echo " Checking ColorOS O-Reality Audio & Spatializer State"
echo "============================================================"

adb shell "
echo '=== SPATIALIZER STATUS IN DUMPSYS AUDIO ==='
dumpsys audio 2>/dev/null | grep -E -A 6 'mHasSpatializerEffect|isSpatializerEnabled|supports binaural' || echo 'dumpsys audio check failed'

echo '=== AUDIO SERVICES ==='
ps -A | grep -iE 'atlasservice|audioserver|android.hardware.audio' || true

echo '=== SOUNDFX AIDL LIBRARIES ==='
ls -l /vendor/lib64/soundfx/libOplus* /odm/lib64/soundfx/libOplus* 2>/dev/null || true
"
echo "============================================================"
