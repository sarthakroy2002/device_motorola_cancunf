/*
 * Copyright (c) 2016 The CyanogenMod Project
 * Copyright (c) 2017-2024 The LineageOS Project
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

import android.os.Bundle;

import androidx.preference.ListPreference;
import androidx.preference.Preference;
import androidx.preference.Preference.OnPreferenceChangeListener;
import androidx.preference.PreferenceFragment;
import androidx.preference.PreferenceManager;

import com.android.settingslib.widget.MainSwitchPreference;

import android.util.Log;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;

public class TurboChargingFragment extends PreferenceFragment {

    private static final String TAG = "TurboChargingFragment";
    private static final String PRIMARY_CHARGE_CURRENT_FILE = "/sys/devices/platform/soc/soc:odm/soc:odm:mmi_chrg_manager/power_supply/mmi_chrg_manager/constant_charge_current_max";
    private static final String ALTERNATE_CHARGE_CURRENT_FILE = "/sys/devices/platform/charger/power_supply/mtk-master-charger/constant_charge_current_max";
    private String CHARGE_CURRENT_FILE;
    private boolean turboEnabled;

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        addPreferencesFromResource(R.xml.charging_panel);

        CheckChargeCurrentFile();

        MainSwitchPreference switchPreference = findPreference("turbo_enable");
        if (switchPreference != null) {
            switchPreference.setOnPreferenceChangeListener((preference, newValue) -> {
                boolean turboEnabled = (Boolean) newValue;
                PreferenceManager.getDefaultSharedPreferences(getActivity())
                        .edit()
                        .putBoolean("turbo_enable", turboEnabled)
                        .apply();

                updateChargeCurrent();
                return true;
            });
        }

        ListPreference listPreference = findPreference("turbo_current");
        if (listPreference != null) {
            listPreference.setOnPreferenceChangeListener((preference, newValue) -> {
                String currentValue = (String) newValue;
                PreferenceManager.getDefaultSharedPreferences(getActivity())
                        .edit()
                        .putString("turbo_current", currentValue)
                        .apply();

                updateChargeCurrent();
                return true;
            });
        }
    }

    private void CheckChargeCurrentFile() {
        File primaryFile = new File(PRIMARY_CHARGE_CURRENT_FILE);
        if (primaryFile.exists()) {
            CHARGE_CURRENT_FILE = PRIMARY_CHARGE_CURRENT_FILE;
        } else {
            CHARGE_CURRENT_FILE = ALTERNATE_CHARGE_CURRENT_FILE;
            ListPreference turboCurrentPreference = findPreference("turbo_current");
            if (turboCurrentPreference != null) {
                turboCurrentPreference.setVisible(false);
            }
        }
        Log.i(TAG, "Using charge current file: " + CHARGE_CURRENT_FILE);
    }

    private void updateChargeCurrent() {
        turboEnabled = PreferenceManager.getDefaultSharedPreferences(getActivity()).getBoolean("turbo_enable", false);
        Log.i(TAG, "isTurbo=" + turboEnabled);
        String defaultValue = "3000000";
        String currentValue;
        if (turboEnabled) {
            if (CHARGE_CURRENT_FILE == PRIMARY_CHARGE_CURRENT_FILE) {
                currentValue = PreferenceManager.getDefaultSharedPreferences(getActivity()).getString("turbo_current", "5000000");
            } else {
                currentValue = defaultValue;
            }
            Log.i(TAG, "currentValue=" + currentValue);
            writeChargeCurrent(currentValue);
        } else {
            writeChargeCurrent(defaultValue);
        }
    }

    private void writeChargeCurrent(String value) {
        try {
            Integer.parseInt(value);
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(CHARGE_CURRENT_FILE))) {
                writer.write(value);
                Log.i(TAG, "Updated Charging current to " + value);
            }
        } catch (NumberFormatException e) {
            Log.e(TAG, "Invalid charge current value: " + value, e);
        } catch (IOException e) {
            Log.e(TAG, "Failed to update charge current", e);
        }
    }
}
