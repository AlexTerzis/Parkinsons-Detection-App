/*
 * Copyright 2022 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.example.hand_landmarker_flutter

import android.content.Context
import android.graphics.Bitmap
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.hardware.display.DisplayManager
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.util.Range
import android.util.Size
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class HandLandmarkerHelper(
    private val context: Context,
    private val previewView: PreviewView,
    private val overlay: OverlayView,
    private val lifecycleOwner: LifecycleOwner
) : ImageAnalysis.Analyzer {

    // Swapped from the detector thread on a GPU fallback, read on the camera
    // thread, so it must be visible across both.
    @Volatile
    private var handLandmarker: HandLandmarker? = null
    private var bitmapBuffer: Bitmap? = null
    private var frameCount = 0
    private var lastFpsTimestamp = SystemClock.elapsedRealtime()
    private var resultListener: ((HandLandmarkerResult, MPImage, Long) -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var cameraExecutor: ExecutorService
    private var cameraFacing = CameraSelector.LENS_FACING_FRONT
    private var cameraProvider: ProcessCameraProvider? = null
    private var analysisUseCase: ImageAnalysis? = null

    /** Which MediaPipe delegate is actually running, for the fallback. */
    private var delegate = Delegate.GPU

    /** Consecutive detector errors; enough of them on the GPU means fall back. */
    private var errorCount = 0

    /** Last timestamp handed to MediaPipe, which requires them to increase. */
    private var lastFrameTimeMs = 0L

    /**
     * The analysis frames have to be rotated upright for the display as it is
     * *now*. The test runs in landscape, and the activity does not restart on
     * rotation (configChanges includes orientation), so the rotation CameraX
     * captured when the use case was built goes stale as soon as the screen
     * turns. Without this the detector is fed sideways hands.
     */
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
        override fun onDisplayChanged(displayId: Int) {
            val display = previewView.display ?: return
            if (display.displayId == displayId) {
                analysisUseCase?.targetRotation = display.rotation
            }
        }
    }

    /**
     * Whether the frames handed to MediaPipe are mirrored.
     *
     * This matters far more than it looks. The front camera is mirrored in
     * [analyze] so the preview behaves like a mirror for the user — but a
     * mirrored right hand is geometrically indistinguishable from a left hand,
     * so MediaPipe reports the opposite side from the one the user is actually
     * holding up. Anything that names a hand has to know this.
     */
    val isMirrored: Boolean
        get() = cameraFacing == CameraSelector.LENS_FACING_FRONT

    init {
        initHandLandmarker()
        cameraExecutor = Executors.newSingleThreadExecutor()
    }

    fun setResultListener(listener: (HandLandmarkerResult, MPImage, Long) -> Unit) {
        resultListener = listener
    }

    /**
     * Builds the detector on the GPU when the device allows it, otherwise on
     * the CPU.
     *
     * The GPU delegate typically runs the hand model two to three times faster,
     * and frame rate is what the whole analysis lives on: fast finger tapping
     * is 4-6 taps a second, which cannot be counted from 10-12 frames a second,
     * and tremor frequency needs at least 15. Not every GPU driver works with
     * MediaPipe, so a failure here — or repeated errors once running, see
     * [onError] — drops back to the CPU rather than leaving the test with no
     * detector at all.
     */
    private fun initHandLandmarker() {
        handLandmarker = createLandmarker(delegate)
        if (handLandmarker == null && delegate == Delegate.GPU) {
            Log.w(TAG, "GPU delegate unavailable, falling back to CPU")
            delegate = Delegate.CPU
            handLandmarker = createLandmarker(delegate)
        }
        Log.i(TAG, "Hand landmarker running on $delegate")
    }

    private fun createLandmarker(delegate: Delegate): HandLandmarker? {
        return try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setDelegate(delegate)
                .setModelAssetPath("hand_landmarker.task")

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setNumHands(2)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setResultListener(this::onResults)
                .setErrorListener(this::onError)
                .build()

            HandLandmarker.createFromOptions(context, options)
        } catch (e: Throwable) {
            Log.e(TAG, "MediaPipe failed to initialize on $delegate: ${e.message}")
            null
        }
    }

    private fun onError(error: RuntimeException) {
        Log.e(TAG, "Hand Landmarker Error: ${error.message}")
        errorCount++
        if (delegate == Delegate.GPU && errorCount >= 5) {
            Log.w(TAG, "Repeated GPU errors, switching the detector to CPU")
            delegate = Delegate.CPU
            errorCount = 0
            val old = handLandmarker
            handLandmarker = createLandmarker(delegate)
            // Closed later, not from inside its own error callback.
            mainHandler.post {
                try {
                    old?.close()
                } catch (e: Exception) {
                    Log.w(TAG, "Error closing GPU landmarker: ${e.message}")
                }
            }
        }
    }

    /**
     * When the frame behind [result] was captured, in wall-clock milliseconds.
     *
     * MediaPipe echoes back the timestamp it was given, which is the uptime
     * clock at the moment the frame reached [analyze]. Converted here, on the
     * detector thread, so Flutter receives the capture time rather than
     * stamping frames when they arrive — arrival time includes the detector's
     * own latency and the hop to the main thread, which varies frame to frame
     * and showed up in the analysis as jitter and a lower apparent frame rate.
     */
    private fun captureEpochMs(result: HandLandmarkerResult): Long {
        val ageMs = SystemClock.uptimeMillis() - result.timestampMs()
        return System.currentTimeMillis() - ageMs
    }

    private fun onResults(result: HandLandmarkerResult, input: MPImage) {
        errorCount = 0
        val capturedAt = captureEpochMs(result)
        mainHandler.post {
            resultListener?.invoke(result, input, capturedAt)
        }

        frameCount++
        val now = SystemClock.elapsedRealtime()
        val delta = now - lastFpsTimestamp
        if (delta > 1000) {
            val fps = (frameCount * 1000.0 / delta).toInt()
            Log.d(TAG, "FPS: $fps")
            frameCount = 0
            lastFpsTimestamp = now
        }
    }

    // Entry point for setting up camera and landmarker
    fun setupCameraAndLandmarker() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener(
            {
                val cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases(cameraProvider)
            },
            ContextCompat.getMainExecutor(context)
        )
    }

    @androidx.annotation.OptIn(ExperimentalCamera2Interop::class)
    private fun bindCameraUseCases(cameraProvider: ProcessCameraProvider) {
        // Kept so shutdown can release the camera. Binding is tied to the
        // Activity lifecycle, which outlives this view, so nothing unbinds it
        // when the view goes away unless we do it ourselves.
        this.cameraProvider = cameraProvider

        val cameraSelector = CameraSelector.Builder().requireLensFacing(cameraFacing).build()
        val rotation = previewView.display?.rotation ?: android.view.Surface.ROTATION_0
        val fpsRange = bestFpsRange()

        // Preview Use Case
        val previewBuilder = Preview.Builder().setTargetRotation(rotation)
        fpsRange?.let {
            Camera2Interop.Extender(previewBuilder)
                .setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, it)
        }
        val previewUseCase = previewBuilder.build()
        previewUseCase.setSurfaceProvider(previewView.surfaceProvider)

        // Image Analysis Use Case
        val analysisBuilder = ImageAnalysis.Builder()
            // Capped deliberately. Every analysis frame is copied into a bitmap
            // and rotated on the CPU, so the cost of this scales with the pixel
            // count — and the landmark model downsamples its input anyway, so a
            // larger frame buys precision the detector then throws away. The
            // preview stays at full resolution; only analysis is capped.
            .setTargetResolution(Size(640, 480))
            .setTargetRotation(rotation)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)

        // Ask the sensor for a high, steady frame rate.
        //
        // Left to itself, auto-exposure on most front cameras drops to 15 fps
        // indoors to brighten the picture. That halves what the detector can
        // possibly see, before it has done any work at all. The picture is a
        // little darker this way; the movement analysis is far better for it.
        fpsRange?.let {
            Camera2Interop.Extender(analysisBuilder)
                .setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, it)
        }
        val analysis = analysisBuilder.build()
        analysis.setAnalyzer(cameraExecutor, this)
        analysisUseCase = analysis

        // Unbind existing use cases before rebinding
        cameraProvider.unbindAll()

        try {
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                previewUseCase,
                analysis
            )
            val displayManager =
                context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            displayManager.registerDisplayListener(displayListener, mainHandler)
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    /**
     * The front camera's best supported auto-exposure range for this test: the
     * highest top speed, and among those the highest floor, so exposure cannot
     * drag the rate down in dim light. `null` leaves the camera's default.
     */
    private fun bestFpsRange(): Range<Int>? {
        return try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val id = manager.cameraIdList.firstOrNull { cameraId ->
                manager.getCameraCharacteristics(cameraId)
                    .get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_FRONT
            } ?: return null
            val ranges = manager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
                ?: return null
            ranges
                .filter { it.upper <= 30 }
                .maxWithOrNull(compareBy<Range<Int>>({ it.upper }, { it.lower }))
                ?.also { Log.i(TAG, "Requesting camera frame rate range $it") }
        } catch (e: Exception) {
            Log.w(TAG, "Could not read camera frame rate ranges: ${e.message}")
            null
        }
    }

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        // MediaPipe's live-stream mode rejects a timestamp that does not
        // increase, which two frames inside one millisecond would otherwise do.
        var frameTime = SystemClock.uptimeMillis()
        if (frameTime <= lastFrameTimeMs) frameTime = lastFrameTimeMs + 1
        lastFrameTimeMs = frameTime

        // Rows can be padded. On devices where the row stride is wider than the
        // image, copying the buffer into a bitmap exactly the image's width
        // shears every row sideways, and the detector is fed a smeared picture
        // it can barely find a hand in. The bitmap is sized to the stride and
        // the padding is cropped off below.
        val plane = imageProxy.planes[0]
        val bufferWidth = plane.rowStride / plane.pixelStride

        // The source buffer is allocated once and reused.
        //
        // It used to be reallocated on every frame, which at 30fps meant
        // throwing away a full-resolution ARGB bitmap thirty times a second.
        // The resulting garbage collection is what made the landmarks lag
        // behind the hand: the detector was not slow, it was starved by the
        // allocator. Reused here, and only replaced if the frame size changes.
        val buffer = bitmapBuffer.let { existing ->
            if (existing != null &&
                existing.width == bufferWidth &&
                existing.height == imageProxy.height
            ) {
                existing
            } else {
                Bitmap.createBitmap(
                    bufferWidth,
                    imageProxy.height,
                    Bitmap.Config.ARGB_8888
                ).also { bitmapBuffer = it }
            }
        }

        // Width and height captured before the proxy is closed below.
        val width = imageProxy.width
        val height = imageProxy.height
        val rotationDegrees = imageProxy.imageInfo.rotationDegrees
        // Some devices omit the padding after the last row, so the buffer is
        // a few bytes short of a stride-wide bitmap and copying would throw.
        // CameraX's own conversion handles that case, at the cost of one
        // allocation, so it is used only then.
        var source: Bitmap = buffer
        imageProxy.use {
            val pixels = it.planes[0].buffer
            pixels.rewind()
            if (pixels.remaining() >= buffer.byteCount) {
                buffer.copyPixelsFromBuffer(pixels)
            } else {
                source = it.toBitmap()
            }
        }

        // Handle rotation
        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
            // Mirror image for front camera
            if (cameraFacing == CameraSelector.LENS_FACING_FRONT) {
                postScale(-1f, 1f, width.toFloat(), height.toFloat())
            }
        }
        val rotatedBitmap = Bitmap.createBitmap(
            source,
            0, 0,
            width, height,
            matrix,
            // No bilinear filtering. This is fed to a landmark detector, not to
            // a display, and the smoothing costs time without adding accuracy.
            false
        )

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()

        handLandmarker?.detectAsync(mpImage, frameTime)

        // No need to close imageProxy here as it's handled by the use block
    }

    fun shutdown() {
        try {
            val displayManager =
                context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            displayManager.unregisterDisplayListener(displayListener)
        } catch (e: Exception) {
            Log.e(TAG, "Error removing display listener: ${e.message}")
        }

        // Release the camera FIRST, and on the main thread, which is where
        // CameraX requires it.
        //
        // This used to be left to the lifecycle owner on the assumption that
        // "CameraX should handle it". It does not: the lifecycle owner here is
        // the Activity, which is still very much alive when this view is
        // disposed, so the use cases stayed bound and the device kept showing
        // the camera-in-use indicator after the test had finished.
        try {
            mainHandler.post {
                try {
                    cameraProvider?.unbindAll()
                } catch (e: Exception) {
                    Log.e(TAG, "Error unbinding camera: ${e.message}")
                } finally {
                    cameraProvider = null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error posting camera release: ${e.message}")
        }

        try {
            cameraExecutor.shutdown()
            // Bounded, and never on an unbounded wait. The previous
            // Long.MAX_VALUE could block the caller — the main thread, during
            // view disposal — indefinitely if an analysis frame were stuck.
            if (!cameraExecutor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                cameraExecutor.shutdownNow()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping analysis executor: ${e.message}")
        }

        try {
            handLandmarker?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing landmarker: ${e.message}")
        } finally {
            handLandmarker = null
        }
    }

    companion object {
        private const val TAG = "HandLandmarkerHelper"
    }
}
