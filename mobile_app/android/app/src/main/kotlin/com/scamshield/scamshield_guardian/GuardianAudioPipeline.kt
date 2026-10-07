package com.scamshield.scamshield_guardian

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.ArrayDeque
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max

object GuardianAudioPipeline {
    const val SAMPLE_RATE_HZ = 16_000
    const val CHANNEL_COUNT = 1
    const val ENCODING = "PCM_16BIT"
    const val CHUNK_DURATION_MS = 5_000
    const val MAX_BUFFERED_CHUNKS = 2
    private const val BYTES_PER_SAMPLE = 2
    private const val TAG = "ScamShieldAudio"

    data class Snapshot(
        val state: String,
        val source: String,
        val route: String,
        val reason: String,
        val chunksCreated: Int,
        val chunksDropped: Int,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "state" to state,
            "source" to source,
            "route" to route,
            "reason" to reason,
            "chunksCreated" to chunksCreated,
            "chunksDropped" to chunksDropped,
        )
    }

    private data class AudioChunk(
        val id: String,
        val sessionId: String,
        val sequence: Int,
        val timestamp: Long,
        val bytes: ByteArray,
    )

    private val chunks = ArrayDeque<AudioChunk>()
    private var recorder: AudioRecord? = null
    private var captureThread: Thread? = null
    private var stopRequested: AtomicBoolean? = null
    private var activeSessionId: String? = null
    private var statusListener: (() -> Unit)? = null
    private var chunkListener: ((Map<String, Any>) -> Unit)? = null
    private var audioManager: AudioManager? = null
    private var deviceCallback: AudioDeviceCallback? = null
    private var state = "IDLE"
    private var source = ""
    private var route = "UNKNOWN"
    private var reason = ""
    private var chunksCreated = 0
    private var chunksDropped = 0

    @Synchronized
    fun setListeners(
        onStatusChanged: (() -> Unit)?,
        onChunkAvailable: ((Map<String, Any>) -> Unit)?,
    ) {
        statusListener = onStatusChanged
        chunkListener = onChunkAvailable
    }

    @Synchronized
    fun setChunkListener(onChunkAvailable: ((Map<String, Any>) -> Unit)?) {
        chunkListener = onChunkAvailable
    }

    @Synchronized
    fun setStatusListener(onStatusChanged: (() -> Unit)?) {
        statusListener = onStatusChanged
    }

    @Synchronized
    fun snapshot(): Snapshot = Snapshot(
        state = state,
        source = source,
        route = route,
        reason = reason,
        chunksCreated = chunksCreated,
        chunksDropped = chunksDropped,
    )

    @Synchronized
    fun start(context: Context, sessionId: String?) {
        if (state == "AUDIO_INITIALIZING" || state == "AUDIO_READY" ||
            state == "AUDIO_STREAMING"
        ) {
            return
        }
        clearBufferedChunks()
        activeSessionId = sessionId ?: UUID.randomUUID().toString()
        chunksCreated = 0
        chunksDropped = 0
        source = "DEVICE_MICROPHONE"
        route = "UNKNOWN"
        reason = ""
        state = "AUDIO_INITIALIZING"
        publishStatus()

        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            fail("Microphone permission is not granted.")
            return
        }
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)) {
            fail("This device does not report a microphone.")
            return
        }

        val chunkBytes = SAMPLE_RATE_HZ * CHANNEL_COUNT * BYTES_PER_SAMPLE *
            CHUNK_DURATION_MS / 1_000
        val minimumBufferBytes = AudioRecord.getMinBufferSize(
            SAMPLE_RATE_HZ,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minimumBufferBytes <= 0) {
            fail("Android reported that this microphone format is unavailable.")
            return
        }

        val activeRecorder = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE_HZ,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                max(minimumBufferBytes, chunkBytes),
            )
        } catch (error: IllegalArgumentException) {
            fail("Android could not initialize the device microphone.", error)
            return
        } catch (error: SecurityException) {
            fail("Android denied microphone access.", error)
            return
        }
        if (activeRecorder.state != AudioRecord.STATE_INITIALIZED) {
            activeRecorder.release()
            fail("Android could not initialize the device microphone.")
            return
        }

        try {
            activeRecorder.startRecording()
        } catch (error: IllegalStateException) {
            activeRecorder.release()
            fail("Android could not start microphone capture.", error)
            return
        } catch (error: SecurityException) {
            activeRecorder.release()
            fail("Android denied microphone capture.", error)
            return
        }
        if (activeRecorder.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            activeRecorder.release()
            fail("Android did not start microphone capture.")
            return
        }

        recorder = activeRecorder
        stopRequested = AtomicBoolean(false)
        route = inputRoute(activeRecorder.routedDevice)
        state = "AUDIO_READY"
        publishStatus()
        registerRouteCallback(context.applicationContext)

        val session = activeSessionId ?: UUID.randomUUID().toString()
        val stopFlag = stopRequested ?: AtomicBoolean(true)
        val reader = Thread(
            { capture(activeRecorder, stopFlag, session, chunkBytes) },
            "ScamShieldAudioCapture",
        )
        reader.isDaemon = true
        captureThread = reader
        reader.start()
    }

    fun stop() {
        val activeRecorder: AudioRecord?
        val reader: Thread?
        synchronized(this) {
            stopRequested?.set(true)
            activeRecorder = recorder
            reader = captureThread
            recorder = null
            captureThread = null
            stopRequested = null
            activeSessionId = null
            unregisterRouteCallback()
            clearBufferedChunks()
            state = "IDLE"
            source = ""
            route = "UNKNOWN"
            reason = ""
            publishStatus()
        }
        if (activeRecorder != null) {
            try {
                if (activeRecorder.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    activeRecorder.stop()
                }
            } catch (error: IllegalStateException) {
                Log.w(TAG, "Microphone capture stopped with an invalid recorder state.")
            } finally {
                activeRecorder.release()
            }
        }
        reader?.join(250)
    }

    @Synchronized
    fun markUnavailable(message: String) {
        stopRequested?.set(true)
        val activeRecorder = recorder
        recorder = null
        activeSessionId = null
        clearBufferedChunks()
        state = "AUDIO_UNAVAILABLE"
        source = "DEVICE_MICROPHONE"
        route = "UNKNOWN"
        reason = message
        publishStatus()
        activeRecorder?.let {
            try {
                if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    it.stop()
                }
            } catch (_: IllegalStateException) {
                Log.w(TAG, "Unable to stop microphone capture after service restriction.")
            } finally {
                it.release()
            }
        }
        unregisterRouteCallback()
    }

    @Synchronized
    fun takeNextChunk(): Map<String, Any>? {
        val chunk = chunks.pollFirst() ?: return null
        return mapOf(
            "chunkId" to chunk.id,
            "sessionId" to chunk.sessionId,
            "sequenceNumber" to chunk.sequence,
            "timestamp" to chunk.timestamp,
            "durationMs" to CHUNK_DURATION_MS,
            "sampleRateHz" to SAMPLE_RATE_HZ,
            "channels" to CHANNEL_COUNT,
            "encoding" to ENCODING,
            "source" to source,
            "audioData" to chunk.bytes,
        )
    }

    private fun capture(
        activeRecorder: AudioRecord,
        stopFlag: AtomicBoolean,
        sessionId: String,
        chunkBytes: Int,
    ) {
        val scratch = ByteArray(8_192)
        val chunk = ByteArray(chunkBytes)
        var chunkOffset = 0
        var sequence = 0
        try {
            while (!stopFlag.get()) {
                val bytesRead = activeRecorder.read(scratch, 0, scratch.size)
                if (bytesRead < 0) {
                    if (!stopFlag.get()) {
                        failFromCapture("Android stopped providing microphone audio.")
                    }
                    return
                }
                if (bytesRead == 0) continue
                var sourceOffset = 0
                while (sourceOffset < bytesRead && !stopFlag.get()) {
                    val count = minOf(bytesRead - sourceOffset, chunkBytes - chunkOffset)
                    System.arraycopy(scratch, sourceOffset, chunk, chunkOffset, count)
                    sourceOffset += count
                    chunkOffset += count
                    if (chunkOffset == chunkBytes) {
                        sequence += 1
                        emitChunk(sessionId, sequence, chunk.copyOf())
                        chunkOffset = 0
                    }
                }
            }
        } catch (error: SecurityException) {
            if (!stopFlag.get()) failFromCapture("Android revoked microphone access.", error)
        } catch (error: IllegalStateException) {
            if (!stopFlag.get()) failFromCapture("Microphone capture stopped unexpectedly.", error)
        }
    }

    @Synchronized
    private fun emitChunk(sessionId: String, sequence: Int, data: ByteArray) {
        if (activeSessionId != sessionId ||
            state == "IDLE" ||
            state == "AUDIO_UNAVAILABLE"
        ) {
            return
        }
        if (chunks.size == MAX_BUFFERED_CHUNKS) {
            chunks.removeFirst()
            chunksDropped += 1
        }
        val chunk = AudioChunk(
            id = UUID.randomUUID().toString(),
            sessionId = sessionId,
            sequence = sequence,
            timestamp = System.currentTimeMillis(),
            bytes = data,
        )
        chunks.addLast(chunk)
        chunksCreated += 1
        state = "AUDIO_STREAMING"
        route = inputRoute(recorder?.routedDevice)
        val metadata = mapOf(
            "event" to "audioChunkAvailable",
            "chunkId" to chunk.id,
            "sessionId" to chunk.sessionId,
            "sequenceNumber" to chunk.sequence,
            "timestamp" to chunk.timestamp,
            "durationMs" to CHUNK_DURATION_MS,
            "sampleRateHz" to SAMPLE_RATE_HZ,
            "channels" to CHANNEL_COUNT,
            "encoding" to ENCODING,
            "source" to source,
        )
        publishStatus()
        chunkListener?.invoke(metadata)
    }

    private fun failFromCapture(message: String, error: Exception? = null) {
        synchronized(this) {
            if (state == "IDLE" || state == "AUDIO_UNAVAILABLE") return
            state = "AUDIO_UNAVAILABLE"
            reason = message
            clearBufferedChunks()
            stopRequested?.set(true)
            val activeRecorder = recorder
            recorder = null
            if (error == null) {
                Log.w(TAG, message)
            } else {
                Log.w(TAG, message, error)
            }
            publishStatus()
            activeRecorder?.let {
                try {
                    it.stop()
                } catch (_: IllegalStateException) {
                    Log.w(TAG, "Unable to stop the unavailable microphone recorder.")
                } finally {
                    it.release()
                }
            }
        }
    }

    private fun fail(message: String, error: Exception? = null) {
        state = "AUDIO_UNAVAILABLE"
        reason = message
        if (error == null) {
            Log.w(TAG, message)
        } else {
            Log.w(TAG, message, error)
        }
        publishStatus()
    }

    private fun registerRouteCallback(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val manager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return
        audioManager = manager
        val callback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                updateRoute()
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                updateRoute()
            }
        }
        deviceCallback = callback
        manager.registerAudioDeviceCallback(callback, null)
    }

    @Synchronized
    private fun updateRoute() {
        route = inputRoute(recorder?.routedDevice)
        publishStatus()
    }

    private fun unregisterRouteCallback() {
        val manager = audioManager
        val callback = deviceCallback
        if (manager != null && callback != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            manager.unregisterAudioDeviceCallback(callback)
        }
        audioManager = null
        deviceCallback = null
    }

    private fun inputRoute(device: AudioDeviceInfo?): String {
        if (device == null) return "UNKNOWN"
        return when (device.type) {
            AudioDeviceInfo.TYPE_BUILTIN_MIC -> "DEVICE_MICROPHONE"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "BLUETOOTH_MICROPHONE"
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> "WIRED_HEADSET_MICROPHONE"
            AudioDeviceInfo.TYPE_USB_HEADSET -> "USB_HEADSET_MICROPHONE"
            else -> "OTHER_MICROPHONE"
        }
    }

    @Synchronized
    private fun publishStatus() {
        statusListener?.invoke()
    }

    private fun clearBufferedChunks() {
        chunks.clear()
    }
}
