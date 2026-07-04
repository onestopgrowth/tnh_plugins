import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

const STORAGE_KEY = "tnhiq_onboarding_checked";

const SKIP_PREFIXES = [
  "/founders/onboarding",
  "/admin",
  "/login",
  "/signup",
  "/session",
  "/auth",
  "/safe-mode",
  "/u/",
  "/my/",
  "/email",
  "/password-reset",
];

export default {
  name: "tnhiq-onboarding-redirect",

  initialize() {
    withPluginApi("1.13.0", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (!siteSettings?.tnhiq_onboarding_enabled) {
        return;
      }
      // Skippable mode: never force the redirect.
      if (!siteSettings.tnhiq_onboarding_required) {
        return;
      }

      const user = api.getCurrentUser();
      if (!user) {
        return;
      }

      // Only members of the configured founding group are onboarded.
      const foundingGroup = siteSettings.tnhiq_onboarding_founding_group;
      const groups = (user.groups || []).map((g) => g.name);
      if (!groups.includes(foundingGroup)) {
        return;
      }

      const path = window.location.pathname;
      if (SKIP_PREFIXES.some((p) => path.startsWith(p))) {
        return;
      }

      // Probe once per browser session to avoid hammering the endpoint.
      if (sessionStorage.getItem(STORAGE_KEY) === "1") {
        return;
      }
      sessionStorage.setItem(STORAGE_KEY, "1");

      ajax("/founders/onboarding/status.json")
        .then((data) => {
          if (!data || !data.completed) {
            window.location.href = "/founders/onboarding";
          }
        })
        .catch(() => {
          // best-effort — never block normal navigation if the probe fails
        });
    });
  },
};
