package com.example.hand_landmarker_flutter

import android.content.Context
import android.util.Log
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class GestureRecognizerView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    private val lifecycleOwner: LifecycleOwner
) : PlatformView {
    private val frameLayout = FrameLayout(context)
    private val previewView = PreviewView(context)
    private val helper = GestureRecognizerHelper(context, previewView, lifecycleOwner)
    private val channel = MethodChannel(messenger, "gesture_recognizer_channel_$id")

    init {
        previewView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        previewView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
        frameLayout.setBackgroundColor(android.graphics.Color.TRANSPARENT)
        frameLayout.addView(previewView)

        helper.setResultListener { result ->
            val gestures = result.gestures().mapNotNull { gestureList ->
                gestureList.firstOrNull()?.categoryName()
            }
            // Only send to Flutter if the gestures are not ["None"] or empty
            if (gestures.isNotEmpty() && !(gestures.size == 1 && gestures[0] == "None")) {
                Log.d("GestureRecognizerView", "Sending gestures to Flutter: $gestures")
                channel.invokeMethod("onGestures", gestures)
            }
        }
        helper.setupCamera()
    }

    override fun getView() = frameLayout

    override fun dispose() {
        helper.shutdown()
    }
}
