package com.dkiyanov.learning_control;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.Context;
import android.content.ComponentName;
import android.content.IntentFilter;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import java.util.List;
import java.util.ArrayList;

import android.app.AppOpsManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;

import android.net.Uri;
import android.content.Intent;
import android.os.PowerManager;
import android.provider.Settings;

import android.util.Log;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity.java";
    private static final String CHANNEL = "com.dkiyanov.learning_control";

    private static final List<String> skipAppList = new ArrayList<>();

    private static boolean appIsVisible = false;

    @Override
    protected void onResume() {
        super.onResume();
        appIsVisible = true;
    }

    @Override
    protected void onPause() {
        super.onPause();
        appIsVisible = false;
    }

    @Override
    protected void onStop() {
        super.onStop();
        appIsVisible = false;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        appIsVisible = false;
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            // This method is invoked on the main thread.
                            if (call.method.equals("getTopActivityName")) {
                                String topActivity = getTopActivityName();
                                result.success(topActivity);
                            }
                            else if (call.method.equals("setSkipAppList")) {
                                result.success(setSkipAppList(call.argument("skipAppList")));
                            }

                            else if (call.method.equals("isUsageAccessExists")) {
                                result.success(isUsageAccessExists());
                            }
                            else if (call.method.equals("showUsageAccessSettings")) {
                                result.success(showUsageAccessSettings());
                            }

                            else if (call.method.equals("isCanDrawOverlays")) {
                                result.success(isCanDrawOverlays());
                            }
                            else if (call.method.equals("showDrawOverlaysSettings")) {
                                result.success(showDrawOverlaysSettings());
                            }

                            else if (call.method.equals("isIgnoringBatteryOptimizations")) {
                                result.success(isIgnoringBatteryOptimizations());
                            }
                            else if (call.method.equals("showBatteryOptimizationsSettings")) {
                                result.success(showBatteryOptimizationsSettings());
                            }

                            else if (call.method.equals("getPackageName")) {
                                result.success(getPackageName());
                            }
                            else if (call.method.equals("getLaunchers")) {
                                result.success(getLaunchers());
                            }
                            else if (call.method.equals("isMyLauncherDefault")) {
                                result.success(isMyLauncherDefault());
                            }
                            else if (call.method.equals("showLauncherSettings")) {
                                result.success(showLauncherSettings());
                            }

                            else if (call.method.equals("backToHome")) {
                                result.success(backToHome());
                            }

                            else if (call.method.equals("foregroundServiceStart")) {
                                result.success(foregroundServiceStart(call.argument("title"), call.argument("text")));
                            }
                            else if (call.method.equals("foregroundServiceStop")) {
                                result.success(foregroundServiceStop());
                            }
                            else if (call.method.equals("restartApp")) {
                                result.success(restartApp());
                            }
                            else if (call.method.equals("appIsVisible")) {
                                result.success(appIsVisible);
                            }
                            else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private String getTopActivityName(){
//        Log.d(TAG, "getTopActivityName start");

        java.lang.StringBuilder topPackageName = new java.lang.StringBuilder();

        UsageStatsManager mUsageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long currentTime = System.currentTimeMillis();
        // get usage stats for the last 8 hours
        List<UsageStats> stats = mUsageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, currentTime - 1000 * 60 * 60 * 8, currentTime);
        // search for app with most recent last used time
        if (stats != null) {
            long lastUsedAppTime = 0;
            long curLastUsedAppTime;
            for (UsageStats usageStats : stats) {
                curLastUsedAppTime = usageStats.getLastTimeUsed();
                if (curLastUsedAppTime == 0) continue;

                final String packageName = usageStats.getPackageName();
                if (skipAppList.contains(packageName)) continue;

//                Log.d(TAG, "getTopActivityName " + curLastUsedAppTime + " "+ usageStats.getPackageName());

                if (curLastUsedAppTime > lastUsedAppTime) {
                    topPackageName = new java.lang.StringBuilder(packageName);
                    lastUsedAppTime = curLastUsedAppTime;
                } else {
                    if (curLastUsedAppTime == lastUsedAppTime) {
                        topPackageName.append(";").append(packageName);
                    }
                }
            }
        }

//        Log.d(TAG, "getTopActivityName finish " + topPackageName);

        return topPackageName.toString();
    }

    private boolean setSkipAppList(List<String> newSkipAppList){
        skipAppList.clear();
        skipAppList.addAll(newSkipAppList);
        return true;
    }

    private boolean isUsageAccessExists(){
        try {
            Log.d(TAG, "isUsageAccessExists");

            PackageManager packageManager = getPackageManager();
            ApplicationInfo applicationInfo = packageManager.getApplicationInfo(getPackageName(), 0);
            AppOpsManager appOpsManager = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
            int mode = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, applicationInfo.uid, applicationInfo.packageName);
            return (mode == AppOpsManager.MODE_ALLOWED);

        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private boolean showUsageAccessSettings(){
        Log.d(TAG, "showUsageAccessSettings");

        try {
            Intent intent = new Intent(
                    Settings.ACTION_USAGE_ACCESS_SETTINGS,
                    Uri.parse(getPackageName())
            );
            startActivity(intent);
        } catch (android.content.ActivityNotFoundException e) {
            Intent intent = new Intent(
                    Settings.ACTION_USAGE_ACCESS_SETTINGS
            );
            startActivity(intent);
        }

        return true;
    }

    private boolean isCanDrawOverlays(){
        return Settings.canDrawOverlays(this);
    }

    private boolean showDrawOverlaysSettings(){
        Log.d(TAG, "showDrawOverlaysSettings");

        try {
            Intent intent = new Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse(getPackageName())
            );
            startActivity(intent);
        } catch (android.content.ActivityNotFoundException e) {
            Intent intent = new Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION
            );
            startActivity(intent);
        }

        return true;
    }

    private boolean isIgnoringBatteryOptimizations(){
        PowerManager powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
        return powerManager.isIgnoringBatteryOptimizations(getPackageName());
    }

    private boolean showBatteryOptimizationsSettings(){
        Log.d(TAG, "showBatteryOptimizationsSettings");

        Intent intent = new Intent();
        intent.setAction(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        startActivity(intent);

        return true;
    }

    private String getLaunchers(){
        java.lang.StringBuilder launchers = new java.lang.StringBuilder();

        PackageManager packageManager = getPackageManager();
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_HOME);
        List<ResolveInfo> resolveInfoList = packageManager.queryIntentActivities(intent, 0);

        for (ResolveInfo resolveInfo : resolveInfoList) {
            if (launchers.length() == 0) {
                launchers.append(resolveInfo.activityInfo.packageName);
            } else {
                launchers.append(";");
                launchers.append(resolveInfo.activityInfo.packageName);
            }
        }

        return launchers.toString();
    }

    boolean isMyLauncherDefault() {
        final IntentFilter filter = new IntentFilter(Intent.ACTION_MAIN);
        filter.addCategory(Intent.CATEGORY_HOME);

        List<IntentFilter> filters = new ArrayList<>();
        filters.add(filter);

        final String myPackageName = getPackageName();
        List<ComponentName> activities = new ArrayList<>();
        final PackageManager packageManager = (PackageManager) getPackageManager();

        // You can use name of your package here as third argument
        packageManager.getPreferredActivities(filters, activities, null);

        for (ComponentName activity : activities) {
            if (myPackageName.equals(activity.getPackageName())) {
                return true;
            }
        }
        return false;
    }

    private boolean showLauncherSettings(){
        Log.d(TAG, "showLauncherSettings");
        Intent intent = new Intent(
                Settings.ACTION_HOME_SETTINGS
        );
        startActivity(intent);

        return true;
    }

    private boolean backToHome() {
        Log.d(TAG, "backToHome");

// Почему не всегда полностью корректно отрабатывет
// например не может перебить recent apps screen
// иногда какбы не фиксируется поднятьие на верх, тоесть по факту оно есть, но usage status это не чуствует
//        Intent intent = new Intent(this, MainActivity.class);
//        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP );
//        startActivity(intent);

// попробуем так:
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLaunchIntentForPackage(getPackageName());
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP );
        startActivity(intent);

        return true;
    }

    private boolean foregroundServiceStart(String title, String text) {
        Intent intent = new Intent(this, LCForegroundService.class);
        intent.setAction("StartService");
        intent.putExtra("title", title);
        intent.putExtra("text", text);
        startService(intent);
        return true;
    }
    private boolean foregroundServiceStop() {
        Intent intent = new Intent(this, LCForegroundService.class);
        intent.setAction("StopService");
        stopService(intent);
        return true;
    }

    private boolean restartApp() {
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLaunchIntentForPackage(getPackageName());
        ComponentName componentName = intent.getComponent();
        Intent mainIntent = Intent.makeRestartActivityTask(componentName);
        startActivity(mainIntent);
        Runtime.getRuntime().exit(0);
        return true;
    }
}
