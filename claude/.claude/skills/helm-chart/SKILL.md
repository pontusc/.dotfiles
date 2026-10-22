---
name: helm-chart
description: Authoring Helm charts (Chart.yaml, templates, helpers, library charts, values.schema.json, OCI packaging), not consuming third-party charts.
user-invocable: false
allowed-tools: Read, Glob, Grep, Bash
paths:
  - "**/Chart.yaml"
  - "**/templates/**"
  - "**/values.schema.json"
---

# Authoring Helm Charts

- Start from the `helm create` layout and helper names (`<chart>.name`, `.fullname`, `.labels`, `.selectorLabels`). Inside `templates/`, its `app.kubernetes.io/*` label set replaces the `kubernetes` skill's label rule, and the rendered output from `helm template` replaces its file-level dry-run.
- Selector labels are `name` and `instance` only. Selectors are immutable after first install, so never put `version`, `helm.sh/chart` or anything that changes per release into them.
- A library chart (`type: library`) only `define`s named templates, prefixed `<library>.`. It renders nothing itself. App charts depend on it in `Chart.yaml` and run `helm dependency update` after every library version bump.
- Expose a value only when a consumer sets it differently. Everything else is literal in the template. Values with no safe default use `required`.
- `values.schema.json` covers every exposed key, with `additionalProperties: false` at each object level so a typo in an override fails instead of being silently ignored.
- `version` is strict SemVer and is the artifact identity. `appVersion` is the image tag and the default for `image.tag`. Never reuse a `version` for different content.
- OCI: `helm push <chart>-<version>.tgz oci://<host>/<path>`. The chart name becomes the last path segment and `version` becomes the tag, with any `+` rewritten to `_`.

## Before reporting

- `helm lint --strict` on each chart, with each environment's values file.
- `helm template` with each values file, piped to `kubectl apply --dry-run=client -f -`.
- Confirm no selector carries a label outside `name` and `instance`.
