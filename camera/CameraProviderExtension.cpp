/*
 * Copyright (C) 2024 LibreMobileOS Foundation
 * Copyright (C) 2025 Yet Another AOSP Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "CameraProviderExtension.h"

#include <android-base/logging.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* For IOCTL definitions */
#include <misc/mediatek/flashlight.h>

#define TORCH_NODE "/dev/flashlight"

int32_t getTorchDefaultStrengthLevelExt() {
    return 2;
}

static int32_t get(int cmd) {
    struct flashlight_user_arg fl;
    int32_t node = open(TORCH_NODE, O_RDWR);
    int32_t ret = 0;

    if (node < 0) {
        LOG(ERROR) << "Failed to open!";
        return -EINVAL;
    }

    /* Common definitions */
    fl.type_id = 1;
    fl.ct_id = 1;

    ret = ioctl(node, cmd, &fl);
    close(node);
    if (ret < 0) {
        LOG(ERROR) << "IOCTL call failed with ret = " << ret;
        return -EINVAL;
    }
    return fl.arg;
}

static void set(int cmd, int32_t value) {
    struct flashlight_user_arg fl;
    int32_t node = open(TORCH_NODE, O_RDWR);
    int32_t ret = 0;

    if (node < 0) {
        LOG(ERROR) << "Failed to open!";
        return;
    }

    /* Common definitions */
    fl.type_id = 1;
    fl.ct_id = 1;

    /* Set arg to whatever value is being sent */
    fl.arg = value;

    ret = ioctl(node, cmd, &fl);
    close(node);
    if (ret < 0) {
        LOG(ERROR) << "IOCTL call failed with ret = " << ret;
        return;
    }
}

bool supportsTorchStrengthControlExt() {
    return true;
}

bool supportsSetTorchModeExt() {
    return false;
}

int32_t getTorchMaxStrengthLevelExt() {
    return get(FLASH_IOC_GET_MAX_TORCH_DUTY);
}

int32_t getTorchStrengthLevelExt() {
    return get(FLASH_IOC_GET_CURRENT_TORCH_DUTY);
}

void setTorchStrengthLevelExt(int32_t torchStrength, bool enabled) {
    /* Set duty first */
    set(FLASH_IOC_SET_DUTY, torchStrength);

    /* Set timeout to 0 to keep it enabled always */
    set(FLASH_IOC_SET_TIME_OUT_TIME_MS, 0);

    /* Set on/off */
    if (enabled)
        set(FLASH_IOC_SET_ONOFF, 1);
}

void setTorchModeExt(bool enabled) {
    int32_t strength = getTorchDefaultStrengthLevelExt();
    setTorchStrengthLevelExt(enabled ? strength : 0, enabled);
}
