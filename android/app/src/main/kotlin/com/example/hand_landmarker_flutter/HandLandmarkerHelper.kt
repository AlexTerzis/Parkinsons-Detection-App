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
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.util.Size
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

    private var handLandmarker: HandLandmarker? = null
    private var bitmapBuffer: Bitmap? = null
    private var frameCount = 0
    private var lastFpsTimestamp = SystemClock.elapsedRealtime()
    private var resultListener: ((HandLandmarkerResult, MPImage) -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var cameraExecutor: ExecutorService
    private var cameraFacing = CameraSelector.LENS_FACING_FRONT
    private var cameraProvider: ProcessCameraProvider? = null

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

    fun setResultListener(listener: (HandLandmarkerResult, MPImage) -> Unit) {
        resultListener = listener
    }

    private fun initHandLandmarker() {
        try {
            val baseOptionsBuilder = BaseOptions.builder()
                // Using CPU for now, GPU might need EGL setup
                .setDelegate(Delegate.CPU)
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

            handLandmarker = HandLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e(TAG, "MediaPipe failed to initialize: ${e.message}")
        }
    }

    private fun onError(error: RuntimeException) {
        Log.e(TAG, "Hand Landmarker Error: ${error.message}")
    }

    private fun onResults(result: HandLandmarkerResult, input: MPImage) {
        mainHandler.post {
            resultListener?.invoke(result, input)
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

    private fun bindCameraUseCases(cameraProvider: ProcessCameraProvider) {
        // Kept so shutdown can release the camera. Binding is tied to the
        // Activity lifecycle, which outlives this view, so nothing unbinds it
        // when the view goes away unless we do it ourselves.
        this.cameraProvider = cameraProvider

        val cameraSelector = CameraSelector.Builder().requireLensFacing(cameraFacing).build()

        // Preview Use Case
        val previewUseCase = Preview.Builder().build()
        previewUseCase.setSurfaceProvider(previewView.surfaceProvider)

        // Image Analysis Use Case
        val analysisUseCase = ImageAnalysis.Builder()
            // Capped deliberately. Every analysis frame is copied into a bitmap
            // and rotated on the CPU, so the cost of this scales with the pixel
            // count — and the landmark model downsamples its input anyway, so a
            // larger frame buys precision the detector then throws away. The
            // preview stays at full resolution; only analysis is capped.
            .setTargetResolution(Size(640, 480))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()

        analysisUseCase.setAnalyzer(cameraExecutor, this)

        // Unbind existing use cases before rebinding
        cameraProvider.unbindAll()

        try {
            // Bind use cases to camera
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                previewUseCase,
                analysisUseCase
            )
            // Update preview aspect ratio if needed, but we aren't using Preview use case directly
            // val cameraInfo = cameraProvider.bindToLifecycle(...).cameraInfo
            // val rotationDegrees = cameraInfo.sensorRotationDegrees
            // preview.targetRotation = rotationDegrees 
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        val frameTime = SystemClock.uptimeMillis()

        // The source buffer is allocated once and reused.
        //
        // It used to be reallocated on every frame, which at 30fps meant
        // throwing away a full-resolution ARGB bitmap thirty times a second.
        // The resulting garbage collection is what made the landmarks lag
        // behind the hand: the detector was not slow, it was starved by the
        // allocator. Reused here, and only replaced if the frame size changes.
        val buffer = bitmapBuffer.let { existing ->
            if (existing != null &&
                existing.width == imageProxy.width &&
                existing.height == imageProxy.height
            ) {
                existing
            } else {
                Bitmap.createBitmap(
                    imageProxy.width,
                    imageProxy.height,
                    Bitmap.Config.ARGB_8888
                ).also { bitmapBuffer = it }
            }
        }

        imageProxy.use { buffer.copyPixelsFromBuffer(it.planes[0].buffer) }

        // Handle rotation
        val rotationDegrees = imageProxy.imageInfo.rotationDegrees
        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
            // Mirror image for front camera
            if (cameraFacing == CameraSelector.LENS_FACING_FRONT) {
                postScale(-1f, 1f, imageProxy.width.toFloat(), imageProxy.height.toFloat())
            }
        }
        val rotatedBitmap = Bitmap.createBitmap(
            buffer,
            0, 0,
            imageProxy.width, imageProxy.height,
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
