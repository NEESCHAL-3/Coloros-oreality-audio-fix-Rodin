# SELinux Policy Requirements for ColorOS O-Reality Audio

When running with SELinux in **Enforcing** mode (`permissive=0`), `audioserver`, `atlasservice`, and `hal_audio_default` require proper file contexts to read models, parameters, and execute AIDL soundfx libraries.

## 1. File Labels

| File / Directory Path | SELinux Context | Description |
|:---|:---|:---|
| `/vendor/etc/audio_effects_config.xml` | `u:object_r:vendor_configs_file:s0` | Read by `audioserver` during effect discovery |
| `/odm/etc/audio_effects_config.xml` | `u:object_r:vendor_configs_file:s0` | Read by `audioserver` during effect discovery |
| `/vendor/lib64/soundfx/libOplus*` | `u:object_r:vendor_file:s0` | Executed by `audioserver` and `hal_audio_default` |
| `/odm/lib64/soundfx/libOplus*` | `u:object_r:vendor_file:s0` | Executed by `audioserver` and `hal_audio_default` |
| `/odm/etc/spatializer/*` | `u:object_r:vendor_configs_file:s0` | Spatializer room models read by `libOplusSpatializerAidl` |
| `/odm/etc/audio/audiox_param/*` | `u:object_r:vendor_configs_file:s0` | Equalizer and gain maps read by `liboplus_audiox` |
| `/my_product/etc/permissions/*` | `u:object_r:system_file:s0` | Read by `system_server` on boot |

Apply labels manually via:
```bash
chcon u:object_r:vendor_configs_file:s0 /vendor/etc/audio_effects_config.xml /odm/etc/audio_effects_config.xml
chcon u:object_r:vendor_file:s0 /vendor/lib64/soundfx/libOplus* /vendor/lib64/liboplus_audiox.so
chcon -R u:object_r:vendor_configs_file:s0 /odm/etc/spatializer /vendor/etc/spatializer /odm/etc/audio/audiox_param
chcon u:object_r:system_file:s0 /my_product/etc/permissions/oplus.product.features_audiox.xml
```

## 2. Policy Permissions

If `atlasservice` or `audioserver` encounters AVC denials reading the spatializer room models, ensure the following rule is present in `odm_sepolicy.cil` / `vendor_sepolicy.cil`:

```cil
(allow audioserver vendor_configs_file (dir (read open search getattr)))
(allow audioserver vendor_configs_file (file (read open getattr)))
(allow hal_audio_default vendor_configs_file (dir (read open search getattr)))
(allow hal_audio_default vendor_configs_file (file (read open getattr)))
```
