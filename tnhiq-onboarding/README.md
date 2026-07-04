# tnhiq-onboarding

Founder's Circle onboarding + member routing for the Truck N' Hustle Discourse community.

On first login, a paid founding member takes a short 6-question assessment, gets classified into one of six starting paths, has their answers saved to their profile, is added to the matching path group, and is sent to their recommended next step — so nobody lands in a blank community.

## How it fits the stack

- **Backend (`tnh-comm-api`)** still owns Stripe billing and adds paying members to the `founding_member` group. It does **not** run the intake.
- **This plugin** owns the in-forum onboarding: intake → path → groups → result. Triggered on first login for `founding_member`s.
- Reuses the **already-provisioned** groups and categories (`founders-circle-setup.rb`). It does not create them.

Flow: pay → backend sets `founding_member` → SSO into Discourse → plugin prompts onboarding on first login.

## Routes

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/founders/onboarding` | Assessment page (redirects to result if already done) |
| GET | `/founders/onboarding/status` | JSON `{ completed, path }` — used by the redirect initializer |
| POST | `/founders/onboarding/submit` | Validate + store answers, assign path + group |
| GET | `/founders/onboarding/result` | Recommended-path result page |
| GET | `/admin/plugins/tnhiq-onboarding/report` | Staff-only aggregate report (JSON) |

## Settings (Admin → Settings → Plugins)

`tnhiq_onboarding_enabled` (default **false** — turn on to go live), `tnhiq_onboarding_founding_group` (`founding_member`), `tnhiq_onboarding_required` (redirect vs skippable), `tnhiq_onboarding_assign_path_groups`, the three destination URLs (`intro`/`roundtable`/`start_here`), and one group-name setting per path (defaults match the provisioned groups — all ≤ 20 chars, Discourse's limit).

## User custom fields

`tnhiq_stage`, `tnhiq_interests` (json), `tnhiq_pain_point`, `tnhiq_resources` (json), `tnhiq_goal_90_day`, `tnhiq_help_wanted` (json), `tnhiq_path`, `tnhiq_onboarding_completed_at`.

## Path routing

Deterministic, no scoring engine. Priority: **vendor → small fleet → non-asset → driver/owner-operator → specialized → beginner**, with a beginner-signal exception (exploring / not-sure / choose-business / choose-lane routes to Beginner Explorer unless clearly vendor or small fleet). See `lib/tnhiq_onboarding/path_assigner.rb` (unit-tested in `spec/`), mirroring the backend logic.

## ⚠️ Deployment note (read before rebuilding)

Discourse only loads plugins that are **direct children** of `plugins/` (`plugins/<name>/plugin.rb`). This repo (`tnh_plugins`) is a **monorepo** — `app.yml` clones it to `plugins/tnh_plugins/`, which puts every plugin one level too deep, so **none of the `tnhiq-*` plugins load as-is**. Before the next `./launcher rebuild app`, fix the `hooks:` block in `containers/app.yml` to symlink each plugin up one level, e.g.:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/onestopgrowth/tnh_plugins.git
          - ln -sf tnh_plugins/tnhiq-onboarding tnhiq-onboarding
```

(Repeat the `ln -sf` for any other tnhiq plugin you want active.) Then rebuild. A rebuild is ~8–10 min of downtime — do it in a low-traffic window, and note the droplet is only 2 GB (consider resizing first).

## Testing

```
cd /var/www/discourse
bin/rspec plugins/tnhiq-onboarding/spec
```

## Reporting via Data Explorer (already installed)

Instead of custom report UI, use the `discourse-data-explorer` plugin. Example queries:

```sql
-- Completions by assigned path
SELECT value AS path, COUNT(*) AS members
FROM user_custom_fields WHERE name = 'tnhiq_path'
GROUP BY value ORDER BY members DESC;

-- Completions by stage
SELECT value AS stage, COUNT(*) AS members
FROM user_custom_fields WHERE name = 'tnhiq_stage'
GROUP BY value ORDER BY members DESC;

-- Completions by biggest challenge
SELECT value AS pain_point, COUNT(*) AS members
FROM user_custom_fields WHERE name = 'tnhiq_pain_point'
GROUP BY value ORDER BY members DESC;

-- Total onboarded
SELECT COUNT(*) FROM user_custom_fields WHERE name = 'tnhiq_onboarding_completed_at';
```

The staff endpoint `/admin/plugins/tnhiq-onboarding/report` returns the same aggregates as JSON.

## V1 scope

Intake → tag → assign path → route. **Not** built (intentionally): scoring engine, AI recommendations, marketplace, LMS, media library. Does not modify Discourse core.
