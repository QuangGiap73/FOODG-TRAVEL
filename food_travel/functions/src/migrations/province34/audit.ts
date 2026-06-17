/* eslint-disable max-len, require-jsdoc */
import * as admin from "firebase-admin";
import {readFile} from "node:fs/promises";
import path from "node:path";

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

type JsonMap = Record<string, string>;

type CanonicalProvinceSeed = {
  code: string;
  name: string;
  slug: string;
  regionCode: string;
  primaryLegacyCode: string;
  status?: string;
};

const CURRENT_DIR = path.resolve(process.cwd(), "src", "migrations", "province34");
const REPO_ROOT = path.resolve(process.cwd(), "..");
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
  if (fromEnv.trim().length > 0) return fromEnv.trim();

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

function normalizeKey(input: string): string {
  const lower = input.toLowerCase().trim();
  const source =
    "Ã Ã¡áº¡áº£Ã£Ã¢áº§áº¥áº­áº©áº«Äƒáº±áº¯áº·áº³áºµÃ¨Ã©áº¹áº»áº½Ãªá»áº¿á»‡á»ƒá»…Ã¬Ã­á»‹á»‰Ä©" +
    "Ã²Ã³á»á»ÃµÃ´á»“á»‘á»™á»•á»—Æ¡á»á»›á»£á»Ÿá»¡Ã¹Ãºá»¥á»§Å©Æ°á»«á»©á»±á»­á»¯á»³Ã½á»µá»·á»¹Ä‘";
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

function logSection(title: string): void {
  console.log("");
  console.log(`=== ${title} ===`);
}

async function auditProvinces(
  db: admin.firestore.Firestore,
  mapping: JsonMap,
  seedsByCode: Map<string, CanonicalProvinceSeed>,
): Promise<void> {
  logSection("PROVINCES");
  const snap = await db.collection("provinces").get();
  console.log(`Total legacy provinces: ${snap.size}`);

  const unmatched: string[] = [];
  const matchCounts = new Map<string, string[]>();

  for (const doc of snap.docs) {
    const data = doc.data();
    const code = asString(data.code || data.province_code || doc.id);
    const name = asString(data.name);
    const mapped = detectMappedCanonicalCode(mapping, code, doc.id, name);

    if (!mapped) {
      unmatched.push(`${doc.id} (code=${code}, name=${name})`);
      continue;
    }

    const key = normalizeKey(mapped);
    const list = matchCounts.get(key) ?? [];
    list.push(doc.id);
    matchCounts.set(key, list);
  }

  const missingSeeds: string[] = [];
  for (const seed of seedsByCode.values()) {
    if (!(matchCounts.get(normalizeKey(seed.code)) ?? []).length) {
      missingSeeds.push(`${seed.code} (${seed.name})`);
    }
  }

  console.log("Canonical merge preview:");
  for (const [code, legacyIds] of [...matchCounts.entries()].sort()) {
    console.log(`- ${code} <= ${legacyIds.join(", ")}`);
  }

  if (unmatched.length > 0) {
    console.log("Unmatched legacy provinces:");
    unmatched.slice(0, 50).forEach((item) => console.log(`- ${item}`));
  } else {
    console.log("Unmatched legacy provinces: 0");
  }

  if (missingSeeds.length > 0) {
    console.log("Canonical provinces with no matched legacy source:");
    missingSeeds.forEach((item) => console.log(`- ${item}`));
  } else {
    console.log("All canonical provinces have at least one legacy source.");
  }
}

async function auditRegions(db: admin.firestore.Firestore): Promise<void> {
  logSection("REGIONS");
  const snap = await db.collection("regions").get();
  console.log(`Total legacy regions: ${snap.size}`);
  for (const doc of snap.docs) {
    const data = doc.data();
    console.log(
      `- ${doc.id}: code=${asString(data.code)}, name=${asString(data.name)}, macro_region=${asString(data.macro_region)}`,
    );
  }
}

async function auditDishes(
  db: admin.firestore.Firestore,
  mapping: JsonMap,
): Promise<void> {
  logSection("DISHES");
  const snap = await db.collection("dishes").limit(500).get();
  console.log(`Sampled dishes: ${snap.size}`);

  let matched = 0;
  let unmatched = 0;
  const fieldHits = {
    province_code: 0,
    provinceCode: 0,
    province_name_vi: 0,
    province_name: 0,
    province: 0,
    provinceCode34: 0,
  };
  const examples: string[] = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const candidateProvinceCode = pickLocalizedString(data.province_code);
    const candidateProvinceCodeCamel = asString(data.provinceCode);
    const candidateProvinceNameVi = asString(data.province_name_vi);
    const candidateProvinceName = asString(data.province_name);
    const candidateProvince = asString(data.province);
    const candidateProvinceCode34 = asString(data.provinceCode34);

    if (candidateProvinceCode) fieldHits.province_code++;
    if (candidateProvinceCodeCamel) fieldHits.provinceCode++;
    if (candidateProvinceNameVi) fieldHits.province_name_vi++;
    if (candidateProvinceName) fieldHits.province_name++;
    if (candidateProvince) fieldHits.province++;
    if (candidateProvinceCode34) fieldHits.provinceCode34++;

    const mapped = detectMappedCanonicalCode(
      mapping,
      candidateProvinceCode,
      candidateProvinceCodeCamel,
      candidateProvinceNameVi,
      candidateProvinceName,
      candidateProvince,
    );

    if (mapped) {
      matched++;
    } else {
      unmatched++;
      if (examples.length < 20) {
        examples.push(
          `${doc.id} => province_code=${candidateProvinceCode} | provinceCode=${candidateProvinceCodeCamel} | province_name_vi=${candidateProvinceNameVi} | province_name=${candidateProvinceName} | province=${candidateProvince}`,
        );
      }
    }
  }

  console.log(`Mapped dishes in sample: ${matched}`);
  console.log(`Unmapped dishes in sample: ${unmatched}`);
  console.log("Field usage:");
  for (const [key, value] of Object.entries(fieldHits)) {
    console.log(`- ${key}: ${value}`);
  }
  if (examples.length > 0) {
    console.log("Sample unmapped dishes:");
    examples.forEach((item) => console.log(`- ${item}`));
  }
}

async function auditPlaces(
  db: admin.firestore.Firestore,
  mapping: JsonMap,
): Promise<void> {
  logSection("PLACES");
  const snap = await db.collection("places").limit(300).get();
  console.log(`Sampled places: ${snap.size}`);

  let matched = 0;
  let unmatched = 0;
  const examples: string[] = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const mapped = detectMappedCanonicalCode(
      mapping,
      asString(data.provinceCode),
      asString(data.province_code),
      asString(data.provinceName),
      asString(data.province_name),
      asString(data.city),
      asString(data.address),
    );
    if (mapped) {
      matched++;
    } else {
      unmatched++;
      if (examples.length < 20) {
        examples.push(
          `${doc.id} => provinceCode=${asString(data.provinceCode)} | province_code=${asString(data.province_code)} | provinceName=${asString(data.provinceName)} | province_name=${asString(data.province_name)} | city=${asString(data.city)}`,
        );
      }
    }
  }

  console.log(`Mapped places in sample: ${matched}`);
  console.log(`Unmapped places in sample: ${unmatched}`);
  if (examples.length > 0) {
    console.log("Sample unmapped places:");
    examples.forEach((item) => console.log(`- ${item}`));
  }
}

async function auditUsersJourney(
  db: admin.firestore.Firestore,
  mapping: JsonMap,
): Promise<void> {
  logSection("USERS / JOURNEY");
  const usersSnap = await db.collection("users").get();
  console.log(`Total users: ${usersSnap.size}`);

  let prefsMatched = 0;
  let prefsUnmatched = 0;
  let journeyDocs = 0;
  let journeyMatched = 0;
  let journeyUnmatched = 0;

  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    const prefs = (data.preferences ?? {}) as Record<string, unknown>;
    const prefMapped = detectMappedCanonicalCode(
      mapping,
      asString(prefs.provinceCode),
      asString(prefs.provinceName),
    );
    if (asString(prefs.provinceCode) || asString(prefs.provinceName)) {
      if (prefMapped) {
        prefsMatched++;
      } else {
        prefsUnmatched++;
      }
    }

    const journeySnap = await userDoc.ref
      .collection("journey")
      .doc("summary")
      .collection("provinces")
      .get();

    for (const provinceDoc of journeySnap.docs) {
      journeyDocs++;
      const provinceData = provinceDoc.data();
      const mapped = detectMappedCanonicalCode(
        mapping,
        asString(provinceData.provinceCode),
        asString(provinceData.provinceName),
        provinceDoc.id,
      );
      if (mapped) {
        journeyMatched++;
      } else {
        journeyUnmatched++;
      }
    }
  }

  console.log(`Preferences matched: ${prefsMatched}`);
  console.log(`Preferences unmatched: ${prefsUnmatched}`);
  console.log(`Journey province docs: ${journeyDocs}`);
  console.log(`Journey province docs matched: ${journeyMatched}`);
  console.log(`Journey province docs unmatched: ${journeyUnmatched}`);
}

async function main(): Promise<void> {
  const projectId = await detectProjectId();
  const mapping = await readJsonFile<JsonMap>(DEFAULT_MAPPING_PATH);
  const seeds = await readJsonFile<CanonicalProvinceSeed[]>(DEFAULT_SEED_PATH);
  const seedsByCode = new Map(
    seeds.map((seed) => [normalizeKey(seed.code), seed] as const),
  );

  if (admin.apps.length === 0) {
    admin.initializeApp(projectId ? {projectId} : undefined);
  }
  const db = admin.firestore();

  console.log(`Running province34 audit for project=${projectId ?? "unknown"}`);
  await auditProvinces(db, mapping, seedsByCode);
  await auditRegions(db);
  await auditDishes(db, mapping);
  await auditPlaces(db, mapping);
  await auditUsersJourney(db, mapping);
  console.log("");
  console.log("Province34 audit finished.");
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  if (
    message.includes("Could not load the default credentials") ||
    message.includes("Could not refresh access token") ||
    message.includes("Could not load credentials")
  ) {
    console.error(
      "Province34 audit failed. May nay chua co quyen Firestore local. " +
        "Chay `gcloud auth application-default login` hoac dat " +
        "`GOOGLE_APPLICATION_CREDENTIALS` tro toi service-account json.",
    );
    process.exitCode = 1;
    return;
  }
  console.error("Province34 audit failed.", error);
  process.exitCode = 1;
});
