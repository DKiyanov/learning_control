package com.dkiyanov.learning_control;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

import androidx.core.app.NotificationCompat;

public class LCForegroundService extends Service {
    private static final String TAG = "learning_control LCForegroundService";

    private NotificationManager notificationManager;
    private static final int NOTIFICATION_ID = 101;
    private static final String NOTIFICATION_CHANNEL_ID = "my_channel_id_01";

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId){
        String action = intent.getAction();
        if ("StopService".equals(action)) {
            stopSelf();
            return START_REDELIVER_INTENT;
        }

        String title = intent.getStringExtra("title");
        String text  = intent.getStringExtra("text");

        if (notificationManager == null) {
            sendNotification(this, text, title, text);
        } else {
            updateNotification(this, text, title, text);
        }

        return START_REDELIVER_INTENT;
    }

    private void initNotificationChannel() {
        if (notificationManager != null) return;
        notificationManager = (NotificationManager) this.getSystemService(NOTIFICATION_SERVICE);

        NotificationChannel notificationChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, "My Notifications", NotificationManager.IMPORTANCE_DEFAULT);
        notificationChannel.setDescription("Channel description");
        notificationManager.createNotificationChannel(notificationChannel);
    }

    private void sendNotification(Context context, String ticker, String title, String text) {
        initNotificationChannel();
        Notification notification = getNotification(context, ticker, title, text);
        startForeground(NOTIFICATION_ID, notification);
    }

    private Notification getNotification(Context context, String ticker, String title, String text) {
        //These three lines makes Notification to open main activity after clicking on it
        Intent notificationIntent = new Intent(context, MainActivity.class);
        notificationIntent.setAction(Intent.ACTION_MAIN);
        notificationIntent.addCategory(Intent.CATEGORY_LAUNCHER);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID);
        builder.setContentIntent(contentIntent)
                .setOngoing(true)   //Can't be swiped out
                .setSmallIcon(R.mipmap.ic_launcher)
                .setTicker(ticker)
                .setContentTitle(title) //Заголовок
                .setContentText(text) // Текст уведомления
                .setWhen(System.currentTimeMillis());

        return builder.build();
    }

    private void updateNotification(Context context, String ticker, String title, String text) {
        Notification notification = getNotification(context, ticker, title, text);
        notificationManager.notify(NOTIFICATION_ID, notification);
    }


    @Override
    public void onDestroy() {
        Log.d(TAG, "Destroyed");
        notificationManager.cancel(NOTIFICATION_ID);
        super.onDestroy();
    }
}