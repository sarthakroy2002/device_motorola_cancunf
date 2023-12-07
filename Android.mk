#
# Copyright (C) 2023 ArrowOS
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),cancunf)
  subdir_makefiles=$(call first-makefiles-under,$(LOCAL_PATH))
  $(foreach mk,$(subdir_makefiles),$(info including $(mk) ...)$(eval include $(mk)))

include $(CLEAR_VARS)

CANCUNF_SYMLINK := $(addprefix $(TARGET_OUT_VENDOR)/, $(strip $(shell cat $(LOCAL_PATH)/symlinks.txt)))
$(CANCUNF_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(dir $@)
	$(hide) ln -sf mt6855/$(notdir $@) $@

ALL_DEFAULT_INSTALLED_MODULES += $(CANCUNF_SYMLINK)

ADDITIONAL_SYMLINKS := \
    $(TARGET_OUT_VENDOR)/lib/hw \
    $(TARGET_OUT_VENDOR)/lib64/hw

$(ADDITIONAL_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@mkdir -p $(TARGET_OUT_VENDOR)/lib/hw
	@mkdir -p $(TARGET_OUT_VENDOR)/lib64/hw
	@ln -sf /vendor/bin/hw/mt6855/android.hardware.graphics.allocator@4.0-service-mediatek.mt6855 $(TARGET_OUT_VENDOR)/bin/hw/android.hardware.graphics.allocator@4.0-service-mediatek
	@ln -sf /vendor/bin/mt6855/v3avpud.mt6855 $(TARGET_OUT_VENDOR)/bin/v3avpud
	$(hide) touch $@

ALL_DEFAULT_INSTALLED_MODULES += $(ADDITIONAL_SYMLINKS)

endif
