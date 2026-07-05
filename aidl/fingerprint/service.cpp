/*
 * Copyright (C) 2024 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "Fingerprint.h"

#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>
#include <cutils/properties.h>

using ::aidl::android::hardware::biometrics::fingerprint::Fingerprint;

int main() {
    LOG(INFO) << "Opening fingerprint HAL library...";

    ABinderProcess_setThreadPoolMaxThreadCount(0);

    // Create fingerprint service
    auto fingerprint = ndk::SharedRefBase::make<Fingerprint>();

    if (fingerprint != nullptr) {
        if (fingerprint->init() == 0) {
            LOG(INFO) << "Finish to initialize fingerprint HAL module.";

            const std::string instance =
                    std::string(Fingerprint::descriptor) + "/default";

            binder_status_t status =
                    AServiceManager_addService(fingerprint->asBinder().get(),
                                               instance.c_str());

            if (status == STATUS_OK) {
                LOG(INFO) << "Finish to register as service.";
                property_set("vendor.hw.fingerprint.status", "ok");
            } else {
                LOG(ERROR) << "Failed to register fingerprint service.";
                property_set("vendor.hw.fingerprint.status", "fail");
                return EXIT_FAILURE;
            }
        } else {
            LOG(ERROR) << "Can't initialize fingerprint HAL module.";
            property_set("vendor.hw.fingerprint.status", "fail");
            return EXIT_FAILURE;
        }
    } else {
        LOG(ERROR) << "Can't create Fingerprint instance.";
        property_set("vendor.hw.fingerprint.status", "fail");
        return EXIT_FAILURE;
    }

    ABinderProcess_joinThreadPool();

    return EXIT_FAILURE; // Should never reach here
}
