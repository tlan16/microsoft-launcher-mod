package com.local.noaadprompt;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodReplacement;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam;
import java.lang.ref.WeakReference;

/**
 * Replaces Ea.e.b(WeakReference<Activity>, Runnable) of Microsoft Launcher 6.260402.0.1178950
 * (the only builder of the "Enable Automated Version Update" dialog) with: run the continuation, show nothing.
 * Class/method names are obfuscated and valid for this build only.
 */
public class Hook implements IXposedHookLoadPackage {
    private static final String TAG = "[NoAadPrompt] ";

    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) {
        if (!"com.microsoft.launcher".equals(lpparam.packageName)) return;
        Class<?> c = XposedHelpers.findClassIfExists("Ea.e", lpparam.classLoader);
        if (c == null) {
            XposedBridge.log(TAG + "class Ea.e not found; unsupported launcher build");
            return;
        }
        try {
            XposedHelpers.findAndHookMethod(c, "b", WeakReference.class, Runnable.class,
                new XC_MethodReplacement() {
                    @Override
                    protected Object replaceHookedMethod(MethodHookParam param) {
                        Runnable r = (Runnable) param.args[1];
                        if (r != null) r.run();
                        return null;
                    }
                });
            XposedBridge.log(TAG + "hooked Ea.e.b(WeakReference,Runnable)");
        } catch (Throwable t) {
            XposedBridge.log(TAG + "hook failed: " + t);
        }
    }
}
