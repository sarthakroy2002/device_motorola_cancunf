#
# Copyright (C) 2024 ArrowOS
# Copyright (C) 2024 PixelOS
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)
SYMLINK_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),cancunf)
  subdir_makefiles=$(call first-makefiles-under,$(LOCAL_PATH))
  $(foreach mk,$(subdir_makefiles),$(info including $(mk) ...)$(eval include $(mk)))

include $(CLEAR_VARS)

CANCUNF_SYMLINK := $(addprefix $(TARGET_OUT_VENDOR)/, $(strip $(shell cat $(SYMLINK_PATH)/symlinks.txt)))
$(CANCUNF_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf mt6855/$(notdir $@) $@

ALL_DEFAULT_INSTALLED_MODULES += $(CANCUNF_SYMLINK)

AUDIO_PRIMARY_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/audio.primary.mt6855.so
$(AUDIO_PRIMARY_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf audio.primary.mediatek.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(AUDIO_PRIMARY_SYMLINK)

AUDIO_SUBMIX_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/audio.r_submix.mt6855.so
$(AUDIO_SUBMIX_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf audio.r_submix.mediatek.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(AUDIO_SUBMIX_SYMLINK)

GATEKEEPER_DEFAULT_SYMLINK += $(TARGET_OUT_VENDOR)/lib/hw/gatekeeper.default.so
GATEKEEPER_DEFAULT_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/gatekeeper.default.so
$(GATEKEEPER_DEFAULT_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf libSoftGatekeeper.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(GATEKEEPER_DEFAULT_SYMLINK)

GATEKEEPER_TRUSTONIC_SYMLINK += $(TARGET_OUT_VENDOR)/lib/hw/gatekeeper.trustonic.so
GATEKEEPER_TRUSTONIC_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/gatekeeper.trustonic.so
$(GATEKEEPER_TRUSTONIC_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf libMcGatekeeper.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(GATEKEEPER_TRUSTONIC_SYMLINK)

GRAPHICS_SYMLINK += $(TARGET_OUT_VENDOR)/bin/hw/android.hardware.graphics.allocator@4.0-service-mediatek
$(GRAPHICS_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf mt6855/android.hardware.graphics.allocator@4.0-service-mediatek.mt6855 $@

ALL_DEFAULT_INSTALLED_MODULES += $(GRAPHICS_SYMLINK)

KMSETKEY_SYMLINK += $(TARGET_OUT_VENDOR)/lib/hw/kmsetkey.default.so
KMSETKEY_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/kmsetkey.default.so
$(KMSETKEY_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf kmsetkey.trustonic.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(KMSETKEY_SYMLINK)

SENSORS_SYMLINK += $(TARGET_OUT_VENDOR)/lib64/hw/sensors.mt6855.so
$(SENSORS_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf sensors.mediatek.V2.0.so $@

ALL_DEFAULT_INSTALLED_MODULES += $(SENSORS_SYMLINK)

VPUD_SYMLINK += $(TARGET_OUT_VENDOR)/bin/v3avpud
$(VPUD_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf mt6855/v3avpud.mt6855 $@

ALL_DEFAULT_INSTALLED_MODULES += $(VPUD_SYMLINK)

endif
