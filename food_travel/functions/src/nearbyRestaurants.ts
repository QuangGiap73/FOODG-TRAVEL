import {createHash} from "node:crypto";
import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

const serpApiKey = defineSecret("SERPAPI_KEY");
const cacheTtlMs = 8 * 60 * 1000;

type JsonObject = Record<string, unknown>;

interface Restaurant {
  id: string;
  serpDataId: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number | null;
  reviewCount: number;
  price: string | null;
  thumbnail: string | null;
  openState: string | null;
  isOpen: boolean | null;
  distanceMeters: number;
}

/** Converts an unknown value to a JSON object when possible. */
function asObject(value: unknown): JsonObject | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as JsonObject;
}

/** Returns a trimmed string or an empty fallback. */
function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/** Parses a finite number from a JSON value. */
function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string") return null;
  const parsed = Number(value.replace(/[^0-9.-]/g, ""));
  return Number.isFinite(parsed) ? parsed : null;
}

/** Calculates the great-circle distance between two coordinates. */
function distanceMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const earthRadius = 6371000;
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const dLat = radians(lat2 - lat1);
  const dLng = radians(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(radians(lat1)) * Math.cos(radians(lat2)) *
    Math.sin(dLng / 2) ** 2;
  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Normalizes SerpApi open-state text. */
function parseOpenState(item: JsonObject): {
  text: string | null;
  isOpen: boolean | null;
} {
  const text = asString(item.open_state || item.hours) || null;
  if (!text) return {text: null, isOpen: null};
  const normalized = text.toLowerCase();
  if (normalized.includes("closed") || normalized.includes("đóng cửa")) {
    return {text, isOpen: false};
  }
  if (normalized.includes("open") || normalized.includes("mở cửa")) {
    return {text, isOpen: true};
  }
  return {text, isOpen: null};
}

/** Converts one SerpApi result to the public restaurant response. */
function parseRestaurant(
  value: unknown,
  userLat: number,
  userLng: number,
): Restaurant | null {
  const item = asObject(value);
  if (!item) return null;
  const coordinates = asObject(item.gps_coordinates) || {};
  const latitude = asNumber(coordinates.latitude);
  const longitude = asNumber(coordinates.longitude);
  const name = asString(item.title || item.name);
  if (!name || latitude === null || longitude === null) return null;

  const distance = distanceMeters(userLat, userLng, latitude, longitude);
  const dataId = asString(item.data_id || item.data_cid);
  const id = asString(item.place_id || dataId || item.cid) ||
    `${name}-${latitude}-${longitude}`;
  const open = parseOpenState(item);

  return {
    id,
    serpDataId: dataId,
    name,
    address: asString(item.address || item.formatted_address),
    latitude,
    longitude,
    rating: asNumber(item.rating),
    reviewCount: Math.round(asNumber(item.reviews) || 0),
    price: asString(item.price || item.price_range) || null,
    thumbnail: asString(item.thumbnail) || null,
    openState: open.text,
    isOpen: open.isOpen,
    distanceMeters: Math.round(distance),
  };
}

/** Builds a stable cache document ID without exposing the query. */
function cacheId(
  latitude: number,
  longitude: number,
  query: string,
  radius: number,
  language: string,
): string {
  const latBucket = latitude.toFixed(3);
  const lngBucket = longitude.toFixed(3);
  return createHash("sha256")
    .update(`${latBucket}|${lngBucket}|${query}|${radius}|${language}`)
    .digest("hex");
}

export const searchNearbyRestaurants = onCall(
  {secrets: [serpApiKey], timeoutSeconds: 30, memory: "256MiB"},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const input = asObject(request.data) || {};
    const latitude = asNumber(input.latitude);
    const longitude = asNumber(input.longitude);
    if (latitude === null || latitude < -90 || latitude > 90 ||
        longitude === null || longitude < -180 || longitude > 180) {
      throw new HttpsError("invalid-argument", "Invalid coordinates.");
    }

    const rawQuery = asString(input.query) || "quán ăn";
    const query = rawQuery.slice(0, 80);
    const requestedRadius = asNumber(input.radiusMeters) || 5000;
    const radius = Math.round(Math.min(Math.max(requestedRadius, 500), 15000));
    const language = asString(input.language) === "en" ? "en" : "vi";
    const id = cacheId(latitude, longitude, query, radius, language);
    const cacheRef = admin.firestore().collection("serpapi_cache").doc(id);
    const cached = await cacheRef.get();
    const cachedData = cached.data();
    const expiresAt = cachedData?.expiresAt as admin.firestore.Timestamp;
    if (expiresAt?.toMillis() > Date.now() &&
        Array.isArray(cachedData?.restaurants)) {
      return {restaurants: cachedData.restaurants, cached: true};
    }

    const params = new URLSearchParams({
      engine: "google_maps",
      type: "search",
      q: query,
      ll: `@${latitude},${longitude},15z`,
      nearby: "true",
      hl: language,
      gl: "vn",
      api_key: serpApiKey.value(),
    });

    let response: Response;
    try {
      response = await fetch(`https://serpapi.com/search.json?${params}`, {
        signal: AbortSignal.timeout(12000),
      });
    } catch (error) {
      logger.error("SerpApi request failed", {error});
      throw new HttpsError("unavailable", "Restaurant search is unavailable.");
    }
    if (!response.ok) {
      logger.error("SerpApi returned an error", {status: response.status});
      throw new HttpsError("unavailable", "Restaurant search failed.");
    }

    const body = await response.json() as JsonObject;
    if (asString(body.error)) {
      logger.error("SerpApi response error", {error: asString(body.error)});
      throw new HttpsError("resource-exhausted", "Search quota unavailable.");
    }
    const results = Array.isArray(body.local_results) ? body.local_results : [];
    const unique = new Map<string, Restaurant>();
    for (const raw of results) {
      const restaurant = parseRestaurant(raw, latitude, longitude);
      if (!restaurant || restaurant.distanceMeters > radius) continue;
      if (!unique.has(restaurant.id)) unique.set(restaurant.id, restaurant);
    }
    const restaurants = [...unique.values()]
      .sort((a, b) => a.distanceMeters - b.distanceMeters)
      .slice(0, 20);

    await cacheRef.set({
      restaurants,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + cacheTtlMs),
    });
    return {restaurants, cached: false};
  },
);
