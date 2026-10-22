package io.appsmaker.racketmates

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Receives FCM messages. While the app is closed or in the background the
 * system shows `notification` messages itself and delivers their data to
 * [MainActivity] when tapped; here only the foreground case is handled, by
 * passing the message to Flutter, which shows it in the app.
 */
class RacketmatesMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        PushPlugin.emitToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        PushPlugin.emitForeground(
            mapOf(
                "id" to message.messageId,
                "title" to message.notification?.title,
                "body" to message.notification?.body,
                "data" to message.data,
            ),
        )
    }
}
