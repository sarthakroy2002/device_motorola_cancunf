/*
 * Copyright (C) 2024 The LineageOS Project
 *               2024 Paranoid Android
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "Fingerprint.h"

#include <android-base/properties.h>
#include "util/Util.h"

#include <android-base/logging.h>
#include <android-base/strings.h>

namespace aidl::android::hardware::biometrics::fingerprint {

namespace {
constexpr int MAX_ENROLLMENTS_PER_USER = 5;
constexpr char HW_COMPONENT_ID[] = "fingerprintSensor";
constexpr char HW_VERSION[] = "vendor/model/revision";
constexpr char FW_VERSION[] = "1.01";
constexpr char SERIAL_NUMBER[] = "00000001";
constexpr char SW_COMPONENT_ID[] = "matchingAlgorithm";
constexpr char SW_VERSION[] = "vendor/version/revision";

typedef struct fingerprint_hal {
    const char* class_name;
} fingerprint_hal_t;

static const fingerprint_hal_t kModules[] = {
    {"goodix"},
};

}  // namespace

static const uint16_t kVersion = HARDWARE_MODULE_API_VERSION(2, 1);
static Fingerprint* sInstance;

int Fingerprint::init() {
    sInstance = this;

    if (mDevice) {
        ALOGI("fingerprint HAL already opened");
    } else {
        for (auto& [class_name] : kModules) {
            mDevice = openFingerprintHal(class_name);
            if (!mDevice) {
                ALOGE("Can't open HAL module, class %s", class_name);
                continue;
            }
            ALOGI("Opened fingerprint HAL, class %s", class_name);
            break;
        }
        if (!mDevice) {
            ALOGE("Can't open any fingerprint HAL module");
            return -1;
        }
    }

    mSensorType = FingerprintSensorType::POWER_BUTTON;
    return 0;
}

Fingerprint::~Fingerprint() {
    ALOGV("~Fingerprint()");
    if (mDevice == nullptr) {
        ALOGE("No valid device");
        return;
    }
    int err;
    if (0 != (err = mDevice->common.close(reinterpret_cast<hw_device_t*>(mDevice)))) {
        ALOGE("Can't close fingerprint module, error: %d", err);
        return;
    }
    mDevice = nullptr;
}

fingerprint_device_t* Fingerprint::openFingerprintHal(const char* class_name) {
    const hw_module_t* hw_mdl = nullptr;

    ALOGD("Opening fingerprint hal library...");
    if (hw_get_module_by_class(FINGERPRINT_HARDWARE_MODULE_ID, class_name, &hw_mdl) != 0) {
        ALOGE("Can't open fingerprint HW Module");
        return nullptr;
    }

    if (!hw_mdl) {
        ALOGE("No valid fingerprint module");
        return nullptr;
    }

    auto module = reinterpret_cast<const fingerprint_module_t*>(hw_mdl);
    if (!module->common.methods->open) {
        ALOGE("No valid open method");
        return nullptr;
    }

    hw_device_t* device = nullptr;
    if (module->common.methods->open(hw_mdl, nullptr, &device) != 0) {
        ALOGE("Can't open fingerprint methods");
        return nullptr;
    }

    auto fp_device = reinterpret_cast<fingerprint_device_t*>(device);
    if (fp_device->set_notify(fp_device, Fingerprint::notify) != 0) {
        ALOGE("Can't register fingerprint module callback");
        return nullptr;
    }

    return fp_device;
}

SensorLocation Fingerprint::getSensorLocation() {
    SensorLocation location;

    location = {
        .sensorLocationX = 1080,
        .sensorLocationY = 750,
        .sensorRadius = 200,
        .display = ""
    };

    return location;
}

void Fingerprint::notify(const fingerprint_msg_t* msg) {
    Fingerprint* thisPtr = sInstance;
    if (thisPtr == nullptr || thisPtr->mSession == nullptr || thisPtr->mSession->isClosed()) {
        ALOGE("Receiving callbacks before a session is opened.");
        return;
    }
    thisPtr->mSession->notify(msg);
}

ndk::ScopedAStatus Fingerprint::getSensorProps(std::vector<SensorProps>* out) {
    std::vector<common::ComponentInfo> componentInfo = {
            {HW_COMPONENT_ID, HW_VERSION, FW_VERSION, SERIAL_NUMBER, "" /* softwareVersion */},
            {SW_COMPONENT_ID, "" /* hardwareVersion */, "" /* firmwareVersion */,
             "" /* serialNumber */, SW_VERSION}};
    int32_t sensorId = 0;
    int32_t sensorStrength = 2;
    bool navigationGesture = false;
    bool detectInteraction = false;
    bool displayTouch = false;
    bool controlIllumination = false;

    common::CommonProps commonProps = {sensorId, (common::SensorStrength)sensorStrength,
                                       MAX_ENROLLMENTS_PER_USER, componentInfo};

    SensorLocation sensorLocation = getSensorLocation();

    ALOGI("sensor type: %s, location: %s", ::android::internal::ToString(mSensorType).c_str(),
          sensorLocation.toString().c_str());

    *out = {{commonProps,
             mSensorType,
             {sensorLocation},
             navigationGesture,
             detectInteraction,
             displayTouch,
             controlIllumination,
             std::nullopt}};
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Fingerprint::createSession(int32_t /*sensorId*/, int32_t userId,
                                              const std::shared_ptr<ISessionCallback>& cb,
                                              std::shared_ptr<ISession>* out) {
    CHECK(mSession == nullptr || mSession->isClosed()) << "Open session already exists!";

    mSession = SharedRefBase::make<Session>(mDevice, userId, cb, mLockoutTracker);
    *out = mSession;

    mSession->linkToDeath(cb->asBinder().get());

    return ndk::ScopedAStatus::ok();
}

}  // namespace aidl::android::hardware::biometrics::fingerprint
