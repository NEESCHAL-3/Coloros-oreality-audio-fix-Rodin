# ColorOS O-Reality Audio & Spatializer Architecture

This document outlines the architecture, AIDL interfaces, audio effects engine, and acoustic parameter mappings of the ColorOS O-Reality Audio (AudioX) and Spatial Audio suite ported to non-OPPO hardware.

---

## 1. Problem Analysis

When ColorOS is ported from stock OPPO hardware to devices such as POCO X7 Pro (`rodin`), O-Reality Audio is non-functional due to four primary missing links:

1. **Unregistered Audio Effect AIDLs**:
   The vendor audio effects manifest (`audio_effects_config.xml`) lacks definitions for OPPO's AIDL soundfx libraries (`libOplusAudioxAidl.so` and `libOplusSpatializerAidl.so`).
2. **Missing Soundfx Binaries**:
   The 64-bit effect engines (`liboplus_audiox.so`, `libOplusAudioxAidl.so`, `libOplusSpatializerAidl.so`) are not present in `/vendor/lib64/soundfx/` or `/odm/lib64/soundfx/`.
3. **Missing Spatializer Room & Acoustic Models**:
   O-Reality Audio spatialization requires binaural and transaural room impulse response (BRIR/HRIR) models (`SPAT_AUDIOX_ROOMMODEL_*.bin`) and acoustic speaker parameter tuning tables (`PlaybackACF_AudioParam.xml`, `PlaybackDRC_AudioParam.xml`, `SPK_*.bin`). Without them, `audioserver` fails during filter convolution.
4. **Disabled Feature Flags & Conflicting Engines**:
   OEM frameworks check for `oplus.software.audio.audiox_support`. Concurrently, stock Xiaomi firmware attempts to run `misoundfx` and MIUI spatializer, colliding with ColorOS `atlasservice`.

---

## 2. Component Architecture

```
+-------------------------------------------------------------------------+
|                              Android System                             |
|  +--------------------------------+   +------------------------------+  |
|  |     ColorOS Settings / UI      |   |        OplusAtlasService     |  |
|  |    (O-Reality Audio Panel)     |   |       (com.oplus.atlas)      |  |
|  +----------------+---------------+   +--------------+---------------+  |
+-------------------|----------------------------------|------------------+
                    |                                  |
+-------------------|----------------------------------|------------------+
|                   v                                  v                  |
|                                audioserver                              |
|  +-------------------------------------------------------------------+  |
|  |                     AudioFlinger Effect Chains                    |  |
|  |                                                                   |  |
|  |  [Effect 1] oplus_audiox_sw (UUID 41f6c0f4-5d8f-11ec-bf63-...)    |  |
|  |             libOplusAudioxAidl.so -> liboplus_audiox.so           |  |
|  |             - Parametric Equalizer, DRC, ACF                      |  |
|  |                                                                   |  |
|  |  [Effect 2] spatializersw (UUID de4d6aaf-4e9d-473d-8168-...)      |  |
|  |             libOplusSpatializerAidl.so                            |  |
|  |             - Binaural & Transaural Convolution Room Models       |  |
|  |             - Pose Prediction & Dynamic Head Tracking             |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
                    |
+-------------------|-----------------------------------------------------+
|                   v                                                     |
|                               Parameters                                |
|  - /odm/etc/spatializer/*.bin (Room Models & Level Filters)             |
|  - /odm/etc/audio/audiox_param/* (ACF, DRC, Equalizer Maps)             |
+-------------------------------------------------------------------------+
```

---

## 3. AIDL Effect Registration

In `audio_effects_config.xml`:

```xml
<libraries>
    <library name="oplus_audiox_sw" path="libOplusAudioxAidl.so"/>
    <library name="spatializersw" path="libOplusSpatializerAidl.so"/>
</libraries>

<effects>
    <effect name="oplusaudiox" library="oplus_audiox_sw" uuid="41f6c0f4-5d8f-11ec-bf63-0242ac130002" type="41f6c0f4-5d8f-11ec-bf63-0242ac130002"/>
    <effect name="spatializer" library="spatializersw" uuid="de4d6aaf-4e9d-473d-8168-4ce92d50a637"/>
</effects>
```

When audio streams begin playback, `SpatializerHelper` in `audioserver` binds `spatializersw`, queries capabilities, and enables spatial audio routing across stereo speakers and connected Bluetooth/wired headphones.
