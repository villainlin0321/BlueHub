package com.europepass.europepass

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    private const val CHANNEL_NAME = "bluehub/app_icon"
  }

  /// 注册平台通道：接收 Flutter 的语言状态，并切换桌面启动图标。
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
      when (call.method) {
        "setIcon" -> {
          val args = call.arguments as? Map<*, *>
          val isChinese = (args?.get("isChinese") as? Boolean) ?: false
          setLauncherAlias(isChinese)
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }

  /// 切换 Launcher alias：Android 无法直接改应用图标，只能通过启用/禁用不同的入口别名实现。
  private fun setLauncherAlias(isChinese: Boolean) {
    val defaultAlias = ComponentName(packageName, "$packageName.MainActivityDefault")
    val zhAlias = ComponentName(packageName, "$packageName.MainActivityZh")

    val enable = if (isChinese) zhAlias else defaultAlias
    val disable = if (isChinese) defaultAlias else zhAlias

    // 关键点：先启用目标入口，再禁用另一个入口，避免部分桌面瞬间丢失启动入口。
    packageManager.setComponentEnabledSetting(enable, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
    packageManager.setComponentEnabledSetting(disable, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
  }
}
