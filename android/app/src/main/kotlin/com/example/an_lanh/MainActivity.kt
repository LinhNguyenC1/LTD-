package com.example.an_lanh

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
	override fun getRenderMode(): RenderMode {
		return RenderMode.texture
	}
}
