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
        helper.setResultListener { result, input, capturedAtMs ->
            // Update the overlay with new results
            overlay.setResults(
                result,
                input.height, // Pass image height
                input.width,  // Pass image width
                RunningMode.LIVE_STREAM
            )

            // Send landmarks and handedness back to Flutter
            // Nullable values: handednessScore is absent when the detector did
            // not classify the hand. StandardMessageCodec encodes that as null.
            val resultsList = mutableListOf<Map<String, Any?>>()
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
                val handednessCategory = result.handednesses().getOrNull(index)?.firstOrNull()
                val detected = handednessCategory?.categoryName() ?: "Unknown"

                // Passed through exactly as MediaPipe reports it.
                //
                // The hand model assumes a mirrored, selfie-style input, and
                // that is what it gets: the front camera's frames are mirrored
                // in HandLandmarkerHelper.analyze before detection. Its label is
                // therefore already the user's own side. This used to be flipped
                // a second time here, which turned every right hand into a left
                // one — harmless while one hand was on screen, but with both in
                // view the test measured the resting hand instead of the moving
                // one. Flutter no longer depends on the label for that anyway;
                // it tells the hands apart by where they are in the picture.
                val handedness = detected

                // The classifier's own confidence in that Left/Right call.
                // Flutter uses it to separate a solid detection from a marginal
                // one; a frame whose handedness is a coin flip must not be
                // counted as clean evidence for the hand under examination.
                // Sent as a nullable extra so an older Flutter layer, or one
                // running against a build without it, simply sees no score
                // rather than a fabricated zero.
                val handednessScore = handednessCategory?.score()

                resultsList.add(mapOf(
                    "landmarks" to landmarksMap,
                    "handedness" to handedness,
                    "handednessScore" to handednessScore
                ))
            }
            // The capture time travels with the hands, so Flutter does not have
            // to stamp frames on arrival — see HandLandmarkerHelper.captureEpochMs.
            channel.invokeMethod(
                "onLandmarks",
                mapOf(
                    "timestampMs" to capturedAtMs,
                    "hands" to resultsList
                )
            )
        }
    }

    override fun getView() = frameLayout

    override fun dispose() {
        helper.shutdown()
    }
}
