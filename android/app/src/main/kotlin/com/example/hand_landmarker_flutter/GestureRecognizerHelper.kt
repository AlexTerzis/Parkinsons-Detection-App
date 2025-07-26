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
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizer
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizerResult
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class GestureRecognizerHelper(
    private val context: Context,
    private val previewView: PreviewView,
    private val lifecycleOwner: LifecycleOwner
) : ImageAnalysis.Analyzer {

    private var recognizer: GestureRecognizer? = null
    private var bitmapBuffer: Bitmap? = null
    private var resultListener: ((GestureRecognizerResult) -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var cameraExecutor: ExecutorService
    private var cameraFacing = CameraSelector.LENS_FACING_FRONT

    init {
        initRecognizer()
        cameraExecutor = Executors.newSingleThreadExecutor()
    }

    fun setResultListener(listener: (GestureRecognizerResult) -> Unit) {
        resultListener = listener
    }

    private fun initRecognizer() {
        try {
            val baseOptions = BaseOptions.builder()
                .setDelegate(Delegate.CPU)
                .setModelAssetPath("gesture_recognizer.task")
                .build()

            val options = GestureRecognizer.GestureRecognizerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setResultListener { result, _ ->
                    mainHandler.post { resultListener?.invoke(result) }
                }
                .setErrorListener { e ->
                    Log.e(TAG, "Gesture recognizer error: ${e.message}")
                }
                .build()

            recognizer = GestureRecognizer.createFromOptions(context, options)
            Log.d(TAG, "GestureRecognizer model loaded successfully!")
        } catch (e: Exception) {
            Log.e(TAG, "MediaPipe failed to initialize: ${e.message}")
        }
    }

    fun setupCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val provider = cameraProviderFuture.get()
            bindCameraUseCases(provider)
            Log.d(TAG, "Camera setup complete!")
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindCameraUseCases(cameraProvider: ProcessCameraProvider) {
        val cameraSelector = CameraSelector.Builder().requireLensFacing(cameraFacing).build()
        val previewUseCase = Preview.Builder().build().also {
            it.setSurfaceProvider(previewView.surfaceProvider)
        }
        val analysisUseCase = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysisUseCase.setAnalyzer(cameraExecutor, this)

        cameraProvider.unbindAll()
        try {
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                previewUseCase,
                analysisUseCase
            )
            Log.d(TAG, "Camera use cases bound!")
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        try {
            val frameTime = SystemClock.uptimeMillis()
            bitmapBuffer = Bitmap.createBitmap(
                imageProxy.width,
                imageProxy.height,
                Bitmap.Config.ARGB_8888
            )

            bitmapBuffer?.copyPixelsFromBuffer(imageProxy.planes[0].buffer)
            if (bitmapBuffer == null) {
                return
            }

            val rotationDegrees = imageProxy.imageInfo.rotationDegrees
            val matrix = Matrix().apply {
                postRotate(rotationDegrees.toFloat())
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
            recognizer?.recognizeAsync(mpImage, frameTime)
        } catch (e: Exception) {
            Log.e(TAG, "Error analyzing image: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }

    fun shutdown() {
        try {
            cameraExecutor.shutdown()
            cameraExecutor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS)
            recognizer?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error shutting down: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "GestureRecognizerHelper"
    }
}
