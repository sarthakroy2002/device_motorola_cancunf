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

endif
