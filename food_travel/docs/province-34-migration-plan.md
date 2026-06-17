# Province 34 Migration Plan

This project currently mixes legacy province data, dish province labels, user
preferences, and journey progress using multiple province key formats. The safe
migration path is:

1. Keep legacy `provinces` as source-of-truth content.
2. Create canonical `provinces_v2` with 34 modern provinces/cities.
3. Add a mapping layer from legacy province code to canonical province code.
4. Backfill dishes, user preferences, and journey summaries with canonical
   fields instead of deleting historical data.

## Recommended Firestore shape

### Legacy collection

`provinces/{legacyProvinceCode}`

- Keep this collection unchanged.
- Keep all local history, gallery, and specialty content here.

### New canonical collection

`provinces_v2/{provinceCode34}`

- `code`
- `name`
- `slug`
- `regionCode`
- `coverImage`
- `imageUrls`
- `description`
- `history`
- `culture`
- `centerLat`
- `centerLng`
- `mergedFrom`
- `legacyCount`
- `status`

### Dishes

Keep current dish fields and backfill:

- `provinceCode34`
- `provinceName34`
- `legacyProvinceCode`

### User preferences

Keep current preference fields and backfill:

- `preferences.provinceCode34`
- `preferences.provinceName34`
- `preferences.legacyProvinceCode`

### Journey

Keep check-in logs as history. Backfill per-user summaries:

- `users/{uid}/journey/summary/provinces_v2/{provinceCode34}`

This allows the app to show modern 34-province progress without losing legacy
detail.

## Files added for this migration

- `functions/src/migrations/province34/data/province_merge_map.sample.json`
- `functions/src/migrations/province34/data/canonical_provinces_34.sample.json`
- `functions/src/migrations/province34/data/province_merge_map.official_2025.json`
- `functions/src/migrations/province34/data/canonical_provinces_34.official_2025.json`
- `functions/src/migrations/province34/migrate.ts`

## Official basis used

The official province-level arrangement used here is based on:

- National Assembly Resolution `202/2025/QH15`, effective on `12/06/2025`
- The Government policy summary page listing the 34 province-level units from
  `12/06/2025`

Important:

- The official count before this arrangement is `63`, not `64`
- The new structure is `34` province-level units:
  - `28` provinces
  - `6` centrally governed cities
- The restructured local governments began operating from `01/07/2025`

## Suggested workflow

1. Review `province_merge_map.official_2025.json` and
   `canonical_provinces_34.official_2025.json`.
2. Keep the sample JSON files only as templates for custom variants if needed.
3. Run the migration in dry-run mode first.
4. Inspect logs and counts.
5. Run apply mode to write:
   - `provinces_v2`
   - dish canonical fields
   - user preference canonical fields
   - `journey/summary/provinces_v2`

## Example commands

From `food_travel/functions`:

```bash
npm run migrate:province34:dry
npm run migrate:province34
```

These commands now default to the official 2025 mapping/seed files.

## Important note

Do not delete legacy data until:

- province detail pages load correctly from canonical keys
- dish queries use canonical keys
- journey map reads canonical 34-province progress
- user preferences have been backfilled
