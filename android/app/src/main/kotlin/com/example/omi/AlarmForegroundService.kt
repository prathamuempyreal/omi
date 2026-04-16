package com.example.omi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    companion object {
        private const val actionStart = "START"
        private const val actionStop = "STOP"
        private const val channelId = "omi_alarms"
        private const val notificationId = 4101
        private const val TAG = "AlarmService"

        private var mediaPlayer: MediaPlayer? = null
        private var isAlarmPlaying = false
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand action = ${intent?.action}")
        when (intent?.action) {
            actionStart -> startAlarm()
            actionStop -> stopAlarm()
        }
        return START_NOT_STICKY
    }

    private fun startAlarm() {
        if (isAlarmPlaying) {
            Log.d(TAG, "Alarm already playing")
            return
        }
        
        Log.d(TAG, "Starting alarm...")
        
        // Play alarm sound using MediaPlayer for continuous looping
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                val afd = resources.openRawResourceFd(R.raw.alarm_sound)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                prepare()
                start()
            }
            isAlarmPlaying = true
            Log.d(TAG, "MediaPlayer started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting MediaPlayer: ${e.message}")
            e.printStackTrace()
        }

        // Also show notification
        createNotificationChannel()
        startForeground(notificationId, buildNotification())
    }

    private fun stopAlarm() {
        Log.d(TAG, "Stopping alarm...")
        isAlarmPlaying = false
        
        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping MediaPlayer: ${e.message}")
        }
        mediaPlayer = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
        Log.d(TAG, "Alarm stopped")
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Omi Alarm")
            .setContentText("Alarm is ringing - tap to stop")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            channelId,
            "Omi Alarms",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.setSound(null, null)
        manager.createNotificationChannel(channel)
    }
}
