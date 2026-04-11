package com.example.vton_auth

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.ImageButton
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.snap.camerakit.Session
import com.snap.camerakit.invoke                          // ← CRITICAL: enables Session() lambda
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.whenHasSome
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource

class CameraKitActivity : AppCompatActivity() {

    private var cameraKitSession: Session? = null
    private val CAMERA_PERMISSION_REQUEST = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera_kit)

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                CAMERA_PERMISSION_REQUEST
            )
        } else {
            startCameraKit()
        }

        findViewById<ImageButton>(R.id.btn_close).setOnClickListener {
            finish()
        }
    }

    private fun startCameraKit() {
        val lensGroupId = intent.getStringExtra("lens_group_id")
            ?: "12433cb9-95e5-4ecc-a9b4-9cbad9b43e7b"
        val lensId = intent.getStringExtra("lens_id")
            ?: "2ce6c480-9472-4b71-8451-da1e33f06a59"

        val imageProcessorSource = CameraXImageProcessorSource(
            context = this,
            lifecycleOwner = this
        )
        imageProcessorSource.startPreview(true)

        // Now works because camerakit-kotlin is in dependencies
        cameraKitSession = Session(context = this) {
            imageProcessorSource(imageProcessorSource)
            attachTo(findViewById(R.id.camera_kit_stub))
        }

        cameraKitSession?.lenses?.repository?.observe(
            LensesComponent.Repository.QueryCriteria.Available(
                groupIds = setOf(lensGroupId)
            )
        ) { result ->
            result.whenHasSome { lenses ->
                val targetLens = lenses.find { it.id == lensId } ?: lenses.firstOrNull()
                targetLens?.let {
                    cameraKitSession?.lenses?.processor?.apply(it)
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            startCameraKit()
        } else {
            Toast.makeText(this, "Camera permission required", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraKitSession?.close()
    }
}