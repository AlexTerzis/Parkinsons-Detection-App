package com.example.hand_landmarker_flutter

import android.content.Context
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import com.google.mediapipe.tasks.vision.core.RunningMode

class HandLandmarkerView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    private val lifecycleOwner: LifecycleOwner
) : PlatformView {
    private val frameLayout = FrameLayout(context)
    private val previewView = PreviewView(context)
    private val overlay = OverlayView(context)
    private val helper = HandLandmarkerHelper(
        context, previewView, overlay, lifecycleOwner
    )
    private val channel = MethodChannel(
        messenger, "hand_landmarker_channel_$id"
    )

    init {
        // Force TextureView implementation for PreviewView to respect Z-order
        previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE

        // Configure layout parameters
        previewView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        overlay.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )

        // Add views to layout
        frameLayout.addView(previewView)
        frameLayout.addView(overlay)
        
        // Explicitly bring OverlayView to the front
        overlay.bringToFront()
        
        // Start the helper which initializes CameraX and MediaPipe
        helper.setupCameraAndLandmarker()
        
        // Listener to receive results from HandLandmarkerHelper
        helper.setResultListener { result, input ->
            // Update the overlay with new results
            overlay.setResults(
                result,
                input.height, // Pass image height
                input.width,  // Pass image width
                RunningMode.LIVE_STREAM
            )

            // Send landmarks and handedness back to Flutter
            val resultsList = mutableListOf<Map<String, Any>>()
            result.landmarks().forEachIndexed { index, handLandmarks ->
                val landmarksMap = handLandmarks.map { landmark ->
                    mapOf(
                        "x" to landmark.x(),
                        "y" to landmark.y(),
                        "z" to landmark.z()
                    )
                }
                // Get handedness (Left/Right). Defaults to Unknown if not available.
                // Use handednesses() (plural) which returns List<List<Category>>
                val handedness = result.handednesses().getOrNull(index)?.firstOrNull()?.categoryName() ?: "Unknown"
                
                resultsList.add(mapOf(
                    "landmarks" to landmarksMap,
                    "handedness" to handedness
                ))
            }
            channel.invokeMethod("onLandmarks", resultsList)
        }
    }

    override fun getView() = frameLayout

    override fun dispose() {
        helper.shutdown()
    }
}
