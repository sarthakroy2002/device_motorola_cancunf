/*
 * Copyright (c) 2015 The CyanogenMod Project
 * Copyright (c) 2017-2022 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.lineageos.settings.device;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.SystemProperties;
import android.os.UserHandle;
import android.util.Log;
import org.lineageos.settings.device.actions.TapGestureSettings;

public class BootCompletedReceiver extends BroadcastReceiver {
    private static final String TAG = "MotoActions";

    @Override
    public void onReceive(final Context context, Intent intent) {
        Log.i(TAG, "Booting");
        TapGestureSettings.MainSettingsFragment.restoreTapGestureStates(context);
        context.startServiceAsUser(new Intent(context, MotoActionsService.class),
                UserHandle.CURRENT);
        felicaDisabler(context);
    }

    private void felicaDisabler(Context context) {
        String sku = SystemProperties.get("ro.boot.hardware.sku", "");
        boolean isJapaneseVariant = "XT2431-2".equals(sku) || "XT2431-3".equals(sku);
        int flag = isJapaneseVariant ?
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED :
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED;

        context.getPackageManager().setApplicationEnabledSetting("com.felicanetworks.mfc", flag, 0);
    }
}
