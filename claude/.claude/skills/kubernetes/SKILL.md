---
name: kubernetes
description: Kubernetes manifest conventions, applied when writing or editing resource YAML (Deployments, Services, ConfigMaps, Ingress).
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.yaml"
  - "**/*.yml"
---

# Kubernetes Manifests

- Always set `metadata.namespace`. Never deploy to `default`.
- Never add a label or annotation the user did not ask for: no `app.kubernetes.io/*` recommended set (`name`, `instance`, `version`, `component`, `part-of`, `managed-by`), no `app:`, `tier:`, or `environment:`. Add only the minimal pair a selector needs to function, a Deployment's `spec.selector.matchLabels` and the matching pod-template label. On an existing manifest, never introduce a key that is not already present.
- One resource per file, or one workload's tightly related resources together (Deployment, Service, HPA), separated by `---`. File naming: `<resource-kind>-<name>.yml`.
- Security contexts are not added by default, pods run unhardened unless hardening is asked for.
- `runAsNonRoot` is pod-level, while `allowPrivilegeEscalation`, `readOnlyRootFilesystem`, and `capabilities` are container-level and are silently ignored if set only on the pod.
- A dedicated service account per workload. Never `default`.
- Always set CPU and memory `requests`, reflecting actual usage. Propose a memory `limit` to cap burst. No CPU `limit`, it throttles through CFS even with spare node capacity. Limits equal to requests only when Guaranteed QoS is the goal.
- `LimitRange` and `ResourceQuota` at namespace level as guardrails.
- Liveness, readiness, and startup probes all present.
- NetworkPolicy with explicit ingress and egress rules, default-deny preferred.

## Before reporting

- Run `kubectl apply --dry-run=client -f <file>`.
- Grep for a missing `metadata.namespace` and for `cpu:` under `limits`.
- Confirm each securityContext field sits at the level where it takes effect.
- Confirm no label or annotation key was added that the file did not already carry.
