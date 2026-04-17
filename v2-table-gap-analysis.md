# GTHO v2 Table Gap Analysis

**Source:** v1 production Supabase schema (38 tables) vs v2 ARCHITECTURE.md entity specs

---

## Spec'd in v2 (10 tables mapped from v1)

| v1 Table | v2 Entity | v2 Section | Notes |
|---|---|---|---|
| operations | operations | §8a | CREATE TABLE defined |
| farms | farms | §8a | CREATE TABLE defined |
| animals | animals | §4e | Full ANIMAL_FIELDS |
| animal_groups | groups | §4e | Renamed. Full GROUP_FIELDS |
| pastures | pastures | §4e | Full PASTURE_FIELDS |
| events | events | §4b | Full EVENT_FIELDS |
| batches | batches | §4e | Full BATCH_FIELDS |
| feed_types | feed_types | §4e | Full FEED_TYPE_FIELDS |
| surveys | surveys | §4e | Full SURVEY_FIELDS |
| event_sub_moves | sub_moves | §4f | Renamed. Full SUB_MOVE_FIELDS |

## Partially mapped (2 tables — v2 renames or redesigns)

| v1 Table | v2 Entity | Notes |
|---|---|---|
| event_feed_deliveries | event_feed_entries | v2 redesigns feed deliveries as a ledger model. Different columns. |
| event_feed_residual_checks | event_residual_checks | Renamed. Schema defined in §4f. |

## New in v2 (not in v1)

| v2 Entity | Section | Purpose |
|---|---|---|
| amendments | §4e | Soil/pasture amendments (replaces input_applications?) |
| app_logs | §22a | Structured logging |
| feedback | §23b | Bug reports / feature requests (replaces submissions?) |

---

## NOT SPEC'D IN V2 — 26 missing tables

### Setup / Config (6 tables)

These are Tier 0 and Tier 1 setup tables that define the operation's reference data. Without them, many features can't function.

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **operation_settings** | operation_id, data (jsonb) | Global app settings per operation | HIGH — settings drive calculations, display prefs, DMI defaults |
| **forage_types** | 12 cols incl. dm_pct, NPK rates, dm_lbs_per_inch_per_acre, min_residual_height | Pasture forage assignments, DMI calcs, height-based yield | HIGH — pastures reference forage_type_id, all grass calcs depend on this |
| **animal_classes** | name, species, archived | Group classification, class-based head counts | MEDIUM — groups reference class_id |
| **treatment_types** | name, category, archived | Health event treatment dropdown | LOW until health events are built |
| **input_products** | name, type, NPK rates, cost_per_unit | Input application product catalog | LOW until input tracking is built |
| **ai_bulls** | name, breed, tag, archived | AI breeding records | LOW until breeding is built |

### Livestock Health & Breeding (4 tables)

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **animal_health_events** | 24 cols incl. BCS, treatments, breeding, calving, withdrawal dates | Individual animal health records, breeding, calving | MEDIUM — core livestock management feature |
| **animal_weight_records** | weight_lbs, recorded_at, source | Weight tracking, ADG calculations | MEDIUM — weight gain is key metric |
| **animal_group_memberships** | group_id, animal_id, date_joined, date_left, reason | Track which animals are in which groups over time | MEDIUM — needed for accurate head counts at any date |
| **animal_group_class_compositions** | group_id, class_id, count, effective_date | Class-based composition of groups (for operations that don't tag individuals) | MEDIUM — many operations manage by class not individual |

### Event Child Tables (3 tables)

These are part of the event ledger. v2 specs sub_moves, feed_entries, and residual_checks but misses three others.

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **event_group_memberships** | group_id, head_snapshot, weight_snapshot, date_added/removed | Which groups were on an event and when | HIGH — events need to know which groups are grazing |
| **event_paddock_windows** | pasture_id, is_primary, acres, date_added/removed | Which paddocks were open during an event | HIGH — multi-paddock events, rotation tracking |
| **event_npk_deposits** | N/P/K lbs, head, avg_weight, days, acres, npk_value | Fertility ledger — manure nutrient deposits | MEDIUM — the "fertility ledger" is a stated v2 goal |

### Harvest & Forage (2 tables)

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **harvest_events** | date, notes | Hay cutting records | MEDIUM — tracks when fields were cut |
| **harvest_event_fields** | 15 cols incl. land_id, feed_type_id, quantity, weight, NPK, batch_id | Per-field harvest detail, auto-creates batches | MEDIUM — connects hay harvest to feed inventory |

### Soil & Input Tracking (4 tables)

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **soil_tests** | N/P/K, pH, organic_matter, lab | Soil health baseline per paddock | MEDIUM — informs amendment decisions |
| **input_applications** | product_id, source_type, NPK totals, cost | Commercial fertilizer / amendment applications | MEDIUM — tracks what's been applied |
| **input_application_locations** | pasture_id, acres, NPK lbs, cost_share | Per-paddock breakdown of an application | MEDIUM — location-level tracking |
| **batch_nutritional_profiles** | 13 cols incl. protein, ADF, NDF, TDN, RFV | Lab test results per feed batch | LOW-MEDIUM — feed quality data |

### Manure Tracking (2 tables)

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **manure_batches** | 16 cols incl. source_event_id, NPK, estimated/remaining volume | Collected manure inventory | MEDIUM — manure as a trackable resource |
| **manure_batch_transactions** | type, volume_lbs, NPK, source_event_id, application_id | Ledger of manure collection and application | MEDIUM — connects grazing → manure → application |

### System / Meta (3 tables)

| v1 Table | Columns | Used By | Gap Impact |
|---|---|---|---|
| **operation_members** | user_id, display_name, role, field_mode, field_modules, email, invited/accepted | Multi-user access, roles, field mode config | HIGH — multi-user is in v2 scope (§8a auth) |
| **submissions** | 20+ cols incl. cat, status, priority, thread, dev_response | Bug/feature tracking from within the app | LOW — v2 has feedback table as replacement |
| **release_notes** | version, resolved_items, notes | In-app changelog display | LOW — nice-to-have |
| **todos** | title, status, paddock, animal_id, assigned_to | In-app task list per operation | LOW — separate feature |

---

## Where should these live in the v2 architecture?

The v2 architecture doc uses checkpoints (CP1-CP24) and entity sections (§4b-§4k). Here's where each gap fits:

### Must be added to existing checkpoints

| Missing Table | Belongs In | Reason |
|---|---|---|
| operation_settings | CP1 (project scaffold) or CP14 (auth/onboarding) | Settings are needed from day 1 |
| forage_types | CP11 (pastures) | Pastures reference forage_type_id |
| animal_classes | CP12 (animals) | Groups reference class_id |
| event_group_memberships | CP7-CP10 (event CRUD) | Events must track which groups are grazing |
| event_paddock_windows | CP7-CP10 (event CRUD) | Events must track which paddocks are open |
| operation_members | CP14 (auth) | Multi-user access |
| animal_group_memberships | CP12 (animals) or CP13 (dashboard) | Need membership history for accurate counts |
| animal_group_class_compositions | CP12 (animals) | Class-based herd composition |

### Should be added to later checkpoints (CP17-CP24)

| Missing Table | Belongs In | Reason |
|---|---|---|
| event_npk_deposits | CP17 (fertility ledger) | Core fertility tracking |
| harvest_events + harvest_event_fields | CP19 (harvest) | Hay cutting records |
| soil_tests | CP22 (soil module) | Soil health tracking |
| input_applications + input_application_locations | CP22 (inputs) | Amendment/fertilizer tracking |
| manure_batches + manure_batch_transactions | CP22 (manure) | Manure nutrient cycle |
| batch_nutritional_profiles | CP20 (DMI) or CP22 | Feed quality lab results |
| animal_health_events | CP17 or new CP | Health/breeding/calving |
| animal_weight_records | CP17 or new CP | Weight tracking |
| treatment_types | with animal_health_events | Reference data for treatments |
| input_products | with input_applications | Reference data for inputs |
| ai_bulls | with animal_health_events | Reference data for AI breeding |

### Probably fine to defer or drop

| Table | Reason |
|---|---|
| submissions | v2 replaces with feedback table |
| release_notes | Nice-to-have, can add anytime |
| todos | Separate feature, not core grazing |

---

## Summary

- **v1 production:** 38 tables
- **v2 spec'd:** 12 mapped from v1 + 3 new = 15 total
- **Missing from v2 spec:** 26 tables
- **HIGH impact gaps:** operation_settings, forage_types, event_group_memberships, event_paddock_windows, operation_members
- **The 5 HIGH gaps will block basic functionality** — events can't track groups or paddocks, pastures can't reference forage types, settings don't persist, and multi-user doesn't work

The architecture doc needs an update to at minimum acknowledge all 26 missing tables and assign them to checkpoints, even if the full schema isn't written yet.
