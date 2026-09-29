/*
 * Copyright (C) 2015 The CyanogenMod Project
 * Copyright (C) 2017-2024 The LineageOS Project
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

import android.app.Activity;
import android.app.Dialog;
import android.content.SharedPreferences;
import android.os.Bundle;

import androidx.preference.Preference;
import androidx.preference.PreferenceCategory;
import androidx.preference.SwitchPreferenceCompat;

import com.android.settingslib.widget.MainSwitchPreference;
import com.android.settingslib.widget.SettingsBasePreferenceFragment;

public class DozePreferenceFragment extends SettingsBasePreferenceFragment
        implements Preference.OnPreferenceChangeListener {

    private SwitchPreferenceCompat mAlwaysOnDisplayPreference;

    private SwitchPreferenceCompat mHandwavePreference;
    private SwitchPreferenceCompat mPickUpPreference;
    private SwitchPreferenceCompat mPocketPreference;

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.doze_panel, rootKey);

        boolean dozeEnabled = MotoActionsSettings.isDozeEnabled(getActivity());

        MainSwitchPreference switchBar = findPreference(MotoActionsSettings.DOZE_ENABLE);
        switchBar.setOnPreferenceChangeListener(this);
        switchBar.setChecked(dozeEnabled);

        mAlwaysOnDisplayPreference = findPreference(MotoActionsSettings.ALWAYS_ON_DISPLAY);
        mAlwaysOnDisplayPreference.setEnabled(dozeEnabled);
        mAlwaysOnDisplayPreference.setChecked(MotoActionsSettings.isAlwaysOnEnabled(getActivity()));
        mAlwaysOnDisplayPreference.setOnPreferenceChangeListener(this);

        mHandwavePreference = findPreference(MotoActionsSettings.GESTURE_IR_WAKEUP_KEY);
        mHandwavePreference.setEnabled(dozeEnabled);
        mHandwavePreference.setOnPreferenceChangeListener(this);

        mPickUpPreference = findPreference(MotoActionsSettings.GESTURE_PICK_UP_KEY);
        mPickUpPreference.setEnabled(dozeEnabled);
        mPickUpPreference.setOnPreferenceChangeListener(this);

        mPocketPreference = findPreference(MotoActionsSettings.GESTURE_POCKET_KEY);
        mPocketPreference.setEnabled(dozeEnabled);
        mPocketPreference.setOnPreferenceChangeListener(this);

        // Hide AOD if not supported and set all its dependents otherwise
        if (!MotoActionsSettings.alwaysOnDisplayAvailable(getActivity())) {
            getPreferenceScreen().removePreference(mAlwaysOnDisplayPreference);
        } else {
            PreferenceCategory ambientDisplayCategory = findPreference("ambient_display_key");
            ambientDisplayCategory.setDependency(MotoActionsSettings.ALWAYS_ON_DISPLAY);
        }
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        boolean isChecked = (Boolean) newValue;
        if (MotoActionsSettings.ALWAYS_ON_DISPLAY.equals(preference.getKey())) {
            MotoActionsSettings.enableAlwaysOn(getActivity(), isChecked);
        } else if (MotoActionsSettings.DOZE_ENABLE.equals(preference.getKey())) {
            MotoActionsSettings.enableDoze(getActivity(), isChecked);

            if (!isChecked) {
                MotoActionsSettings.enableAlwaysOn(getActivity(), false);
                mAlwaysOnDisplayPreference.setChecked(false);
            }
            mAlwaysOnDisplayPreference.setEnabled(isChecked);

            mHandwavePreference.setEnabled(isChecked);
            mPickUpPreference.setEnabled(isChecked);
            mPocketPreference.setEnabled(isChecked);
        }

        return true;
    }

}
