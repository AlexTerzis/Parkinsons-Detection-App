package com.example.hand_landmarker_flutter

import android.content.Context
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class HandLandmarkerFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleOwner: LifecycleOwner
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return HandLandmarkerView(context, messenger, viewId, lifecycleOwner)
    }
}