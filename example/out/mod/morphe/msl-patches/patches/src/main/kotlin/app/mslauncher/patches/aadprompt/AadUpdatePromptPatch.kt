package app.mslauncher.patches.aadprompt

import app.morphe.patcher.Fingerprint
import app.morphe.patcher.extensions.InstructionExtensions.addInstructionsWithLabels
import app.morphe.patcher.patch.ApkFileType
import app.morphe.patcher.patch.AppTarget
import app.morphe.patcher.patch.Compatibility
import app.morphe.patcher.patch.bytecodePatch
import app.morphe.patcher.resource.ResourceType
import app.morphe.patcher.resourceLiteral
import com.android.tools.smali.dexlib2.AccessFlags

private val COMPATIBILITY_MS_LAUNCHER = Compatibility(
    name = "Microsoft Launcher",
    packageName = "com.microsoft.launcher",
    apkFileType = ApkFileType.APK,
    appIconColor = 0x0078D4,
    targets = listOf(AppTarget(version = "6.260402.0.1178950"))
)

// Ea.e.b(WeakReference<Activity>, Runnable) in the analysed build: the only method that
// inflates layout view_appcenter_checkupdate_reminder and shows the dialog.
internal object ShowCheckUpdateDialogFingerprint : Fingerprint(
    accessFlags = listOf(AccessFlags.PUBLIC, AccessFlags.STATIC),
    returnType = "V",
    parameters = listOf("Ljava/lang/ref/WeakReference;", "Ljava/lang/Runnable;"),
    filters = listOf(
        resourceLiteral(ResourceType.LAYOUT, "view_appcenter_checkupdate_reminder"),
    )
)

@Suppress("unused")
val disableAadUpdatePromptPatch = bytecodePatch(
    name = "Disable AAD update prompt",
    description = "Removes the recurring 'Enable Automated Version Update' dialog. " +
        "The continuation Runnable is still run, so the calling flow proceeds normally.",
    default = true
) {
    compatibleWith(COMPATIBILITY_MS_LAUNCHER)

    execute {
        // Static method: p0 = WeakReference<Activity>, p1 = Runnable continuation (nullable).
        ShowCheckUpdateDialogFingerprint.method.addInstructionsWithLabels(
            0,
            """
                if-eqz p1, :done
                invoke-interface {p1}, Ljava/lang/Runnable;->run()V
                :done
                return-void
            """
        )
    }
}
