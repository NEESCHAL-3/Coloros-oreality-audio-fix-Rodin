# ColorOS O-Reality Audio Porting Guide (Unpacked Partition Images)

ColorOS ports are prepared by unpacking partition images (`vendor.img`, `odm.img`, `my_product.img`), placing the required audio effect libraries and models into their respective directories, and repacking them with `mkfs.erofs` or `lpmake`.

---

## 1. File Destination Mapping for Unpacked ROM Images

When unpacking your target ROM partition images, place the files into the following exact directories:

### A. Inside Unpacked `my_product.img`:
| Source File | Destination Path Inside Unpacked `my_product` | Permissions | SELinux Context |
|:---|:---|:---|:---|
| `permissions/oplus.product.features_audiox.xml` | `my_product/etc/permissions/oplus.product.features_audiox.xml` | `0644` | `u:object_r:system_file:s0` |
| `permissions/oplus.product.feature_multimedia_unique.xml` | `my_product/etc/permissions/oplus.product.feature_multimedia_unique.xml` | `0644` | `u:object_r:system_file:s0` |

### B. Inside Unpacked `vendor.img`:
| Source File | Destination Path Inside Unpacked `vendor` | Permissions | SELinux Context |
|:---|:---|:---|:---|
| `audio_effects/vendor_audio_effects_config.xml` | `vendor/etc/audio_effects_config.xml` | `0644` | `u:object_r:vendor_configs_file:s0` |
| `soundfx/libOplusAudioxAidl.so` | `vendor/lib64/soundfx/libOplusAudioxAidl.so` | `0644` | `u:object_r:vendor_file:s0` |
| `soundfx/libOplusSpatializerAidl.so` | `vendor/lib64/soundfx/libOplusSpatializerAidl.so` | `0644` | `u:object_r:vendor_file:s0` |
| `soundfx/liboplus_audiox.so` | `vendor/lib64/liboplus_audiox.so` | `0644` | `u:object_r:vendor_file:s0` |
| `spatializer/*` | `vendor/etc/spatializer/` | `0644` | `u:object_r:vendor_configs_file:s0` |
| `audiox_param/*` | `vendor/etc/audio/audiox_param/` | `0644` | `u:object_r:vendor_configs_file:s0` |

### C. Inside Unpacked `odm.img`:
| Source File | Destination Path Inside Unpacked `odm` | Permissions | SELinux Context |
|:---|:---|:---|:---|
| `audio_effects/odm_audio_effects_config.xml` | `odm/etc/audio_effects_config.xml` | `0644` | `u:object_r:vendor_configs_file:s0` |
| `soundfx/libOplusAudioxAidl.so` | `odm/lib64/soundfx/libOplusAudioxAidl.so` | `0644` | `u:object_r:vendor_file:s0` |
| `soundfx/libOplusSpatializerAidl.so` | `odm/lib64/soundfx/libOplusSpatializerAidl.so` | `0644` | `u:object_r:vendor_file:s0` |
| `soundfx/liboplus_audiox.so` | `odm/lib64/liboplus_audiox.so` | `0644` | `u:object_r:vendor_file:s0` |
| `spatializer/*` | `odm/etc/spatializer/` | `0644` | `u:object_r:vendor_configs_file:s0` |
| `audiox_param/*` | `odm/etc/audio/audiox_param/` | `0644` | `u:object_r:vendor_configs_file:s0` |

### D. System Properties:
Append `props/oreality_audio.prop` into `/odm/etc/build.prop` (or `/vendor/build.prop`):
```properties
ro.audio.spatializer_enabled=true
ro.audio.spatializer_type=oplus
ro.oplus.audio.effect.type=audiox_merge
ro.vendor.audio.soundfx.type=audiox
ro.vendor.audio.soundfx.usb=true
persist.vendor.audio.spatializer.enable=true
persist.vendor.audio.misound.disable=true
vendor.audio.useXiaomiSpatializer=false
vendor.audio.spatializer_enable_stereo=true
vendor.audio.spatializer.music_bypass=true
audio.spatializer.pose_predictor_type=1
audio.spatializer.prediction_duration_ms=50
```

---

## 2. Automated Image Baking

To automatically copy all files into an unpacked ROM workspace:
```bash
./scripts/bake_unpacked_images.sh /path/to/unpacked_rom
```

---

## 3. Live Testing on Connected Device (Without Repacking)

1. Deploy via ADB root:
   ```bash
   ./scripts/deploy_partition.sh
   ```
2. Reboot the device:
   ```bash
   adb reboot
   ```
3. Verify live spatializer state:
   ```bash
   ./scripts/test_oreality_audio.sh
   ```
