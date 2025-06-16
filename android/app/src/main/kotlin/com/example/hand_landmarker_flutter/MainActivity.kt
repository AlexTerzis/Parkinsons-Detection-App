package com.example.hand_landmarker_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the PlatformView factory, passing the activity as LifecycleOwner
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "hand_landmarker_view",
                HandLandmarkerFactory(flutterEngine.dartExecutor.binaryMessenger, this)
            )
    }
}
