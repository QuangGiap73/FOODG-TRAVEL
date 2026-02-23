import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

// Khoi tao Firebase Admin (bat buoc de dung Firestore + FCM)
admin.initializeApp();

// Gioi han so instance (giam chi phi)
setGlobalOptions({maxInstances: 10});

const db = admin.firestore();

/**
 * Lay danh sach FCM token cua user.
 * - Token duoc luu o users/{uid}/fcmTokens/{token}
 */
async function getUserTokens(uid: string): Promise<string[]> {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();
  return snap.docs.map((d) => d.id).filter((t) => t);
}

/**
 * Tao thong bao trong Firestore.
 * - Luu o users/{ownerId}/notifications
 */
async function createNotification(params: {
  ownerId: string;
  type: "like" | "comment";
  postId: string;
  actorId: string;
  actorName: string;
  actorPhoto: string;
  snippet?: string;
}) {
  const ref = db
    .collection("users")
    .doc(params.ownerId)
    .collection("notifications")
    .doc();

  await ref.set({
    type: params.type,
    postId: params.postId,
    actorId: params.actorId,
    actorName: params.actorName,
    actorPhoto: params.actorPhoto,
    snippet: params.snippet ?? "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });
}

/**
 * Gui push notification ve may.
 * - Lay token cua ownerId
 * - Gui push toi tat ca token do
 */
async function sendPush(
  ownerId: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  // Lay danh sach token cua chu bai viet
  const tokens = await getUserTokens(ownerId);
  if (tokens.length === 0) return;

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data,
  });
}

// ============================
// LIKE -> thong bao + push
// ============================
export const onPostLikeCreate = onDocumentCreated(
  "posts/{postId}/likes/{uid}",
  async (event) => {
    // postId: bai viet bi like
    const postId = event.params.postId as string;
    // actorId: nguoi da like
    const actorId = event.params.uid as string;

    // Lay bai viet de biet chu bai (authorId)
    const postSnap = await db.collection("posts").doc(postId).get();
    if (!postSnap.exists) return;
    const post = postSnap.data() || {};
    const ownerId = post.authorId as string | undefined;

    // Neu tu like bai cua minh -> bo qua
    if (!ownerId || ownerId === actorId) return;

    // Lay thong tin nguoi like
    const userSnap = await db.collection("users").doc(actorId).get();
    const user = userSnap.data() || {};
    const actorName = (user.fullName || "Nguoi dung") as string;
    const actorPhoto = (user.photoUrl || "") as string;

    // Tao thong bao (luu DB)
    await createNotification({
      ownerId,
      type: "like",
      postId,
      actorId,
      actorName,
      actorPhoto,
    });

    // Gui push toi chu bai viet
    await sendPush(
      ownerId,
      "Co nguoi thich bai viet",
      `${actorName} da thich bai viet cua ban`,
      {type: "like", postId},
    );

    logger.info("Like notification sent", {
      postId,
      ownerId,
      actorId,
    });
  },
);

// ============================
// COMMENT -> thong bao + push
// ============================
export const onPostCommentCreate = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const postId = event.params.postId as string;
    // Du lieu comment vua tao
    const data = event.data?.data() || {};
    const actorId = (data.authorId || "") as string;

    // Lay bai viet de biet chu bai (authorId)
    const postSnap = await db.collection("posts").doc(postId).get();
    if (!postSnap.exists) return;
    const post = postSnap.data() || {};
    const ownerId = post.authorId as string | undefined;

    // Neu tu comment bai cua minh -> bo qua
    if (!ownerId || ownerId === actorId) return;

    const actorName = (data.authorName || "Nguoi dung") as string;
    const actorPhoto = (data.authorPhoto || "") as string;
    const snippet = ((data.text || "") as string).slice(0, 80);

    // Tao thong bao (luu DB)
    await createNotification({
      ownerId,
      type: "comment",
      postId,
      actorId,
      actorName,
      actorPhoto,
      snippet,
    });

    // Gui push toi chu bai viet
    await sendPush(
      ownerId,
      "Co binh luan moi",
      `${actorName}: ${snippet}`,
      {type: "comment", postId},
    );

    logger.info("Comment notification sent", {
      postId,
      ownerId,
      actorId,
    });
  },
);
