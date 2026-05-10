# TNHIQ Discourse Plugins — Integration Directive

Everything you need to wire these plugins into the rest of the ecosystem.
Read this before deploying.

---

## At a glance

| Plugin | Calls out to | Receives calls from | Production secrets needed |
|---|---|---|---|
| niche-onboarding | `tnh-comm-api` (CRM sync) | none | RSS none; needs CRM endpoint live |
| opportunities | none | external load board (ingest webhook) | `tnhiq_opportunities_ingest_secret` |
| sponsors | none | none (admin UI only) | none |
| podcast | configured RSS feed | none | `tnhiq_podcast_rss_url` |
| skeleton | none | none | none — disable in prod or leave as smoke test |

---

## Section 1 — `tnh-comm-api` (NestJS) endpoints to add

Only **one new endpoint** is required for the plugins to work end-to-end.

### `POST /discourse/member-profile`  (NEW)

Receives onboarding answers when a community member completes their first-login niche flow. The NestJS backend should forward these to GoHighLevel CRM (per the master directive's "Content Engine — GoHighLevel CRM Segmentation Logic" section).

**Caller:** `tnhiq-niche-onboarding` plugin → backend
**Authentication:** *Currently not implemented in the plugin.* Recommend either:

- **Option A — Bearer token (simplest):** Plugin sends `Authorization: Bearer <shared_secret>`. Add a new SiteSetting `tnhiq_niche_onboarding_crm_token` and have `crm_notifier.rb` include it. Backend matches against an env var.
- **Option B — HMAC signature (matches existing pattern):** Plugin signs the JSON body with `DISCOURSE_WEBHOOK_SECRET` and sends `X-TNHIQ-Signature: sha256=...`. Backend verifies the same way `activity.controller.ts` already verifies the inbound Discourse webhook.

> **TODO before launch:** the plugin currently sends an unauthenticated POST. Pick one of the schemes above and update [`tnhiq-niche-onboarding/lib/tnhiq_niche_onboarding/crm_notifier.rb`](./tnhiq-niche-onboarding/lib/tnhiq_niche_onboarding/crm_notifier.rb).

**Request body:**
```json
{
  "discourse_user_id": 123,
  "email": "member@example.com",
  "niche": "owner_operator",
  "equipment": ["dry_van", "reefer"],
  "stage": "growing"
}
```

**Field constraints (enforced at plugin):**
- `niche`: one of `owner_operator | fleet_owner | freight_broker | dispatcher | last_mile_dsp | box_truck | hotshot | warehousing_3pl | getting_started`
- `equipment[]`: subset of `dry_van | reefer | flatbed | step_deck | rgn | box_truck | cargo_van | sprinter | hotshot_trailer | other`
- `stage`: one of `pre_launch | year_one | growing | scaling | established`

**Expected response:** any 2xx (200, 201, 202, 204). The plugin treats anything outside that range as a failure and logs a warning. The user-facing flow does **not** block on CRM sync — it's fire-and-forget via Sidekiq job.

**Idempotency:** the plugin retries via Sidekiq's default retry policy. Backend should be idempotent on `(discourse_user_id, email)`.

---

## Section 2 — Inbound webhooks the plugins expose

These are endpoints **on Discourse** that external systems POST to.

### `POST https://community.tnhiq.com/discourse-plugin/opportunities/ingest`

Curated opportunities (loads, partnerships, direct shippers) get pushed in by Michael's external load board project. Discourse never queries the load board — the load board pushes to Discourse.

**Caller:** external load board project
**Authentication:** `Authorization: Bearer <secret>`. Secret is stored in Discourse SiteSetting `tnhiq_opportunities_ingest_secret`. **Set this before exposing the endpoint** — until it's set, the endpoint returns `503 ingest_secret_not_configured` (safe-fail default).

**Request body:**
```json
{
  "external_reference_id": "J20-LANE-001",
  "title": "Atlanta → Dallas dry van",
  "description": "Weekly recurring lane",
  "equipment_type": "dry_van",
  "origin_state": "GA",
  "destination_state": "TX",
  "commodity": "General freight",
  "source_type": "broker_partner",
  "source_label": "J20 Logistics",
  "tier_required": "core",
  "requires_verified": true,
  "expires_at": "2026-06-30T23:59:59Z",
  "status": "active"
}
```

**Field reference:**
- `external_reference_id` (required, unique): the load board's primary key. Re-posting with the same id **upserts** instead of creating duplicates.
- `equipment_type`: optional. One of `dry_van | reefer | flatbed | step_deck | rgn | box_truck | cargo_van | sprinter | hotshot_trailer | other`.
- `origin_state` / `destination_state`: 2-character US state (auto-uppercased).
- `source_type`: one of `direct_shipper | broker_partner | internal` (default `internal`).
- `tier_required`: one of `free | core | premium | founder` (default `free`). Members below this tier won't see the opportunity.
- `requires_verified`: `true` if only IQDID-verified carriers can express interest. Until the IQDID plugin ships, only staff users count as verified.
- `status`: `active | expired | archived | draft` (default `active`).

**Response:**
- `200 {"ok":true,"id":N,"created":true|false}` on success
- `401 {"ok":false,"error":"unauthorized"}` on bad/missing token
- `422` on validation errors (returns `{errors: [...]}`)
- `503 {"ok":false,"error":"ingest_secret_not_configured"}` if SiteSetting not set

---

## Section 3 — IQDID integration (Step 2, deferred)

The IQDID plugin is your responsibility (per session conversation). The opportunities plugin already has an `IqdidGate` stub that reads `user.custom_fields["iqdid_credential_type"]`. When you build the IQDID plugin, **just have it write that custom field** on successful verification — the opportunities plugin will pick it up automatically with no code changes.

The **5 verified badges** are already created on the live Discourse and ready to be granted by your IQDID plugin:

| Badge ID | Name |
|---|---|
| 111 | Verified Operator |
| 112 | Verified Broker |
| 113 | Verified Dispatcher |
| 114 | Verified Direct Shipper |
| 115 | Verified Driver |

The IQDID plugin should: (a) write the credential type to the user custom field, and (b) call `BadgeGranter.grant(badge, user)` for the matching badge.

---

## Section 4 — SiteSettings to configure in production

After plugins are installed, set these via the Discourse admin UI (`/admin/site_settings`) or a Rails runner one-liner.

| SiteSetting | Plugin | Required? | Notes |
|---|---|---|---|
| `tnhiq_niche_onboarding_enabled` | onboarding | yes | default `true` |
| `tnhiq_niche_onboarding_crm_url` | onboarding | yes | default `https://tnh-comm-api.onrender.com` — switch to `https://api.tnhiq.com` once that endpoint exists |
| `tnhiq_niche_onboarding_crm_timeout_seconds` | onboarding | optional | default 10 |
| `tnhiq_opportunities_enabled` | opportunities | yes | default `true` |
| `tnhiq_opportunities_ingest_secret` | opportunities | **yes — endpoint refuses requests until set** | random 32+ char string. Share with the load board project. |
| `tnhiq_opportunities_default_page_size` | opportunities | optional | default 25 |
| `tnhiq_sponsors_enabled` | sponsors | yes | default `true` |
| `tnhiq_podcast_enabled` | podcast | yes | default `true` |
| `tnhiq_podcast_rss_url` | podcast | **yes — scheduled poller no-ops without it** | the podcast RSS feed URL |
| `tnhiq_podcast_default_category` | podcast | optional | default `announcements` |
| `tnhiq_podcast_pin_days` | podcast | optional | default 7 |
| `tnhiq_podcast_max_per_poll` | podcast | optional | default 5 — limits how many episodes one poll may ingest |

Set them in bulk via Rails runner:
```ruby
SiteSetting.tnhiq_opportunities_ingest_secret = ENV["TNHIQ_INGEST_SECRET"]
SiteSetting.tnhiq_podcast_rss_url = "https://feeds.example.com/trucknhustle.rss"
SiteSetting.tnhiq_niche_onboarding_crm_url = "https://api.tnhiq.com"
```

---

## Section 5 — One-time live Discourse state (already done)

These are already configured on `community.tnhiq.com` and **don't need re-applying**. Documented here so Cline knows the state exists and shouldn't redo it.

- 7 topic categories: `getting-started`, `freight-brokerage`, `owner-operators`, `last-mile`, `business-growth`, `announcements`, `staff-internal`
- 7 groups: `tnh_free`, `tnh_core`, `tnh_premium`, `tnh_founder`, `tnh_staff`, `tnh_moderator`, `tnh_alumni`
- Chat parent category (`Chat`, id 14) with 9 sub-categories and 9 chat channels (broker-talk, dispatch-desk, owner-operator-check-in, lane-watch, last-mile-room, hotshot-room, box-truck-room, business-growth-chat, staff-internal). Free tier sees the 2 funnel channels; paid tiers see everything except staff-internal.
- 6 official Discourse plugins enabled: Chat, Solved, Topic Voting, Gamification, Calendar, Reactions
- 5 verified badges (IDs 111–115)
- Outbound webhook (id 1): Discourse → `https://tnh-comm-api.onrender.com/discourse/webhook` for `post_created` events. Already firing successfully (last_delivery_status=3).
- `default_categories_muted = "14"` so the Chat parent doesn't clutter the homepage feed

**Still pending:** install Discourse Docs plugin (requires `containers/app.yml` edit + `./launcher rebuild app` — bounces site for 10–15 min).

---

## Section 6 — What to verify after deployment

Smoke checks Cline should run after `./launcher rebuild app` completes:

```bash
# Plugin endpoints respond
curl -i https://community.tnhiq.com/skeleton-test
# Should 200 with JSON: {"ok":true,"plugin":"tnhiq-skeleton",...}

# Onboarding endpoint requires auth
curl -i https://community.tnhiq.com/onboarding/status.json
# Should 403 not_logged_in

# Opportunities ingest refuses without configured secret
curl -i -X POST https://community.tnhiq.com/discourse-plugin/opportunities/ingest \
  -H "Authorization: Bearer wrong" -H "Content-Type: application/json" -d '{}'
# After secret is set: should 401 unauthorized (not 503)

# Sponsor click endpoint exists
curl -i "https://community.tnhiq.com/sponsor-click?placement_id=999"
# Should 404 "Placement not found." (not the Discourse SPA shell)

# Podcast admin dashboard renders for admin users
curl -i -H "Api-Key: <KEY>" -H "Api-Username: <ADMIN>" \
     https://community.tnhiq.com/admin/plugins/tnhiq-podcast/dashboard
# Should 200 HTML with title "Podcast Engine — TNHIQ Admin"
```

If any of those return Discourse's SPA shell (`<title>Discourse</title>`) instead of the plugin response, the plugin didn't load — check `/var/log/discourse/rails/production.log` for `tnhiq` errors.

---

## Phase B (deferred, not blocking launch)

Things explicitly not built in this iteration. None are required to ship Phase 1.

- Per-plugin admin Ember UI (currently uses ERB pages + JSON CRUD)
- `Jobs::ScheduledExpireOpportunities` — daily job to mark expired opportunities (the model query `expired_now` is ready; just needs a Scheduled job wrapper)
- Email/Discourse notifications to opportunity poster when someone expresses interest
- Sponsor impression tracking (clicks only currently)
- Sponsor click report CSV export
- Podcast unpin job — **not needed**, Discourse natively unpins via `pinned_until`

---

*Last updated: 2026-05-10*
