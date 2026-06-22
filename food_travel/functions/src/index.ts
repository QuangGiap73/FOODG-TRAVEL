import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
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
 * Tao thong bao hanh trinh sau khi check-in.
 * - Luu o users/{ownerId}/notifications
 */
async function createJourneyNotification(params: {
  ownerId: string;
  checkinId: string;
  placeName: string;
  provinceName?: string;
  pointsEarned: number;
  currentStreak: number;
}) {
  const ref = db
    .collection("users")
    .doc(params.ownerId)
    .collection("notifications")
    .doc();

  const locationText = params.provinceName ?
    `${params.placeName}, ${params.provinceName}` :
    params.placeName;
  const streakText = params.currentStreak > 1 ?
    ` Chuoi hien tai ${params.currentStreak} ngay.` :
    "";

  await ref.set({
    type: "journey_checkin",
    postId: "",
    actorId: "system",
    actorName: "Hanh trinh am thuc",
    actorPhoto: "",
    snippet:
      `Ban vua check-in tai ${locationText} ` +
      `va nhan ${params.pointsEarned} diem.${streakText}`,
    checkinId: params.checkinId,
    placeName: params.placeName,
    provinceName: params.provinceName ?? "",
    pointsEarned: params.pointsEarned,
    currentStreak: params.currentStreak,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });
}

/**
 * Tao thong bao khi mo khoa huy hieu.
 */
async function createJourneyBadgeNotification(params: {
  ownerId: string;
  badgeId: string;
  title: string;
  description: string;
}) {
  const ref = db
    .collection("users")
    .doc(params.ownerId)
    .collection("notifications")
    .doc();

  await ref.set({
    type: "journey_badge",
    postId: "",
    actorId: "system",
    actorName: "Hanh trinh am thuc",
    actorPhoto: "",
    snippet: `Ban vua mo khoa huy hieu ${params.title}.`,
    badgeId: params.badgeId,
    badgeTitle: params.title,
    badgeDescription: params.description,
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

// ============================================================
// FOOD JOURNEY / CHECK-IN
// ============================================================

// Gioi han check-in theo MVP.
const CHECKIN_RADIUS_METERS = 300;
const CHECKIN_COOLDOWN_HOURS = 24;
const MAX_DAILY_CHECKINS = 10;

// Viet Nam UTC+7.
const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

type BadgeRule = {
  badgeId: string;
  title: string;
  description: string;
  iconKey: string;
  currentValue: number;
  targetValue: number;
};

type DailyMissionDefinition = {
  id: string;
  title: string;
  description: string;
  type: string;
  iconKey: string;
  targetCount: number;
  rewardPoints: number;
  isFixedDaily?: boolean;
};

const DAILY_MISSION_DEFINITIONS: DailyMissionDefinition[] = [
  {
    id: "favorite_any_place",
    title: "Luu 1 quan yeu thich",
    description: "Danh dau yeu thich bat ky mot quan an nao.",
    type: "favorite_any_place",
    iconKey: "save",
    targetCount: 1,
    rewardPoints: 10,
    isFixedDaily: true,
  },
  {
    id: "first_checkin_before_9am",
    title: "Check-in dau ngay truoc 9h",
    description: "Hoan thanh check-in dau tien trong ngay truoc 9h sang.",
    type: "first_checkin_before_9am",
    iconKey: "clock",
    targetCount: 1,
    rewardPoints: 25,
  },
  {
    id: "evening_checkin_after_18h",
    title: "Check-in buoi toi sau 18h",
    description: "Ghe quan vao buoi toi va check-in sau 18h.",
    type: "evening_checkin_after_18h",
    iconKey: "night",
    targetCount: 1,
    rewardPoints: 20,
  },
  {
    id: "checkin_high_rating_place",
    title: "Check-in quan tu 4.5 sao",
    description: "Check-in 1 quan co diem danh gia tu 4.5 tro len.",
    type: "checkin_high_rating_place",
    iconKey: "review",
    targetCount: 1,
    rewardPoints: 25,
  },
  {
    id: "earn_30_points_in_day",
    title: "Tich luy 30 diem trong ngay",
    description: "Kiem tong cong it nhat 30 diem check-in trong hom nay.",
    type: "earn_30_points_in_day",
    iconKey: "points",
    targetCount: 30,
    rewardPoints: 30,
  },
  {
    id: "revisit_a_place",
    title: "Quay lai quan da tung check-in",
    description: "Check-in lai mot quan ban da ghe truoc do.",
    type: "revisit_a_place",
    iconKey: "repeat",
    targetCount: 1,
    rewardPoints: 20,
  },
  {
    id: "unlock_new_province",
    title: "Mo khoa 1 tinh moi",
    description: "Lan dau check-in tai mot tinh thanh moi trong hanh trinh.",
    type: "unlock_new_province",
    iconKey: "province",
    targetCount: 1,
    rewardPoints: 40,
  },
  {
    id: "checkin_new_place",
    title: "Check-in 1 quan moi",
    description: "Hay check-in tai mot quan ban chua tung an.",
    type: "checkin_new_place",
    iconKey: "checkin",
    targetCount: 1,
    rewardPoints: 30,
  },
];

const DAILY_RANDOM_MISSION_COUNT = 4;

/**
 * Ep an input thanh chuoi an toan.
 */
function toStringSafe(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

/**
 * Chuan hoa ten quan/huyen thanh key on dinh de luu district da di qua.
 */
function normalizeDistrictKey(value: string): string {
  return toStringSafe(value)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

/**
 * Ep an input sang so nguyen an toan.
 */
function toInt(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed)) return fallback;
    return parsed;
  }
  return fallback;
}

/**
 * Ep an input sang so thuc an toan.
 */
function toDouble(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    if (!Number.isFinite(parsed)) return fallback;
    return parsed;
  }
  return fallback;
}

/**
 * Tao key yyyy-MM-dd theo gio Viet Nam.
 */
function getVietnamDateKey(date: Date): string {
  const vn = new Date(date.getTime() + VN_OFFSET_MS);
  const year = vn.getUTCFullYear();
  const month = String(vn.getUTCMonth() + 1).padStart(2, "0");
  const day = String(vn.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/**
 * Lay gio hien tai theo mui gio Viet Nam.
 */
function getVietnamHour(date: Date): number {
  const vn = new Date(date.getTime() + VN_OFFSET_MS);
  return vn.getUTCHours();
}

/**
 * Tao hash on dinh de chon mission random theo user + ngay.
 */
function stableHash(value: string): number {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = ((hash * 31) + value.charCodeAt(index)) >>> 0;
  }
  return hash;
}

/**
 * Chon bo daily mission cho user trong ngay.
 */
function selectDailyMissionDefinitions(
  uid: string,
  dateKey: string,
): DailyMissionDefinition[] {
  const fixed = DAILY_MISSION_DEFINITIONS.filter(
    (mission) => mission.isFixedDaily,
  );
  const randomPool = DAILY_MISSION_DEFINITIONS.filter(
    (mission) => !mission.isFixedDaily,
  );

  const ranked = [...randomPool].sort((a, b) => {
    const left = stableHash(`${uid}:${dateKey}:${a.id}`);
    const right = stableHash(`${uid}:${dateKey}:${b.id}`);
    return left - right;
  });

  return [
    ...fixed,
    ...ranked.slice(0, Math.min(DAILY_RANDOM_MISSION_COUNT, ranked.length)),
  ];
}

/**
 * Tinh khoang cach giua 2 diem GPS.
 */
function haversineMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const r = 6371000;
  const toRad = (n: number) => (n * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Upsert badge theo rule.
 */
function syncJourneyBadge(
  tx: admin.firestore.Transaction,
  badgesCol: admin.firestore.CollectionReference,
  rule: BadgeRule,
  existing: admin.firestore.DocumentData,
): boolean {
  const badgeRef = badgesCol.doc(rule.badgeId);

  const progress = rule.targetValue <= 0 ? 0 : Math.min(
    rule.currentValue / rule.targetValue,
    1,
  );

  const wasUnlocked =
    existing.unlockedAt != null || toDouble(existing.progress) >= 1;
  let unlockedAt = existing.unlockedAt ?? null;
  if (unlockedAt === null && progress >= 1) {
    unlockedAt = admin.firestore.FieldValue.serverTimestamp();
  }

  tx.set(
    badgeRef,
    {
      badgeId: rule.badgeId,
      title: rule.title,
      description: rule.description,
      iconKey: rule.iconKey,
      progress,
      currentValue: rule.currentValue,
      targetValue: rule.targetValue,
      unlockedAt,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  return !wasUnlocked && progress >= 1;
}


/**
 * Tao du lieu mission mac dinh de ghi vao Firestore.
 */
function buildMissionSeed(
  definition: DailyMissionDefinition,
  dateKey: string,
): admin.firestore.DocumentData {
  return {
    id: definition.id,
    title: definition.title,
    description: definition.description,
    type: definition.type,
    iconKey: definition.iconKey,
    targetCount: definition.targetCount,
    currentCount: 0,
    rewardPoints: definition.rewardPoints,
    date: dateKey,
    isCompleted: false,
    isClaimed: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Ghi mission mac dinh neu mission hom nay chua ton tai.
 */
function writeDailyMissionSeed(
  tx: admin.firestore.Transaction,
  missionRef: admin.firestore.DocumentReference,
  existing: admin.firestore.DocumentData | undefined,
  definition: DailyMissionDefinition,
  dateKey: string,
) {
  if (existing) return;

  tx.set(
    missionRef,
    buildMissionSeed(definition, dateKey),
    {merge: true},
  );
}

/**
 * Cap nhat tien do mission trong transaction.
 */
function writeDailyMissionProgress(
  tx: admin.firestore.Transaction,
  missionRef: admin.firestore.DocumentReference,
  existing: admin.firestore.DocumentData | undefined,
  definition: DailyMissionDefinition,
  dateKey: string,
  shouldIncrease: boolean,
) {
  const currentCount = toInt(existing?.currentCount);
  const targetCount = definition.targetCount;
  const alreadyCompleted =
    existing?.isCompleted === true ||
    (targetCount > 0 && currentCount >= targetCount);

  const nextCount = shouldIncrease && !alreadyCompleted ?
    Math.min(currentCount + 1, targetCount) :
    currentCount;

  const isCompleted =
    alreadyCompleted ||
    (targetCount > 0 && nextCount >= targetCount);

  const data: admin.firestore.DocumentData = {
    id: definition.id,
    title: definition.title,
    description: definition.description,
    type: definition.type,
    iconKey: definition.iconKey,
    targetCount,
    currentCount: nextCount,
    rewardPoints: definition.rewardPoints,
    date: dateKey,
    isCompleted,
    isClaimed: existing?.isClaimed === true,
    createdAt:
      existing?.createdAt ??
      admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (isCompleted && !existing?.completedAt) {
    data.completedAt = admin.firestore.FieldValue.serverTimestamp();
  }

  if (existing?.claimedAt) {
    data.claimedAt = existing.claimedAt;
  }

  if (existing?.dueAt) {
    data.dueAt = existing.dueAt;
  }

  tx.set(missionRef, data, {merge: true});
}

type DailyMissionCheckinContext = {
  dailyCountBefore: number;
  dailyPointsBefore: number;
  pointsEarned: number;
  vietnamHour: number;
  isNewPlace: boolean;
  isNewProvince: boolean;
  isReturnVisit: boolean;
  placeRating: number;
};

/**
 * Xac dinh mission nao can tang tien do sau moi lan check-in.
 */
function shouldIncreaseMissionFromCheckin(
  mission: DailyMissionDefinition,
  context: DailyMissionCheckinContext,
): boolean {
  switch (mission.type) {
  case "checkin_new_place":
    return context.isNewPlace;
  case "first_checkin_before_9am":
    return context.dailyCountBefore === 0 && context.vietnamHour < 9;
  case "evening_checkin_after_18h":
    return context.vietnamHour >= 18;
  case "checkin_high_rating_place":
    return context.placeRating >= 4.5;
  case "earn_30_points_in_day":
    return context.dailyPointsBefore < 30 &&
      context.dailyPointsBefore + context.pointsEarned >= 30;
  case "revisit_a_place":
    return context.isReturnVisit;
  case "unlock_new_province":
    return context.isNewProvince;
  default:
    return false;
  }
}

export const ensureDailyMissions = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Ban can dang nhap.");
  }

  const payload = request.data ?? {};
  const dateKey =
    toStringSafe(payload.dateKey) || getVietnamDateKey(new Date());

  const summaryRef = db
    .collection("users")
    .doc(uid)
    .collection("journey")
    .doc("summary");

  const dailyMissionRef = summaryRef
    .collection("daily_missions")
    .doc(dateKey);

  const missionsCol = dailyMissionRef.collection("missions");
  const selectedMissions = selectDailyMissionDefinitions(uid, dateKey);
  const selectedMissionIds = new Set(
    selectedMissions.map((mission) => mission.id),
  );
  const missionRefs = selectedMissions.map((mission) =>
    missionsCol.doc(mission.id),
  );

  await db.runTransaction(async (tx) => {
    const existingMissionSnapshot = await tx.get(missionsCol);
    const missionSnaps = await Promise.all(
      missionRefs.map((missionRef) => tx.get(missionRef)),
    );

    tx.set(
      dailyMissionRef,
      {
        dateKey,
        missionIds: selectedMissions.map((mission) => mission.id),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    selectedMissions.forEach((mission, index) => {
      writeDailyMissionSeed(
        tx,
        missionRefs[index],
        missionSnaps[index].data(),
        mission,
        dateKey,
      );
    });

    existingMissionSnapshot.docs.forEach((doc) => {
      if (!selectedMissionIds.has(doc.id)) {
        tx.delete(doc.ref);
      }
    });
  });

  return {
    success: true,
    dateKey,
  };
});

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

// ============================
// CREATE CHECKIN
// ============================
export const createCheckin = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Ban can dang nhap de check-in.");
  }

  const payload = request.data ?? {};
  const placeId = toStringSafe(payload.placeId);
  const placeName = toStringSafe(payload.placeName);
  const placeAddress = toStringSafe(payload.placeAddress);
  const placeLat = toDouble(payload.placeLat);
  const placeLng = toDouble(payload.placeLng);
  const placePhotoUrl = toStringSafe(payload.photoUrl);
  const placeRating = toDouble(payload.placeRating);
  const districtName = toStringSafe(payload.districtName);
  const placeType = toStringSafe(payload.placeType) || "restaurant";
  const provinceCode = toStringSafe(payload.provinceCode);
  const provinceName = toStringSafe(payload.provinceName);
  const userLat = toDouble(payload.userLat);
  const userLng = toDouble(payload.userLng);
  const verificationType = toStringSafe(payload.verificationType) || "gps";
  const source = toStringSafe(payload.source) || "gps";

  if (!placeId) {
    throw new HttpsError("invalid-argument", "Thieu placeId.");
  }
  if (!placeName) {
    throw new HttpsError("invalid-argument", "Thieu placeName.");
  }
  if (!Number.isFinite(placeLat) || !Number.isFinite(placeLng)) {
    throw new HttpsError("invalid-argument", "Toa do quan khong hop le.");
  }
  if (!Number.isFinite(userLat) || !Number.isFinite(userLng)) {
    throw new HttpsError("invalid-argument", "Toa do nguoi dung khong hop le.");
  }

  const userRef = db.collection("users").doc(uid);
  const summaryRef = userRef.collection("journey").doc("summary");
  const checkinsCol = summaryRef.collection("checkins");
  const placeVisitsCol = summaryRef.collection("placeVisits");
  const dailyStatsCol = summaryRef.collection("dailyStats");
  const canonicalProvincesCol = summaryRef.collection("provinces_v2");
  const legacyProvincesCol = summaryRef.collection("provinces");
  const badgesCol = summaryRef.collection("badges");
  const districtVisitsCol = summaryRef.collection("districtVisits");
  const placeVisitRef = placeVisitsCol.doc(placeId);
  const todayDailyRef = dailyStatsCol.doc(getVietnamDateKey(new Date()));
  const checkinRef = checkinsCol.doc();

  const result = await db.runTransaction(async (tx) => {
    const now = new Date();
    const todayKey = getVietnamDateKey(now);
    const yesterdayKey = getVietnamDateKey(new Date(now.getTime() - DAY_MS));
    const cooldownMs = CHECKIN_COOLDOWN_HOURS * 60 * 60 * 1000;

    // Chi doc summary cua user. Du lieu quan duoc gui tu app.
    const summarySnap = await tx.get(summaryRef);

    // Tinh khoang cach tu user den quan.
    const distanceMeters = haversineMeters(
      userLat,
      userLng,
      placeLat,
      placeLng,
    );
    if (distanceMeters > CHECKIN_RADIUS_METERS) {
      throw new HttpsError(
        "failed-precondition",
        "Ban dang o qua xa quan de check-in.",
      );
    }

    const summaryData = summarySnap.data() ?? {};
    const previousLastActiveDate = toStringSafe(summaryData.lastActiveDate);
    const totalPointsBefore = toInt(summaryData.totalPoints);
    const currentStreakBefore = toInt(summaryData.currentStreak);
    const longestStreakBefore = toInt(summaryData.longestStreak);
    const totalCheckinsBefore = toInt(summaryData.totalCheckins);
    const uniquePlacesBefore = toInt(summaryData.uniquePlacesCount);
    const uniqueProvincesBefore = toInt(summaryData.uniqueProvincesCount);

    // Gioi han check-in trong ngay.
    // Dung doc rieng theo ngay de tranh query phuc tap.
    const dailySnap = await tx.get(todayDailyRef);
    const dailyData = dailySnap.data() ?? {};
    const dailyCountBefore = toInt(dailyData.checkinCount);
    const dailyPointsBefore = toInt(dailyData.pointsEarned);
    if (dailyCountBefore >= MAX_DAILY_CHECKINS) {
      throw new HttpsError(
        "resource-exhausted",
        "Ban da dat gioi han check-in trong ngay.",
      );
    }

    // Kiem tra cooldown cua dung quan nay qua 1 document rieng.
    const placeVisitSnap = await tx.get(placeVisitRef);
    if (placeVisitSnap.exists) {
      const lastCheckinAt = placeVisitSnap.get("lastCheckinAt");
      let lastDate: Date | null = null;
      if (lastCheckinAt instanceof admin.firestore.Timestamp) {
        lastDate = lastCheckinAt.toDate();
      }

      if (lastDate && now.getTime() - lastDate.getTime() < cooldownMs) {
        throw new HttpsError(
          "failed-precondition",
          "Ban vua check-in quan nay gan day roi.",
        );
      }
    }

    // Province bonus chi hoat dong neu client co cung cap province.
    const provinceRef = provinceCode ?
      canonicalProvincesCol.doc(provinceCode) :
      null;
    const legacyProvinceRef = provinceCode ?
      legacyProvincesCol.doc(provinceCode) :
      null;
    const normalizedDistrictKey = normalizeDistrictKey(districtName);
    const districtVisitRef = provinceCode && normalizedDistrictKey ?
      districtVisitsCol.doc(`${provinceCode}__${normalizedDistrictKey}`) :
      null;
    const provinceSnap = provinceRef ? await tx.get(provinceRef) : null;
    const districtVisitSnap = districtVisitRef ?
      await tx.get(districtVisitRef) :
      null;
    const badgeSnaps = await Promise.all([
      tx.get(badgesCol.doc("first_bite")),
      tx.get(badgesCol.doc("food_explorer")),
      tx.get(badgesCol.doc("province_explorer")),
      tx.get(badgesCol.doc("streak_3")),
    ]);
    const firstBiteBadge = badgeSnaps[0].data() ?? {};
    const foodExplorerBadge = badgeSnaps[1].data() ?? {};
    const provinceExplorerBadge = badgeSnaps[2].data() ?? {};
    const streakBadge = badgeSnaps[3].data() ?? {};
    const unlockedBadges: Array<{
      badgeId: string;
      title: string;
      description: string;
    }> = [];

    const dailyMissionRef = summaryRef
      .collection("daily_missions")
      .doc(todayKey);
    const missionsCol = dailyMissionRef.collection("missions");
    const missionQuerySnap = await tx.get(missionsCol);
    const selectedMissions = selectDailyMissionDefinitions(uid, todayKey);
    const activeMissionDefinitions = missionQuerySnap.empty ?
      selectedMissions :
      missionQuerySnap.docs
        .map(
          (doc) => DAILY_MISSION_DEFINITIONS.find(
            (mission) => mission.id === doc.id,
          ),
        )
        .filter(
          (mission): mission is DailyMissionDefinition => Boolean(mission),
        );

    const isNewPlace = !placeVisitSnap.exists;
    const isNewProvince = Boolean(
      provinceRef && provinceCode && !(provinceSnap?.exists),
    );
    const isNewDistrict = Boolean(
      districtVisitRef && normalizedDistrictKey && !(districtVisitSnap?.exists),
    );

    // Tinh diem MVP.
    let pointsEarned = 10;
    if (isNewPlace) pointsEarned += 20;
    if (isNewProvince) pointsEarned += 50;

    // Tinh streak theo ngay.
    let currentStreak = currentStreakBefore;
    if (previousLastActiveDate === todayKey) {
      currentStreak = currentStreakBefore;
    } else if (previousLastActiveDate === yesterdayKey) {
      currentStreak = currentStreakBefore + 1;
    } else {
      currentStreak = 1;
    }

    const longestStreak = Math.max(longestStreakBefore, currentStreak);
    const totalPoints = totalPointsBefore + pointsEarned;
    const totalCheckins = totalCheckinsBefore + 1;
    const uniquePlacesCount = uniquePlacesBefore + (isNewPlace ? 1 : 0);
    const uniqueProvincesCount =
      uniqueProvincesBefore + (isNewProvince ? 1 : 0);
    const level = Math.floor(totalPoints / 100) + 1;

    // Luu log check-in.
    tx.set(checkinRef, {
      id: checkinRef.id,
      placeId,
      placeName,
      placeAddress,
      provinceCode,
      provinceName,
      userLat,
      userLng,
      placeLat,
      placeLng,
      distanceMeters,
      pointsEarned,
      placeImageUrl: placePhotoUrl,
      districtName,
      placeType,
      verificationType,
      photoUrl: placePhotoUrl || null,
      isNewPlace,
      isNewProvince,
      source,
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Luu trang thai cua tung quan de check cooldown o lan sau.
    let nextPlaceVisitCount = 1;
    if (!isNewPlace) {
      nextPlaceVisitCount = toInt(placeVisitSnap.data()?.checkinCount) + 1;
    }
    const isReturnVisit = nextPlaceVisitCount > 1;

    tx.set(
      placeVisitRef,
      {
        placeId,
        placeName,
        placeAddress,
        provinceCode,
        provinceName,
        lastCheckinAt: admin.firestore.FieldValue.serverTimestamp(),
        checkinCount: nextPlaceVisitCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    if (districtVisitRef && normalizedDistrictKey) {
      tx.set(
        districtVisitRef,
        {
          provinceCode,
          provinceName,
          districtKey: normalizedDistrictKey,
          districtName,
          firstCheckinAt:
            districtVisitSnap?.data()?.firstCheckinAt ??
            admin.firestore.FieldValue.serverTimestamp(),
          lastCheckinAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    // Cap nhat bo dem theo ngay.
    tx.set(
      todayDailyRef,
      {
        dateKey: todayKey,
        checkinCount: dailyCountBefore + 1,
        pointsEarned: dailyPointsBefore + pointsEarned,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    // Cap nhat summary tong.
    tx.set(
      summaryRef,
      {
        totalPoints,
        level,
        currentStreak,
        longestStreak,
        totalCheckins,
        uniquePlacesCount,
        uniqueProvincesCount,
        lastActiveDate: todayKey,
        lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
        lastCheckinAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    // Cap nhat tien trinh tinh/thanh neu co du lieu tinh.
    if (provinceRef) {
      const provinceData = provinceSnap?.data() ?? {};
      const provinceCheckinCount = toInt(provinceData.checkinCount) + 1;
      const provinceUniquePlacesCount =
        toInt(provinceData.uniquePlacesCount) + (isNewPlace ? 1 : 0);
      const provinceDistrictsCount =
        toInt(provinceData.districtsCount) + (isNewDistrict ? 1 : 0);
      const provinceTotalPoints =
        toInt(provinceData.totalPoints) + pointsEarned;
      const provincePayload = {
        provinceCode,
        provinceName: provinceName || toStringSafe(provinceData.provinceName),
        checkinCount: provinceCheckinCount,
        uniquePlacesCount: provinceUniquePlacesCount,
        districtsCount: provinceDistrictsCount,
        totalPoints: provinceTotalPoints,
        isDiscovered: true,
        firstCheckinAt:
          provinceData.firstCheckinAt ??
          admin.firestore.FieldValue.serverTimestamp(),
        lastCheckinAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      tx.set(
        provinceRef,
        provincePayload,
        {merge: true},
      );

      if (legacyProvinceRef) {
        tx.set(legacyProvinceRef, provincePayload, {merge: true});
      }
    }

    // Badge MVP.
    if (syncJourneyBadge(tx, badgesCol, {
      badgeId: "first_bite",
      title: "Mieng dau tien",
      description: "Check-in quan dau tien",
      iconKey: "checkin",
      currentValue: totalCheckins,
      targetValue: 1,
    }, firstBiteBadge)) {
      unlockedBadges.push({
        badgeId: "first_bite",
        title: "Mieng dau tien",
        description: "Check-in quan dau tien",
      });
    }

    if (syncJourneyBadge(tx, badgesCol, {
      badgeId: "food_explorer",
      title: "Nha kham pha am thuc",
      description: "Check-in 5 quan khac nhau",
      iconKey: "map",
      currentValue: uniquePlacesCount,
      targetValue: 5,
    }, foodExplorerBadge)) {
      unlockedBadges.push({
        badgeId: "food_explorer",
        title: "Nha kham pha am thuc",
        description: "Check-in 5 quan khac nhau",
      });
    }

    if (syncJourneyBadge(tx, badgesCol, {
      badgeId: "province_explorer",
      title: "Kham pha tinh thanh",
      description: "Kham pha 3 tinh thanh",
      iconKey: "province",
      currentValue: uniqueProvincesCount,
      targetValue: 3,
    }, provinceExplorerBadge)) {
      unlockedBadges.push({
        badgeId: "province_explorer",
        title: "Kham pha tinh thanh",
        description: "Kham pha 3 tinh thanh",
      });
    }

    if (syncJourneyBadge(tx, badgesCol, {
      badgeId: "streak_3",
      title: "Giu nhip 3 ngay",
      description: "Co hoat dong trong 3 ngay lien tiep",
      iconKey: "streak",
      currentValue: currentStreak,
      targetValue: 3,
    }, streakBadge)) {
      unlockedBadges.push({
        badgeId: "streak_3",
        title: "Giu nhip 3 ngay",
        description: "Co hoat dong trong 3 ngay lien tiep",
      });
    }

    tx.set(
      dailyMissionRef,
      {
        dateKey: todayKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    const missionContext: DailyMissionCheckinContext = {
      dailyCountBefore,
      dailyPointsBefore,
      pointsEarned,
      vietnamHour: getVietnamHour(now),
      isNewPlace,
      isNewProvince,
      isReturnVisit,
      placeRating,
    };

    activeMissionDefinitions.forEach((mission) => {
      const existing = missionQuerySnap.docs
        .find((doc) => doc.id === mission.id)
        ?.data();

      writeDailyMissionProgress(
        tx,
        missionsCol.doc(mission.id),
        existing,
        mission,
        todayKey,
        shouldIncreaseMissionFromCheckin(mission, missionContext),
      );
    });

    return {
      checkinId: checkinRef.id,
      placeId,
      placeName,
      placeAddress,
      provinceCode,
      provinceName,
      distanceMeters,
      pointsEarned,
      totalPoints,
      level,
      currentStreak,
      longestStreak,
      totalCheckins,
      uniquePlacesCount,
      uniqueProvincesCount,
      isNewPlace,
      isNewProvince,
      source,
      verificationType,
      placeLat,
      placeLng,
      placePhotoUrl,
      placeType,
      districtName,
      unlockedBadges,
    };
  });

  logger.info("Journey checkin created", {
    uid,
    placeId: result.placeId,
    checkinId: result.checkinId,
    pointsEarned: result.pointsEarned,
  });

  try {
    await createJourneyNotification({
      ownerId: uid,
      checkinId: result.checkinId,
      placeName: result.placeName,
      provinceName: result.provinceName,
      pointsEarned: result.pointsEarned,
      currentStreak: result.currentStreak,
    });

    const pushBody = result.provinceName ?
      `${result.placeName}, ${result.provinceName}` +
        ` • +${result.pointsEarned} diem` :
      `${result.placeName} • +${result.pointsEarned} diem`;

    await sendPush(
      uid,
      "Check-in thanh cong",
      pushBody,
      {
        type: "journey_checkin",
        checkinId: result.checkinId,
        placeId: result.placeId,
        placeName: result.placeName,
        provinceCode: result.provinceCode || "",
        provinceName: result.provinceName || "",
        pointsEarned: String(result.pointsEarned),
        currentStreak: String(result.currentStreak),
      },
    );

    for (const badge of result.unlockedBadges ?? []) {
      await createJourneyBadgeNotification({
        ownerId: uid,
        badgeId: badge.badgeId,
        title: badge.title,
        description: badge.description,
      });

      await sendPush(
        uid,
        "Mo khoa huy hieu moi",
        `Ban vua mo khoa huy hieu ${badge.title}.`,
        {
          type: "journey_badge",
          badgeId: badge.badgeId,
          badgeTitle: badge.title,
        },
      );
    }
  } catch (error) {
    logger.error("Failed to create checkin notification", {
      uid,
      checkinId: result.checkinId,
      error,
    });
  }

  return {
    success: true,
    ...result,
  };
});
/**
 * Marks today's save-place mission as completed after the user saves a place.
 */
export const completeSavePlaceMission = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Ban can dang nhap de cap nhat nhiem vu.",
    );
  }

  const now = new Date();
  const todayKey = getVietnamDateKey(now);

  const missionRef = db
    .collection("users")
    .doc(uid)
    .collection("journey")
    .doc("summary")
    .collection("daily_missions")
    .doc(todayKey)
    .collection("missions")
    .doc("favorite_any_place");

  await db.runTransaction(async (tx) => {
    const missionSnap = await tx.get(missionRef);
    const missionData = missionSnap.data() ?? {};

    const targetCount = Math.max(
      toInt(missionData.targetCount, 1),
      1,
    );

    const currentCount = toInt(missionData.currentCount);
    const nextCount = Math.min(currentCount + 1, targetCount);
    const isCompleted = nextCount >= targetCount;

    const updateData: admin.firestore.DocumentData = {
      id: "favorite_any_place",
      title: "Luu 1 quan yeu thich",
      description: "Danh dau yeu thich bat ky mot quan an nao.",
      type: "favorite_any_place",
      iconKey: "save",
      targetCount,
      currentCount: nextCount,
      rewardPoints: 10,
      date: todayKey,
      isCompleted,
      isClaimed: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!missionSnap.exists) {
      updateData.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }

    if (isCompleted && !missionData.completedAt) {
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    tx.set(missionRef, updateData, {merge: true});
  });

  return {
    success: true,
    missionId: "favorite_any_place",
  };
});
