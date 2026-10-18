package com.local.noaadprompt;

import android.util.Log;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface;
import java.lang.ref.WeakReference;
import java.lang.reflect.Method;

/**
 * Hooks Ea.e.b(WeakReference, Runnable) of Microsoft Launcher 6.260402.0.1178950, the only builder of the
 * "Enable Automated Version Update" dialog, so it runs the continuation and shows nothing.
 * Names are obfuscated and valid for this build only.
 */
public class ModuleMain extends XposedModule {
    private static final String TAG = "NoAadPrompt";
    private static final String TARGET_PKG = "com.microsoft.launcher";

    @Override
    public void onPackageReady(PackageReadyParam param) {
        if (!TARGET_PKG.equals(param.getPackageName())) return;
        try {
            Class<?> c = param.getClassLoader().loadClass("Ea.e");
            Method m = c.getDeclaredMethod("b", WeakReference.class, Runnable.class);
            hook(m).intercept(chain -> {
                Runnable r = (Runnable) chain.getArg(1);
                if (r != null) r.run();
                return null;
            });
            log(Log.INFO, TAG, "hooked Ea.e.b(WeakReference,Runnable)");
        } catch (ClassNotFoundException | NoSuchMethodException e) {
            log(Log.WARN, TAG, "target Ea.e.b not found; unsupported launcher build", e);
        } catch (Throwable t) {
            log(Log.ERROR, TAG, "hook failed", t);
        }
    }
}
