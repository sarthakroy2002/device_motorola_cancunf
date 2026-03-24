#
# SPDX-FileCopyrightText: PixelOS
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
TARGET_SUPPORTS_OMX_SERVICE := false

# Inherit from device makefile.
$(call inherit-product, device/motorola/cancunf/device.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/custom/config/common_full_phone.mk)
TARGET_SCREEN_WIDTH := 1080

PRODUCT_NAME := custom_cancunf
PRODUCT_DEVICE := cancunf
PRODUCT_MANUFACTURER := motorola
PRODUCT_BRAND := motorola
PRODUCT_MODEL := moto g54 5G

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    DeviceName=cancunf \
    BuildDesc="cancunf_g_sys-user 15 V1TDS35H.83-20-5-7 bdec4-36ecc release-keys" \
    BuildFingerprint=motorola/cancunf_g_sys/cancunf:15/V1TDS35H.83-20-5-7/bdec4-36ecc:user/release-keys
