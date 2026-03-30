#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/motorola/cancunf',
    'hardware/mediatek',
    'hardware/mediatek/libaedv',
    'hardware/mediatek/libmtkperf_client',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'vendor.mediatek.hardware.apuware.apusys@2.0',
        'vendor.mediatek.hardware.apuware.apusys@2.1',
        'vendor.mediatek.hardware.apuware.hmp@1.0',
        'vendor.mediatek.hardware.apuware.utils@2.0',
        'libtflite_mtk',
        'libneuron_graph_delegate.mtk'
    ): lib_fixup_vendor_suffix,
}


blob_fixups: blob_fixups_user_type = {
    'system_ext/priv-app/ImsService/ImsService.apk': blob_fixup()
        .apktool_patch('patches/ImsService'),
    'system_ext/priv-app/MtkGbaService/MtkGbaService.apk': blob_fixup()
        .apktool_patch('patches/MtkGbaService'),
    (
        'system_ext/etc/init/init.vtservice.rc',
        'vendor/etc/init/android.hardware.neuralnetworks-shim-service-mtk.rc'
    ): blob_fixup()
        .regex_replace('start', 'enable'),
    'system_ext/lib64/libsource.so': blob_fixup()
        .add_needed('libui_shim.so'),
    (
        'vendor/bin/hw/android.hardware.gnss-service.mediatek',
        'vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so'
    ): blob_fixup()
        .replace_needed('android.hardware.gnss-V1-ndk_platform.so', 'android.hardware.gnss-V1-ndk.so'),
    'vendor/bin/hw/android.hardware.media.c2@1.2-mediatek-64b': blob_fixup()
        .add_needed('libstagefright_foundation-v33.so')
        .replace_needed('libavservices_minijail_vendor.so', 'libavservices_minijail.so'),
    'vendor/bin/hw/android.hardware.security.keymint-service.trustonic': blob_fixup()
        .add_needed('android.hardware.security.rkp-V1-ndk.so')
        .replace_needed('android.hardware.security.keymint-V1-ndk_platform.so', 'android.hardware.security.keymint-V1-ndk.so')
        .replace_needed('android.hardware.security.sharedsecret-V1-ndk_platform.so', 'android.hardware.security.sharedsecret-V1-ndk.so')
        .replace_needed('android.hardware.security.secureclock-V1-ndk_platform.so', 'android.hardware.security.secureclock-V1-ndk.so'),
    (
        'vendor/bin/mnld',
        'vendor/lib64/hw/android.hardware.sensors@2.X-subhal-mediatek.so',
        'vendor/lib64/mt6855/libcam.utils.sensorprovider.so'
    ): blob_fixup()
        .add_needed('android.hardware.sensors@1.0-convert-shared.so'),
    'vendor/lib64/hw/mt6855/vendor.mediatek.hardware.pq@2.15-impl.so': blob_fixup()
        .add_needed('android.hardware.sensors@1.0-convert-shared.so')
        .replace_needed('libutils.so', 'libutils-v32.so'),
    'vendor/lib64/hw/audio.primary.mediatek.so': blob_fixup()
        .add_needed('libstagefright_foundation-v33.so')
        .replace_needed('libutils.so','libutils-v32.so')
        .replace_needed('libalsautils.so','libalsautils-v31.so'),
    (
        'vendor/lib64/hw/mt6855/android.hardware.camera.provider@2.6-impl-mediatek.so',
        'vendor/lib64/mt6855/libmtkcam_stdutils.so',
        'vendor/lib64/sensors.moto.so'
    ): blob_fixup()
        .replace_needed('libutils.so', 'libutils-v32.so')
        .add_needed('libbase_shim.so'),
    (
        'vendor/lib64/mt6855/lib3a.flash.so',
        'vendor/lib64/mt6855/lib3a.ae.stat.so',
        'vendor/lib64/mt6855/lib3a.sensors.flicker.so',
        'vendor/lib64/mt6855/lib3a.sensors.color.so',
        'vendor/lib64/mt6855/libaaa_ltm.so',
        'vendor/lib64/lib3a.ae.pipe.so'
    ): blob_fixup()
        .add_needed('liblog.so'),
    'vendor/lib64/mt6855/libmnl.so': blob_fixup()
        .add_needed('libcutils.so'),
    'vendor/etc/vintf/manifest/manifest_media_c2_V1_2_default.xml': blob_fixup()
        .regex_replace('1.1', '1.2')
        .regex_replace('@1.0', '@1.2')
        .regex_replace('default9', 'default'),
    (
        'vendor/lib64/mt6855/libcam.hal3a.v3.so',
        'vendor/lib64/hw/hwcomposer.mtk_common.so'
    ): blob_fixup()
        .add_needed('libprocessgroup_shim.so'),
    (
        'vendor/lib/mt6855/libneuralnetworks_sl_driver_mtk_prebuilt.so',
        'vendor/lib64/mt6855/libneuralnetworks_sl_driver_mtk_prebuilt.so',
        'vendor/lib64/libstfactory-vendor.so',
        'vendor/lib/libnvram.so',
        'vendor/lib64/libnvram.so',
        'vendor/lib/libsysenv.so',
        'vendor/lib64/libsysenv.so',
        'vendor/lib/libtflite_mtk.so',
        'vendor/lib64/libtflite_mtk.so'
    ): blob_fixup()
        .add_needed('libbase_shim.so'),
    'system_ext/lib64/libimsma.so': blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    'vendor/bin/hw/mtkfusionrild': blob_fixup()
        .add_needed('libutils-v32.so'),
    (
        'vendor/lib64/librt_extamp_intf.so',
        'vendor/lib64/hw/audio.primary.mediatek.so',
        'vendor/lib64/hw/mt6855/vendor.mediatek.hardware.pq@2.15-impl.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-legacy.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'cancunf',
    'motorola',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
