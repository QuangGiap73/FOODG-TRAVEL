/* eslint-disable max-len, require-jsdoc */
import * as admin from "firebase-admin";
import {readFile} from "node:fs/promises";
import path from "node:path";

type JsonMap = Record<string, string>;

type CanonicalProvinceSeed = {
  code: string;
  name: string;
  slug: string;
  regionCode: string;
  primaryLegacyCode: string;
  status?: string;
};

type LegacyProvinceDoc = {
  id: string;
  name: string;
  code: string;
  imageUrl: string;
  imageUrls: string[];
  description: string;
  regionCode: string;
  slug: string;
  centerLat: number | null;
  centerLng: number | null;
  raw: Record<string, unknown>;
};

type CanonicalProvinceDoc = {
  code: string;
  name: string;
  slug: string;
  regionCode: string;
  coverImage: string;
  imageUrls: string[];
  description: string;
  history: string;
  culture: string;
  centerLat: number | null;
  centerLng: number | null;
  mergedFrom: string[];
  legacyCount: number;
  status: string;
  sourceProvinceNames: string[];
  updatedAt: admin.firestore.FieldValue;
};

type CliOptions = {
  dryRun: boolean;
  mappingPath: string;
  seedPath: string;
};

type FirebaseRc = {
  projects?: {
    default?: string;
  };
};

type FirebaseJson = {
  flutter?: {
    platforms?: {
      dart?: {
        "lib/firebase_options.dart"?: {
          projectId?: string;
        };
      };
    };
  };
};

const CURRENT_DIR = path.resolve(process.cwd(), "src", "migrations", "province34");
const DEFAULT_MAPPING_PATH = path.join(
  CURRENT_DIR,
  "data",
  "province_merge_map.official_2025.json",
);
const DEFAULT_SEED_PATH = path.join(
  CURRENT_DIR,
  "data",
  "canonical_provinces_34.official_2025.json",
);
const REPO_ROOT = path.resolve(process.cwd(), "..");

function parseArgs(argv: string[]): CliOptions {
  let dryRun = true;
  let mappingPath = DEFAULT_MAPPING_PATH;
  let seedPath = DEFAULT_SEED_PATH;

  argv.forEach((arg, index) => {
    if (arg === "--apply") {
      dryRun = false;
      return;
    }
    if (arg === "--dry-run") {
      dryRun = true;
      return;
    }
    if (arg === "--mapping" && argv[index + 1]) {
      mappingPath = path.resolve(argv[index + 1]);
      return;
    }
    if (arg === "--seeds" && argv[index + 1]) {
      seedPath = path.resolve(argv[index + 1]);
    }
  });

  return {dryRun, mappingPath, seedPath};
}

async function readJsonFile<T>(filePath: string): Promise<T> {
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw) as T;
}

async function detectProjectId(): Promise<string | null> {
  const fromEnv =
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    "";
  if (fromEnv.trim().length > 0) {
    return fromEnv.trim();
  }

  try {
    const firebaseRc = await readJsonFile<FirebaseRc>(
      path.join(REPO_ROOT, ".firebaserc"),
    );
    const projectId = firebaseRc.projects?.default?.trim();
    if (projectId) return projectId;
  } catch (_) {
    // ignore
  }

  try {
    const firebaseJson = await readJsonFile<FirebaseJson>(
      path.join(REPO_ROOT, "firebase.json"),
    );
    const projectId = firebaseJson.flutter?.platforms?.dart?.[
      "lib/firebase_options.dart"
    ]?.projectId?.trim();
    if (projectId) return projectId;
  } catch (_) {
    // ignore
  }

  return null;
}

function asString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function pickLocalizedString(value: unknown): string {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    const map = value as Record<string, unknown>;
    return (
      asString(map.vi) ||
      asString(map.en) ||
      asString(map.code) ||
      asString(map.name)
    );
  }
  return asString(value);
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asString(item))
    .filter((item) => item.length > 0);
}

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function normalizeKey(input: string): string {
  const lower = input.toLowerCase().trim();
  const source =
    "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩ" +
    "òóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ";
  const target =
    "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiii" +
    "ooooooooooooooooouuuuuuuuuuuyyyyyd";
  let next = "";
  for (const ch of lower) {
    const idx = source.indexOf(ch);
    next += idx === -1 ? ch : target[idx];
  }
  return next.replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

function toLegacyProvinceDoc(
  doc: admin.firestore.QueryDocumentSnapshot,
): LegacyProvinceDoc {
  const data = doc.data();
  return {
    id: doc.id,
    name: asString(data.name),
    code: asString(data.code || data.province_code || doc.id),
    imageUrl: asString(data.imageUrl || data.Img),
    imageUrls: asStringList(data.imageUrls),
    description: asString(data.description),
    regionCode: asString(
      data.regionCode || data.regionsCode || data.region_code,
    ),
    slug: asString(data.slug),
    centerLat: asNumber(data.centerLat || data.center_lat),
    centerLng: asNumber(data.centerLng || data.center_lng),
    raw: data,
  };
}

function pickPrimaryLegacyDoc(
  seed: CanonicalProvinceSeed,
  docs: LegacyProvinceDoc[],
): LegacyProvinceDoc | undefined {
  const normalizedPrimary = normalizeKey(seed.primaryLegacyCode);
  return docs.find((doc) => normalizeKey(doc.code) === normalizedPrimary) ??
    docs[0];
}

function buildCanonicalProvinceDoc(
  seed: CanonicalProvinceSeed,
  docs: LegacyProvinceDoc[],
): CanonicalProvinceDoc {
  const primary = pickPrimaryLegacyDoc(seed, docs);
  const imageUrls = docs
    .flatMap((doc) => {
      const merged = [...doc.imageUrls];
      if (doc.imageUrl && !merged.includes(doc.imageUrl)) {
        merged.unshift(doc.imageUrl);
      }
      return merged;
    })
    .filter((url, index, all) => url.length > 0 && all.indexOf(url) === index);
  const descriptions = docs
    .map((doc) => doc.description)
    .filter((item) => item.length > 0);
  const history = docs
    .map((doc) =>
      asString(doc.raw.history || doc.raw.origin || doc.raw.historicalInfo),
    )
    .filter((item) => item.length > 0)
    .join("\n\n");
  const culture = docs
    .map((doc) =>
      asString(doc.raw.culture || doc.raw.highlights || doc.raw.intro),
    )
    .filter((item) => item.length > 0)
    .join("\n\n");

  return {
    code: seed.code,
    name: seed.name,
    slug: seed.slug,
    regionCode: seed.regionCode,
    coverImage: primary?.imageUrl || imageUrls[0] || "",
    imageUrls,
    description: primary?.description || descriptions[0] || "",
    history,
    culture,
    centerLat: primary?.centerLat ?? null,
    centerLng: primary?.centerLng ?? null,
    mergedFrom: docs.map((doc) => doc.code),
    legacyCount: docs.length,
    status: seed.status || "active",
    sourceProvinceNames: docs
      .map((doc) => doc.name)
      .filter((item) => item.length > 0),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function ensureSeedCoverage(
  seeds: CanonicalProvinceSeed[],
  mapping: JsonMap,
): void {
  const canonicalCodes = new Set(seeds.map((seed) => normalizeKey(seed.code)));
  const missingTargets = Object.values(mapping)
    .map((item) => normalizeKey(item))
    .filter((code) => !canonicalCodes.has(code));
  if (missingTargets.length > 0) {
    throw new Error(
      `Missing canonical seed definitions for: ${missingTargets.join(", ")}`,
    );
  }
}

function detectMappedCanonicalCode(
  mapping: JsonMap,
  ...candidates: string[]
): string | null {
  for (const candidate of candidates) {
    const key = normalizeKey(candidate);
    if (!key) continue;
    const mapped = mapping[key];
    if (mapped) return mapped;
  }
  return null;
}

async function migrateProvinces(
  db: admin.firestore.Firestore,
  dryRun: boolean,
  seeds: CanonicalProvinceSeed[],
  mapping: JsonMap,
): Promise<void> {
  const legacySnap = await db.collection("provinces").get();
  const legacyDocs = legacySnap.docs.map(toLegacyProvinceDoc);
  const grouped = new Map<string, LegacyProvinceDoc[]>();

  for (const legacy of legacyDocs) {
    const targetCode =
      mapping[normalizeKey(legacy.code)] ||
      mapping[normalizeKey(legacy.id)] ||
      mapping[normalizeKey(legacy.name)];
    if (!targetCode) continue;
    const key = normalizeKey(targetCode);
    const current = grouped.get(key) ?? [];
    current.push(legacy);
    grouped.set(key, current);
  }

  const batch = db.batch();
  let writes = 0;
  for (const seed of seeds) {
    const docs = grouped.get(normalizeKey(seed.code)) ?? [];
    if (docs.length === 0) continue;
    const canonicalDoc = buildCanonicalProvinceDoc(seed, docs);
    if (dryRun) {
      console.log(
        `[dry-run] provinces_v2/${seed.code} <= ` +
          canonicalDoc.mergedFrom.join(", "),
      );
      continue;
    }
    batch.set(db.collection("provinces_v2").doc(seed.code), canonicalDoc, {
      merge: true,
    });
    writes++;
  }

  if (!dryRun && writes > 0) {
    await batch.commit();
  }
  console.log(`Province migration planned writes: ${writes}`);
}

async function migrateDishes(
  db: admin.firestore.Firestore,
  dryRun: boolean,
  seedsByCode: Map<string, CanonicalProvinceSeed>,
  mapping: JsonMap,
): Promise<void> {
  const snap = await db.collection("dishes").get();
  let updates = 0;
  let batch = db.batch();
  let batchSize = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const mappedCode = detectMappedCanonicalCode(
      mapping,
      pickLocalizedString(data.province_code),
      asString(data.provinceCode),
      asString(data.province_name_vi),
      asString(data.province_name),
      asString(data.province),
    );
    if (!mappedCode) continue;
    const seed = seedsByCode.get(normalizeKey(mappedCode));
    if (!seed) continue;

    const payload = {
      provinceCode34: seed.code,
      provinceName34: seed.name,
      legacyProvinceCode: pickLocalizedString(
        data.provinceCode || data.province_code,
      ) || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    updates++;

    if (dryRun) {
      console.log(`[dry-run] dishes/${doc.id} => ${seed.code}`);
      continue;
    }

    batch.set(doc.ref, payload, {merge: true});
    batchSize++;
    if (batchSize >= 400) {
      await batch.commit();
      batch = db.batch();
      batchSize = 0;
    }
  }

  if (!dryRun && batchSize > 0) {
    await batch.commit();
  }
  console.log(`Dish migration planned updates: ${updates}`);
}

async function migrateUsersAndJourney(
  db: admin.firestore.Firestore,
  dryRun: boolean,
  seedsByCode: Map<string, CanonicalProvinceSeed>,
  mapping: JsonMap,
): Promise<void> {
  const usersSnap = await db.collection("users").get();
  let userPrefUpdates = 0;
  let journeyWrites = 0;

  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    const prefs = (data.preferences ?? {}) as Record<string, unknown>;
    const mappedPrefCode = detectMappedCanonicalCode(
      mapping,
      asString(prefs.provinceCode),
      asString(prefs.provinceName),
    );
    const userBatch = db.batch();
    let shouldCommit = false;

    if (mappedPrefCode) {
      const seed = seedsByCode.get(normalizeKey(mappedPrefCode));
      if (seed) {
        userPrefUpdates++;
        shouldCommit = true;
        userBatch.set(
          userDoc.ref,
          {
            preferences: {
              ...prefs,
              provinceCode34: seed.code,
              provinceName34: seed.name,
              legacyProvinceCode: asString(prefs.provinceCode),
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      }
    }

    const journeySnap = await userDoc.ref
      .collection("journey")
      .doc("summary")
      .collection("provinces")
      .get();
    const aggregate = new Map<string, {
      seed: CanonicalProvinceSeed;
      checkinCount: number;
      uniquePlacesCount: number;
      totalPoints: number;
      sourceCodes: string[];
    }>();

    for (const provinceDoc of journeySnap.docs) {
      const provinceData = provinceDoc.data();
      const mappedCode = detectMappedCanonicalCode(
        mapping,
        asString(provinceData.provinceCode),
        asString(provinceData.provinceName),
        provinceDoc.id,
      );
      if (!mappedCode) continue;
      const seed = seedsByCode.get(normalizeKey(mappedCode));
      if (!seed) continue;
      const current = aggregate.get(seed.code) ?? {
        seed,
        checkinCount: 0,
        uniquePlacesCount: 0,
        totalPoints: 0,
        sourceCodes: [],
      };
      current.checkinCount += Number(provinceData.checkinCount ?? 0);
      current.uniquePlacesCount += Number(provinceData.uniquePlacesCount ?? 0);
      current.totalPoints += Number(provinceData.totalPoints ?? 0);
      current.sourceCodes.push(
        asString(provinceData.provinceCode || provinceDoc.id),
      );
      aggregate.set(seed.code, current);
    }

    for (const item of aggregate.values()) {
      journeyWrites++;
      shouldCommit = true;
      userBatch.set(
        userDoc.ref
          .collection("journey")
          .doc("summary")
          .collection("provinces_v2")
          .doc(item.seed.code),
        {
          provinceCode: item.seed.code,
          provinceName: item.seed.name,
          checkinCount: item.checkinCount,
          uniquePlacesCount: item.uniquePlacesCount,
          totalPoints: item.totalPoints,
          isDiscovered: item.checkinCount > 0,
          mergedFrom: item.sourceCodes,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    if (dryRun) {
      if (mappedPrefCode) {
        console.log(
          `[dry-run] users/${userDoc.id} preferences => ${mappedPrefCode}`,
        );
      }
      if (aggregate.size > 0) {
        console.log(
          `[dry-run] users/${userDoc.id} journey provinces_v2 writes=${aggregate.size}`,
        );
      }
      continue;
    }

    if (shouldCommit) {
      await userBatch.commit();
    }
  }

  console.log(`User preference migration planned updates: ${userPrefUpdates}`);
  console.log(`Journey province_v2 planned writes: ${journeyWrites}`);
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const mapping = await readJsonFile<JsonMap>(options.mappingPath);
  const seeds = await readJsonFile<CanonicalProvinceSeed[]>(options.seedPath);
  const projectId = await detectProjectId();

  ensureSeedCoverage(seeds, mapping);

  if (admin.apps.length === 0) {
    admin.initializeApp(projectId ? {projectId} : undefined);
  }
  const db = admin.firestore();
  const seedsByCode = new Map(
    seeds.map((seed) => [normalizeKey(seed.code), seed] as const),
  );

  console.log(`Running province34 migration dryRun=${options.dryRun}`);
  await migrateProvinces(db, options.dryRun, seeds, mapping);
  await migrateDishes(db, options.dryRun, seedsByCode, mapping);
  await migrateUsersAndJourney(db, options.dryRun, seedsByCode, mapping);
  console.log("Province34 migration finished.");
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  if (message.includes("Unable to detect a Project Id")) {
    console.error(
      "Province34 migration failed. Khong tim thay projectId. " +
        "Hay kiem tra .firebaserc/firebase.json hoac dat bien " +
        "GOOGLE_CLOUD_PROJECT=foodg-travel.",
    );
    process.exitCode = 1;
    return;
  }
  if (
    message.includes("Could not load the default credentials") ||
    message.includes("Could not load the default credentials") ||
    message.includes("Could not refresh access token") ||
    message.includes("Could not load credentials")
  ) {
    console.error(
      "Province34 migration failed. May nay chua co quyen Firestore local. " +
        "Chay `gcloud auth application-default login` hoac dat " +
        "GOOGLE_APPLICATION_CREDENTIALS` tro toi service-account json, " +
        "sau do chay lai script.",
    );
    process.exitCode = 1;
    return;
  }
  console.error("Province34 migration failed.", error);
  process.exitCode = 1;
});
