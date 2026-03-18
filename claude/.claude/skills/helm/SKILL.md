---
name: helm
description: Helm chart conventions — applied when writing or editing Helm charts, templates, and values files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---

# Helm Chart Conventions

Apply these conventions when writing or editing Helm charts, templates, and values files.

## Before Making Changes

**Always locate and read the relevant values file first.** Before editing any template or values:

1. Find the chart's `values.yaml` — this is the source of truth for defaults.
2. Check for environment-specific overrides (e.g., `values-prod.yaml`, `values-staging.yaml`, `values.<env>.yaml`).
3. If a helmfile is present (`helmfile.yaml`), read it to understand which values files are composed and in what order.
4. Verify the value you're adding/changing isn't already defined elsewhere in the override chain.

## Chart Structure

Standard layout:

```
chart-name/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
└── charts/          # subcharts (if any)
```

## Values

- **Flat where possible**: Avoid deeply nested structures that are hard to override.
- **Document values**: Add comments above each key in `values.yaml` explaining its purpose and valid options.
- **Sensible defaults**: `values.yaml` should produce a working deployment with minimal overrides.
- **No secrets in values**: Reference external secrets (ExternalSecrets, SealedSecrets, or CSI driver). Never commit plaintext secrets.

## Templates

- **Use `_helpers.tpl`** for reusable template definitions (labels, names, selectors).
- **Standard labels**: Use the helpers to generate consistent `app.kubernetes.io/*` labels across all resources.
- **`toYaml | nindent`**: When inserting structured values, always pipe through `toYaml` and `nindent` for correct indentation.
- **Conditional resources**: Wrap optional resources in `{{- if .Values.feature.enabled }}`.
- **Quote strings**: Use `{{ .Values.foo | quote }}` for string values in templates to prevent YAML parsing issues.

## Validation

When modifying a chart:

- Run `helm template <release> <chart> -f <values>` to verify rendered output.
- Check that all Kubernetes conventions from the `kubernetes` skill are followed in the rendered manifests.
- Verify no duplicate resource names or missing required fields.

## Dependencies

- Pin subchart versions in `Chart.yaml` — no floating ranges.
- Run `helm dependency update` after changing dependencies.
- Commit the `Chart.lock` file.
