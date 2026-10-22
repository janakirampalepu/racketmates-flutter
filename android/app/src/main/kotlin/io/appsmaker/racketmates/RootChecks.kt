package io.appsmaker.racketmates

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.io.File

/**
 * Root detection ported from the native app: its own `RacketmatesRootChecker`
 * (su/busybox files, init.d, PATH, `which su`), the harmful-app package list,
 * and the common checks of the RootBeer library the native app uses (test
 * keys, writable system partitions, Magisk files). It is a port, not the same
 * code, so results can differ on unusual devices.
 */
internal object RootChecks {
    /** Root and root-hiding apps (native `AppConstants.rootAppsPackages`). */
    val harmfulPackages = listOf(
        "com.noshufou.android.su",
        "com.noshufou.android.su.elite",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.thirdparty.superuser",
        "com.yellowes.su",
        "com.topjohnwu.magisk",
        "com.koushikdutta.rommanager",
        "com.koushikdutta.rommanager.license",
        "com.dimonvideo.luckypatcher",
        "com.chelpus.lackypatch",
        "com.ramdroid.appquarantine",
        "com.ramdroid.appquarantinepro",
        "com.android.vending.billing.InAppBillingService.COIN",
        "com.chelpus.luckypatcher",
        "com.devadvance.rootcloak",
        "com.devadvance.rootcloakplus",
        "de.robv.android.xposed.installer",
        "com.saurik.substrate",
        "com.zachspong.temprootremovejb",
        "com.amphoras.hidemyroot",
        "com.amphoras.hidemyrootadfree",
        "com.formyhm.hiderootPremium",
        "com.formyhm.hideroot",
    )

    private val rootPaths = listOf(
        "/sbin/", "/system/bin/", "/system/xbin/", "/data/local/xbin/",
        "/data/local/bin/", "/system/sd/xbin/", "/system/bin/failsafe/",
        "/data/local/", "/system/", "/system/bin/.ext/.su",
        "/system/usr/we-need-root/su-backup", "/system/xbin/mu",
    )

    private val magiskFiles = listOf(
        "/sbin/.magisk", "/cache/.disable_magisk", "/dev/.magisk.unblock",
        "/cache/magisk.log", "/data/adb/magisk", "/data/adb/modules",
    )

    private val systemMounts = listOf(
        "/system", "/system/bin", "/system/sbin", "/system/xbin", "/vendor/bin",
        "/sbin", "/etc",
    )

    fun isCompromised(context: Context): Boolean =
        hasRootFiles() ||
            hasTestKeys() ||
            hasWritableSystemPartition() ||
            hasMagiskFiles() ||
            canRunSu() ||
            hasHarmfulApp(context.packageManager)

    /** Native `RacketmatesRootChecker.isRooted` file checks. */
    internal fun hasRootFiles(): Boolean {
        val initDir = File("/system/etc/init.d")
        if (initDir.exists() && initDir.isDirectory) return true
        for (path in rootPaths) {
            if (File(path + "su").exists() || File(path + "busybox").exists()) return true
        }
        System.getenv("PATH")?.split(":")?.forEach { path ->
            if (File("$path/su").exists() || File("$path/busybox").exists()) return true
        }
        return false
    }

    private fun hasTestKeys(): Boolean = Build.TAGS?.contains("test-keys") == true

    private fun hasMagiskFiles(): Boolean = magiskFiles.any { File(it).exists() }

    /** A system partition mounted read-write means the system was remounted. */
    private fun hasWritableSystemPartition(): Boolean = try {
        File("/proc/mounts").readLines().any { line ->
            val parts = line.split(" ")
            parts.size > 3 &&
                parts[1] in systemMounts &&
                parts[3].split(",").contains("rw")
        }
    } catch (e: Exception) {
        false
    }

    private fun canRunSu(): Boolean = try {
        val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
        process.waitFor()
        process.exitValue() == 0
    } catch (e: Exception) {
        false
    }

    /** Native `isHarmfulAppPackageInstalled`: an installed, enabled package. */
    internal fun hasHarmfulApp(pm: PackageManager): Boolean =
        harmfulPackages.any { pkg ->
            try {
                pm.getApplicationInfo(pkg, 0).enabled
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
}
