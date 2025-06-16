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
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmark
import kotlin.math.max
import kotlin.math.min

class OverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var results: HandLandmarkerResult? = null
    private var scaleFactor: Float = 1f
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1
    
    // Add variables for translation offsets
    private var imageTranslateX: Float = 0f
    private var imageTranslateY: Float = 0f

    private val landmarkPaint = Paint().apply {
        color = Color.RED
        strokeWidth = LANDMARK_STROKE_WIDTH
        style = Paint.Style.FILL
    }
    private val connectionPaint = Paint().apply {
        color = Color.GREEN
        strokeWidth = CONNECTION_STROKE_WIDTH
        style = Paint.Style.STROKE
    }

    fun setResults(
        handLandmarkerResults: HandLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int,
        runningMode: RunningMode = RunningMode.IMAGE
    ) {
        results = handLandmarkerResults
        this.imageHeight = imageHeight
        this.imageWidth = imageWidth

        // Calculate the scaling factor and translation offsets
        val viewWidth = width
        val viewHeight = height

        scaleFactor = when (runningMode) {
            RunningMode.IMAGE, RunningMode.VIDEO -> {
                min(viewWidth * 1f / imageWidth, viewHeight * 1f / imageHeight)
            }
            RunningMode.LIVE_STREAM -> {
                // Handles potentially different aspect ratios using max scale factor.
                // This assumes the PreviewView is using a scale type like FILL_CENTER or CENTER_CROP.
                max(viewWidth * 1f / imageWidth, viewHeight * 1f / imageHeight)
            }
        }

        val scaledImageWidth = imageWidth * scaleFactor
        val scaledImageHeight = imageHeight * scaleFactor

        // Calculate offsets to center the scaled image within the view
        imageTranslateX = (viewWidth - scaledImageWidth) / 2f
        imageTranslateY = (viewHeight - scaledImageHeight) / 2f

        invalidate()
    }

    override fun draw(canvas: Canvas) {
        super.draw(canvas)
        
        results?.let { result ->
            for (landmarks in result.landmarks()) {
                // Draw landmarks
                for (landmark in landmarks) {
                    canvas.drawCircle(
                        landmark.x() * imageWidth * scaleFactor + imageTranslateX,
                        landmark.y() * imageHeight * scaleFactor + imageTranslateY,
                        LANDMARK_RADIUS,
                        landmarkPaint
                    )
                }
                
                // Draw connections
                HAND_CONNECTIONS.forEach { connection ->
                    val start = landmarks[connection.first]
                    val end = landmarks[connection.second]
                    
                    canvas.drawLine(
                        start.x() * imageWidth * scaleFactor + imageTranslateX,
                        start.y() * imageHeight * scaleFactor + imageTranslateY,
                        end.x() * imageWidth * scaleFactor + imageTranslateX,
                        end.y() * imageHeight * scaleFactor + imageTranslateY,
                        connectionPaint
                    )
                }
            }
        }
    }

    companion object {
        private const val LANDMARK_STROKE_WIDTH = 8F
        private const val CONNECTION_STROKE_WIDTH = 5F
        private const val LANDMARK_RADIUS = 8F
        
        // Hand connections based on MediaPipe hand landmark model
        private val HAND_CONNECTIONS = listOf(
            // Thumb
            Pair(HandLandmark.WRIST, HandLandmark.THUMB_CMC),
            Pair(HandLandmark.THUMB_CMC, HandLandmark.THUMB_MCP),
            Pair(HandLandmark.THUMB_MCP, HandLandmark.THUMB_IP),
            Pair(HandLandmark.THUMB_IP, HandLandmark.THUMB_TIP),
            
            // Index finger
            Pair(HandLandmark.WRIST, HandLandmark.INDEX_FINGER_MCP),
            Pair(HandLandmark.INDEX_FINGER_MCP, HandLandmark.INDEX_FINGER_PIP),
            Pair(HandLandmark.INDEX_FINGER_PIP, HandLandmark.INDEX_FINGER_DIP),
            Pair(HandLandmark.INDEX_FINGER_DIP, HandLandmark.INDEX_FINGER_TIP),
            
            // Middle finger
            Pair(HandLandmark.WRIST, HandLandmark.MIDDLE_FINGER_MCP),
            Pair(HandLandmark.MIDDLE_FINGER_MCP, HandLandmark.MIDDLE_FINGER_PIP),
            Pair(HandLandmark.MIDDLE_FINGER_PIP, HandLandmark.MIDDLE_FINGER_DIP),
            Pair(HandLandmark.MIDDLE_FINGER_DIP, HandLandmark.MIDDLE_FINGER_TIP),
            
            // Ring finger
            Pair(HandLandmark.WRIST, HandLandmark.RING_FINGER_MCP),
            Pair(HandLandmark.RING_FINGER_MCP, HandLandmark.RING_FINGER_PIP),
            Pair(HandLandmark.RING_FINGER_PIP, HandLandmark.RING_FINGER_DIP),
            Pair(HandLandmark.RING_FINGER_DIP, HandLandmark.RING_FINGER_TIP),
            
            // Pinky
            Pair(HandLandmark.WRIST, HandLandmark.PINKY_MCP),
            Pair(HandLandmark.PINKY_MCP, HandLandmark.PINKY_PIP),
            Pair(HandLandmark.PINKY_PIP, HandLandmark.PINKY_DIP),
            Pair(HandLandmark.PINKY_DIP, HandLandmark.PINKY_TIP),
            
            // Palm
            Pair(HandLandmark.INDEX_FINGER_MCP, HandLandmark.MIDDLE_FINGER_MCP),
            Pair(HandLandmark.MIDDLE_FINGER_MCP, HandLandmark.RING_FINGER_MCP),
            Pair(HandLandmark.RING_FINGER_MCP, HandLandmark.PINKY_MCP)
        )
    }
}
