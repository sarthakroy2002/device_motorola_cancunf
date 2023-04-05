/*
 * Copyright (C) 2023 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "libpowerhalwrap_vendor"

#include <log/log.h>

int PowerHal_Wrap_mtkPowerHint(int hint, int data)
{
    ALOGD("[%s]: hint:%d, data:%d", __func__, hint, data);
    return 0;
}

int PowerHal_Wrap_mtkCusPowerHint(int hint, int data)
{
    ALOGD("[%s]: hint:%d, data:%d", __func__, hint, data);
    return 0;
}

int PowerHal_Wrap_querySysInfo(unsigned int param, unsigned int data)
{
    ALOGD("[%s]: param:%d, data:%d", __func__, param, data);
    return 0;
}

int64_t PowerHal_Wrap_notifyAppState(const char* pname, const char* aname, unsigned int pid, int status, unsigned int uid)
{
    ALOGD("[%s]: pname:%s, aname:%s, pid:%d, status:%d, uid:%d", __func__, pname, aname, pid, status, uid);
    return 0;
}

int PowerHal_Wrap_scnReg()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_Wrap_scnConfig()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_Wrap_scnUnreg()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_Wrap_scnEnable()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_Wrap_scnDisable()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_Wrap_scnUltraCfg()
{
    ALOGD("%s called", __func__);
    return 0;
}

int PowerHal_TouchBoost(int duration)
{
    ALOGD("[%s]: duration %d", __func__, duration);
    return 0;
}

int PowerHal_Wrap_setSysInfo(int type, const char* data)
{
    ALOGD("[%s]: type: %d, data: %s", __func__, type, data);
    return 0;
}

int PowerHal_Wrap_setSysInfoAsync(int type, const char* data)
{
    ALOGD("[%s]: type: %d, data: %s", __func__, type, data);
    return 0;
}

int PowerHal_Wrap_EnableMultiDisplayMode(int enable, int fps)
{
    ALOGD("[%s]: enable: %d, fps: %d", __func__, enable, fps);
    return 0;
}
