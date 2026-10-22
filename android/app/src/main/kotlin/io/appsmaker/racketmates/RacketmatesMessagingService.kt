package io.appsmaker.racketmates

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject

/**
 * Receives FCM messages. While the app is closed or in the background the
 * system shows `notification` messages itself and delivers their data to
 * [MainActivity] when tapped. Chat messages are different: Sendbird sends them
 * as data only (the `sendbird` key), so they are turned into a notification
 * here. While the app is open Flutter shows the message itself.
 */
class RacketmatesMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        PushPlugin.emitToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val sendbird = message.data["sendbird"]
        val chat = sendbird?.let(::parseChat)
        val shownInApp = PushPlugin.emitForeground(
            mapOf(
                "id" to message.messageId,
                "title" to (message.notification?.title ?: chat?.title),
                "body" to (message.notification?.body ?: chat?.body),
                "data" to message.data,
            ),
        )
        if (!shownInApp && chat != null && message.notification == null) {
            showChatNotification(message, chat)
        }
    }

    private data class Chat(val title: String, val body: String)

    private fun parseChat(json: String): Chat? =
        try {
            val payload = JSONObject(json)
            val sender = payload.optJSONObject("sender")?.optString("name").orEmpty()
            val title = payload.optString("push_title").ifEmpty { sender }
            val body = payload.optString("message")
            if (body.isEmpty()) null else Chat(title, body)
        } catch (_: Exception) {
            null
        }

    private fun showChatNotification(message: RemoteMessage, chat: Chat) {
        val canNotify = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (!canNotify) return
        PushPlugin.createChannel(this)
        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            // The same extras the system adds to a notification it shows itself.
            putExtra("google.message_id", message.messageId ?: System.currentTimeMillis().toString())
            message.data.forEach { (key, value) -> putExtra(key, value) }
        }
        val id = (message.messageId ?: System.currentTimeMillis().toString()).hashCode()
        val pending = PendingIntent.getActivity(
            this,
            id,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, PushPlugin.CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(chat.title)
            .setContentText(chat.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(chat.body))
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        NotificationManagerCompat.from(this).notify(id, notification)
    }
}
