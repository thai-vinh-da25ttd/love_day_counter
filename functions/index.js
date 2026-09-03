import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

export const onLoveReactionCreated = onDocumentCreated(
  'couples/{coupleId}/reactions/{reactionId}',
  async (event) => {
    const reaction = event.data?.data();
    if (!reaction) return;

    const { coupleId } = event.params;
    const fromUid = String(reaction.fromUid ?? '');
    const toUid = String(reaction.toUid ?? '');
    if (!fromUid || !toUid || fromUid === toUid) return;

    const [senderSnap, targetSnap] = await Promise.all([
      db.doc(`users/${fromUid}`).get(),
      db.doc(`users/${toUid}`).get(),
    ]);

    const senderName = senderSnap.data()?.displayName || 'Người ấy';
    const token = targetSnap.data()?.fcmToken;
    if (!token) {
      logger.info('Partner has no FCM token', { toUid, coupleId });
      return;
    }

    try {
      await messaging.send({
        token,
        notification: {
          title: 'Người ấy gửi yêu thương ❤️',
          body: `${senderName} vừa gửi một trái tim cho bạn.`,
        },
        data: {
          type: 'love',
          coupleId,
          fromUid,
          toUid,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'love_messages',
            sound: 'default',
            vibrateTimingsMillis: [0, 120, 80, 120],
          },
        },
      });
    } catch (error) {
      logger.error('Unable to send love notification', error);
      // Remove stale tokens so future sends do not repeatedly fail.
      const code = error?.code;
      if (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token') {
        await db.doc(`users/${toUid}`).set({ fcmToken: null }, { merge: true });
      }
    }
  },
);
