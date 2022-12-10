#
# Copyright (C) 2023 ArrowOS
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),cancunf)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
