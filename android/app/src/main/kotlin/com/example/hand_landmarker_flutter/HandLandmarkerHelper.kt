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
        val cameraSelector = CameraSelector.Builder().requireLensFacing(cameraFacing).build()

        // Preview Use Case
        val previewUseCase = Preview.Builder().build()
        previewUseCase.setSurfaceProvider(previewView.surfaceProvider)

        // Image Analysis Use Case
        val analysisUseCase = ImageAnalysis.Builder()
            // Set target resolution if needed, defaults may work
            // .setTargetResolution(Size(1280, 720))
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
        
        bitmapBuffer = Bitmap.createBitmap(
            imageProxy.width,
            imageProxy.height,
            Bitmap.Config.ARGB_8888
        )
        
        imageProxy.use { bitmapBuffer?.copyPixelsFromBuffer(imageProxy.planes[0].buffer) }
        if (bitmapBuffer == null) {
            imageProxy.close()
            return
        }

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
            bitmapBuffer!!,
            0, 0,
            imageProxy.width, imageProxy.height,
            matrix, true
        )

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()

        handLandmarker?.detectAsync(mpImage, frameTime)
        
        // No need to close imageProxy here as it's handled by the use block
    }

    fun shutdown() {
        try {
            cameraExecutor.shutdown()
            cameraExecutor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS)
            handLandmarker?.close()
            // It might be good practice to unbind use cases here too, but CameraX should handle it with lifecycle
        } catch (e: Exception) {
            Log.e(TAG, "Error shutting down: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "HandLandmarkerHelper"
    }
}
