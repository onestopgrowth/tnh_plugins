# TNHIQ Discourse Plugins

Five custom Discourse plugins powering the TNHIQ community platform.

| Plugin | Purpose |
|---|---|
| `tnhiq-skeleton` | Health-check / dev environment proof. Safe to disable in prod. |
| `tnhiq-niche-onboarding` | First-login niche selection flow → CRM sync to `tnh-comm-api` |
| `tnhiq-opportunities` | Curated opportunity board with tier + IQDID gating + ingest webhook |
| `tnhiq-sponsors` | Sponsor placements with niche/group/category targeting + click tracking |
| `tnhiq-podcast` | Auto-ingest podcast RSS → tagged + pinned topics in matching niche category |

All plugins were verified end-to-end in a local Discourse dev container before commit. Verification details are in the commit history.

## Deployment

Each subdirectory is a self-contained Discourse plugin (`plugin.rb` at root, standard Discourse layout).

For self-hosted Discourse on the DigitalOcean droplet:

1. Add a clone hook to `containers/app.yml` under `hooks: after_code:`. Example for one plugin:
   ```yaml
   - exec:
       cd: $home/plugins
       cmd:
         - git clone --depth=1 https://github.com/onestopgrowth/tnhiq-discourse-plugins.git tnhiq-bundle
         - ln -sf $home/plugins/tnhiq-bundle/tnhiq-niche-onboarding $home/plugins/tnhiq-niche-onboarding
         - ln -sf $home/plugins/tnhiq-bundle/tnhiq-opportunities    $home/plugins/tnhiq-opportunities
         - ln -sf $home/plugins/tnhiq-bundle/tnhiq-sponsors         $home/plugins/tnhiq-sponsors
         - ln -sf $home/plugins/tnhiq-bundle/tnhiq-podcast          $home/plugins/tnhiq-podcast
   ```
2. Run `./launcher rebuild app`. Migrations run automatically on container boot.
3. After rebuild, set required SiteSettings via the admin UI or Rails runner — see [INTEGRATION.md](./INTEGRATION.md).

## Local development

The plugins were developed against a vanilla Discourse `bin/docker/boot_dev` container. To work on them:

1. Clone Discourse: `git clone https://github.com/discourse/discourse.git`
2. Symlink each plugin into `discourse/plugins/`
3. `bin/docker/boot_dev --init` (one-time, ~3GB image pull)
4. `bin/docker/migrate` then `bin/docker/rails server`
5. Hit `http://localhost:3000/skeleton-test` to confirm load

## Required dev gotchas

- **Plugin file edits do NOT auto-reload.** Restart Rails (`pkill -f pitchfork` inside the container, then re-run rails server) after every plugin file change.
- **Always `skip_before_action :check_xhr`** for any plugin route that returns non-JSON to non-XHR clients.
- **Avoid path prefix `/s/`** — `discourse-subscriptions` claims it.
- **Avoid bare `/admin/plugins/<name>`** — Discourse's plugin metadata viewer shadows it. Use `/admin/plugins/<name>/dashboard` or similar.
