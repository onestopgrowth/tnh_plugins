import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

const STORAGE_KEY = "tnhiq_onboarding_checked";

const SKIP_PREFIXES = [
  "/onboarding",
  "/admin",
  "/login",
  "/signup",
  "/session",
  "/auth",
  "/safe-mode",
  "/u/",
  "/email",
  "/password-reset",
];

export default {
  name: "tnhiq-onboarding-redirect",

  initialize() {
    withPluginApi("1.13.0", (api) => {
      const user = api.getCurrentUser();
      if (!user) {
        return;
      }

      const path = window.location.pathname;
      if (SKIP_PREFIXES.some((p) => path.startsWith(p))) {
        return;
      }

      if (sessionStorage.getItem(STORAGE_KEY) === "1") {
        return;
      }
      sessionStorage.setItem(STORAGE_KEY, "1");

      ajax("/onboarding/status.json")
        .then((data) => {
          if (!data || !data.completed) {
            window.location.href = "/onboarding";
          }
        })
        .catch(() => {
          // best-effort — never block normal navigation if probe fails
        });
    });
  },
};
