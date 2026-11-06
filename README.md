# ColorOS O-Reality Audio & Spatializer Compatibility Framework

Production-grade compatibility framework to restore and calibrate O-Reality Audio (AudioX) and Spatial Audio on non-OPPO devices ported to ColorOS (Android 15 / ColorOS 15/17).

Specifically structured for ROM porters working with **unpacked partition images** (`vendor.img`, `odm.img`, `my_product.img`) and live on-device testing.

---

## Overview

When ColorOS is ported to third-party devices (such as POCO X7 Pro / Xiaomi `rodin`), O-Reality Audio and Spatializer functionality are non-functional because:
1. Vendor audio effect configuration manifests lack definitions for ColorOS AIDL soundfx libraries (`libOplusAudioxAidl.so`, `libOplusSpatializerAidl.so`).
2. Proprietary room models (`SPAT_AUDIOX_ROOMMODEL_*.bin`) and acoustic parameter tables are absent from `/odm/etc/spatializer/` and `/odm/etc/audio/audiox_param/`.
3. Conflicting vendor spatializers (e.g. Xiaomi misoundfx) collide with `atlasservice` and `audioserver`.

This repository provides the complete, self-contained suite to enable O-Reality Audio and Spatializer processing:
* **Audio Effects Manifests (`audio_effects/`)**: Preconfigured XML manifests for `/vendor/etc/` and `/odm/etc/` registering OPlus AudioX and Spatializer AIDLs.
* **Shared Soundfx Libraries (`soundfx/`)**: 64-bit AIDL effect plugins (`libOplusAudioxAidl.so`, `libOplusSpatializerAidl.so`, `liboplus_audiox.so`).
* **Acoustic & Spatializer Models (`spatializer/` & `audiox_param/`)**: Full suite of binaural/transaural room models, DRC parameters, and ACF equalizer profiles.
* **Feature Permissions & Props (`permissions/` & `props/`)**: OEM feature XMLs and build properties enabling O-Reality Audio and routing spatial audio to stereo speakers and headphones.
* **Automated Tooling (`scripts/`)**: Automated image baking script for unpacked partition trees and direct ADB on-partition installer.

---

## Repository Structure

```
coloros-oreality-audio-fix-Rodin/
├── permissions/
│   ├── oplus.product.features_audiox.xml          # AudioX support permission
│   └── oplus.product.feature_multimedia_unique.xml# Speaker spatializer permission
├── audio_effects/
│   ├── vendor_audio_effects_config.xml            # Vendor audio effects manifest
│   └── odm_audio_effects_config.xml               # ODM audio effects manifest
├── soundfx/
│   ├── libOplusAudioxAidl.so                      # OPlus AudioX AIDL effect plugin
│   ├── libOplusSpatializerAidl.so                 # OPlus Spatializer AIDL effect plugin
│   └── liboplus_audiox.so                         # Core AudioX audio processing engine
├── spatializer/                                   # 22 room impulse response & speaker models
├── audiox_param/                                  # 55 equalizer, DRC, and ACF acoustic tuning profiles
├── props/
│   └── oreality_audio.prop                        # O-Reality & Spatializer system properties
├── scripts/
│   ├── bake_unpacked_images.sh                    # Automated image baker for unpacked partition trees
│   ├── deploy_partition.sh                        # Direct on-partition deployment via ADB
│   └── test_oreality_audio.sh                     # Diagnostic script to verify spatializer state
├── sepolicy/
│   └── README_SEPOLICY.md                         # SELinux contexts and CIL rules for Enforcing mode
├── ARCHITECTURE.md                                # Detailed technical design & AIDL breakdown
├── PORTING_GUIDE.md                               # Step-by-step guide for unpacked partition images
└── LICENSE                                        # Apache 2.0 License
```

---

## Quick Start (Unpacked Partition Images)

To bake O-Reality Audio directly into your unpacked ColorOS ROM directory:

```bash
./scripts/bake_unpacked_images.sh /path/to/unpacked_rom
```

This will automatically populate:
* `my_product/etc/permissions/`
* `vendor/etc/` and `odm/etc/` (audio_effects_config.xml)
* `vendor/lib64/soundfx/` and `odm/lib64/soundfx/`
* `odm/etc/spatializer/` and `vendor/etc/spatializer/`
* `odm/etc/audio/audiox_param/` and `vendor/etc/audio/audiox_param/`
* Append required properties to `odm/etc/build.prop`

---

## Live Testing on Connected Device (Without Repacking)

1. Connect device with ADB root/su authorized.
2. Deploy files to live partitions:
   ```bash
   ./scripts/deploy_partition.sh
   ```
3. Reboot to reload audio policies and `audioserver`:
   ```bash
   adb reboot
   ```
4. Verify active spatializer and audio effect services:
   ```bash
   ./scripts/test_oreality_audio.sh
   ```

---

## Documentation

* Refer to [ARCHITECTURE.md](ARCHITECTURE.md) for technical architecture, effect chain diagrams, and AIDL interface details.
* Refer to [PORTING_GUIDE.md](PORTING_GUIDE.md) for full partition mapping and repacking procedures.
* Refer to [sepolicy/README_SEPOLICY.md](sepolicy/README_SEPOLICY.md) for SELinux Enforcing compliance.

---

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
