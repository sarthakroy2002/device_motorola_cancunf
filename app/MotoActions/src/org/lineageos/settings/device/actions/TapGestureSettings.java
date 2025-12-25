/*
 * SPDX-FileCopyrightText: Yet Another AOSP Project
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

package org.lineageos.settings.device.actions;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.os.Bundle;
import android.os.UserHandle;
import android.util.Log;

import android.view.MenuItem;

import android.provider.Settings;

import androidx.fragment.app.Fragment;
import androidx.preference.ListPreference;
import androidx.preference.Preference;
import androidx.preference.PreferenceFragmentCompat;
import androidx.preference.PreferenceManager;
import androidx.preference.SwitchPreferenceCompat;

import com.android.internal.lineage.hardware.LineageHardwareManager; // Need FWB support
import com.android.internal.lineage.hardware.TouchscreenGesture; // Need FWB support
import org.lineageos.settings.device.Constants;
import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;
import com.android.settingslib.widget.SettingsBasePreferenceFragment;

import java.lang.System;
import java.util.ArrayList;
import java.util.List;

public class TapGestureSettings extends CollapsingToolbarBaseActivity
        implements PreferenceFragmentCompat.OnPreferenceStartFragmentCallback {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .replace(com.android.settingslib.collapsingtoolbar.R.id.content_frame, new MainSettingsFragment())
                    .commit();
        }
    }

    @Override
    public boolean onPreferenceStartFragment(PreferenceFragmentCompat preferenceFragment,
            Preference preference) {
        Fragment instantiate = Fragment.instantiate(this, preference.getFragment(),
            preference.getExtras());
        getSupportFragmentManager().beginTransaction().replace(
                android.R.id.content, instantiate).addToBackStack(preference.getKey()).commit();

        return true;
    }

    public static class MainSettingsFragment extends SettingsBasePreferenceFragment {

        private static final String KEY_TAP_GESTURE = "tap_gesture";
        private static final String KEY_TAP_GESTURE_HAPTIC = "tap_gesture_haptic_feedback";
        private static final String TAP_GESTURE_TITLE = KEY_TAP_GESTURE + "_%s_title";

        private TouchscreenGesture[] mTapGestures;

        @Override
        public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {

            setPreferencesFromResource(org.lineageos.settings.device.R.xml.tap_gesture_settings, rootKey);

            if (isTapGesturesSupported(getContext())) {
                initTapGestures();
            }
        }

        private void initTapGestures() {
            final LineageHardwareManager manager = LineageHardwareManager.getInstance(getContext());
            mTapGestures = manager.getTouchscreenGestures();
            SwitchPreferenceCompat getstureHapticsSwitch = findPreference(KEY_TAP_GESTURE_HAPTIC);
            boolean enabled = Settings.System.getInt(getContext().getContentResolver(),
                    KEY_TAP_GESTURE_HAPTIC, 1) == 1;
            getstureHapticsSwitch.setChecked(enabled);
            getstureHapticsSwitch.setOnPreferenceChangeListener(
                    (preference, newValue) -> {
                        boolean checked = (Boolean) newValue;
                        Settings.System.putInt(getContext().getContentResolver(),
                                KEY_TAP_GESTURE_HAPTIC, checked ? 1 : 0);
                        return true;
                    });
            final int[] actions = getDefaultGestureActions(getContext(), mTapGestures);
            for (final TouchscreenGesture gesture : mTapGestures) {
                getPreferenceScreen().addPreference(new TapGesturePreference(
                        getContext(), gesture, actions[gesture.id]));
            }
        }

        private class TapGesturePreference extends ListPreference {
            private final Context mContext;
            private final TouchscreenGesture mGesture;

            public static String getLocalizedString(final Resources res,
                                                    final String stringName,
                                                    final String stringFormat) {
                final String name = stringName.toLowerCase().replace(" ", "_");
                final String nameRes = String.format(stringFormat, name);
                return getStringForResourceName(res, nameRes, stringName);
            }

            public static String getStringForResourceName(final Resources res,
                                                          final String resourceName,
                                                          final String defaultValue) {
                final int resId = res.getIdentifier(resourceName, "string", "org.lineageos.settings.device");
                if (resId <= 0) {
                    Log.e("TapGestureSettings", "No resource found for " + resourceName);
                    return defaultValue;
                } else {
                    return res.getString(resId);
                }
            }


            public TapGesturePreference(final Context context,
                                        final TouchscreenGesture gesture,
                                        final int defaultAction) {
                super(context);
                mContext = context;
                mGesture = gesture;

                setKey(buildPreferenceKey(gesture));
                setEntries(org.lineageos.settings.device.R.array.tap_gesture_action_entries);
                setEntryValues(org.lineageos.settings.device.R.array.tap_gesture_action_values);
                setDefaultValue(String.valueOf(defaultAction));

                setSummary("%s");
                setDialogTitle(org.lineageos.settings.device.R.string.tap_gesture_action_dialog_title);
                setTitle(getLocalizedString(
                        context.getResources(), gesture.name, TAP_GESTURE_TITLE));
            }

            @Override
            public boolean callChangeListener(final Object newValue) {
                final int action = Integer.parseInt(String.valueOf(newValue));
                final LineageHardwareManager manager = LineageHardwareManager.getInstance(mContext);
                if (!manager.setTouchscreenGestureEnabled(mGesture, action > 0)) {
                    return false;
                }
                final SharedPreferences.Editor editor = Constants.getDESharedPrefs(mContext).edit();
                editor.putString(getKey(), String.valueOf(newValue));
                editor.apply();
                return super.callChangeListener(newValue);
            }

            @Override
            protected boolean persistString(String value) {
                if (!super.persistString(value)) {
                    return false;
                }
                sendUpdateBroadcast(mContext, mTapGestures);
                return true;
            }
        }

        public static void restoreTapGestureStates(final Context context) {
            if (!isTapGesturesSupported(context)) {
                return;
            }

            final LineageHardwareManager manager = LineageHardwareManager.getInstance(context);
            final TouchscreenGesture[] gestures = manager.getTouchscreenGestures();
            final int[] actionList = buildOldActionList(context, gestures);
            for (final TouchscreenGesture gesture : gestures) {
                manager.setTouchscreenGestureEnabled(gesture, actionList[gesture.id] > 0);
            }

            sendUpdateBroadcast(context, gestures);
        }

        public static void migrateTapGestureStates(final Context context) {
            if (!isTapGesturesSupported(context)) {
                return;
            }

            final LineageHardwareManager manager = LineageHardwareManager.getInstance(context);
            final TouchscreenGesture[] gestures = manager.getTouchscreenGestures();
            final int[] actionList = buildOldActionList(context, gestures);
            final SharedPreferences oldPrefs = PreferenceManager.getDefaultSharedPreferences(context);
            final SharedPreferences.Editor oldPrefsEditor = oldPrefs.edit();
            final SharedPreferences.Editor newPrefsEditor = Constants.getDESharedPrefs(context).edit();
            for (final TouchscreenGesture gesture : gestures) {
                final String key = buildPreferenceKey(gesture);
                final String oldValue = oldPrefs.getString(key, null);
                if (oldValue == null) continue;
                newPrefsEditor.putString(key, oldValue);
                oldPrefsEditor.remove(key);
            }
            newPrefsEditor.commit();
            oldPrefsEditor.commit();
        }

        public static List<String> getPrefKeys(final Context context) {
            if (!isTapGesturesSupported(context)) {
                return null;
            }

            final LineageHardwareManager manager = LineageHardwareManager.getInstance(context);
            final TouchscreenGesture[] gestures = manager.getTouchscreenGestures();
            final List<String> result = new ArrayList<>();
            for (final TouchscreenGesture gesture : gestures)
                result.add(buildPreferenceKey(gesture));
            return result;
        }

        private static boolean isTapGesturesSupported(final Context context) {
            final LineageHardwareManager manager = LineageHardwareManager.getInstance(context);
            return manager.isSupported(LineageHardwareManager.FEATURE_TOUCHSCREEN_GESTURES);
        }

        private static int[] getDefaultGestureActions(final Context context,
                final TouchscreenGesture[] gestures) {
            final int[] defaultActions = context.getResources().getIntArray(
                    org.lineageos.settings.device.R.array.config_defaultTapGestureActions);
            if (defaultActions.length >= gestures.length) {
                return defaultActions;
            }

            final int[] filledDefaultActions = new int[gestures.length];
            System.arraycopy(defaultActions, 0, filledDefaultActions, 0, defaultActions.length);
            return filledDefaultActions;
        }

        private static int[] buildActionList(final Context context,
                final TouchscreenGesture[] gestures) {
            final SharedPreferences prefs = Constants.getDESharedPrefs(context);
            return buildActions(context, gestures, prefs);
        }

        private static int[] buildOldActionList(final Context context,
                final TouchscreenGesture[] gestures) {
            final SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
            return buildActions(context, gestures, prefs);
        }

        private static int[] buildActions(final Context context,
                final TouchscreenGesture[] gestures, final SharedPreferences prefs) {
            final int[] result = new int[gestures.length];
            final int[] defaultActions = getDefaultGestureActions(context, gestures);
            for (final TouchscreenGesture gesture : gestures) {
                final String key = buildPreferenceKey(gesture);
                final String defaultValue = String.valueOf(defaultActions[gesture.id]);
                result[gesture.id] = Integer.parseInt(prefs.getString(key, defaultValue));
            }
            return result;
        }

        private static String buildPreferenceKey(final TouchscreenGesture gesture) {
            return "tap_gesture_" + gesture.id;
        }

        private static void sendUpdateBroadcast(final Context context,
                final TouchscreenGesture[] gestures) {
            final Intent intent = new Intent(Constants.UPDATE_PREFS_ACTION);
            final int[] keycodes = new int[gestures.length];
            final int[] actions = buildActionList(context, gestures);
            for (final TouchscreenGesture gesture : gestures) {
                keycodes[gesture.id] = gesture.keycode;
            }
            intent.putExtra(Constants.UPDATE_EXTRA_KEYCODE_MAPPING, keycodes);
            intent.putExtra(Constants.UPDATE_EXTRA_ACTION_MAPPING, actions);
            intent.setFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY);
            context.sendBroadcastAsUser(intent, UserHandle.CURRENT);
        }

        @Override
        public void onSaveInstanceState(Bundle outState) {
            super.onSaveInstanceState(outState);
        }

        @Override
        public void onResume() {
            super.onResume();
        }

        @Override
        public void onDestroy() {
            super.onDestroy();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
