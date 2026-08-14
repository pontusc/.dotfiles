---
name: kubernetes
description: Kubernetes manifest conventions, applied when writing or editing Kubernetes resource YAML (Deployments, Services, ConfigMaps, Ingress, etc.).
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Kubernetes Manifest Conventions

Conventions for new files and the lines you're changing: on existing files stay surgical and suggest divergences rather than migrating.

## General

- **API version**: Use the current stable API per kind (`apps/v1` Deployments/StatefulSets, `batch/v1` Jobs/CronJobs, `networking.k8s.io/v1` Ingress/NetworkPolicy, `policy/v1` PDB). Avoid deprecated/beta APIs unless required.
- **Namespaces**: Always specify `metadata.namespace`. Never deploy to `default` namespace.

## Labels & Annotations

- **Never add labels or annotations the user didn't ask for.** Do not stamp the
  `app.kubernetes.io/*` recommended set (`name`, `instance`, `version`, `component`,
  `part-of`, `managed-by`), nor `app:`, `tier:`, or `environment:`, by default.
- Add **only** the minimal label pair a selector requires to function (a Deployment's
  `spec.selector.matchLabels` and the matching pod-template label), nothing more.
- On existing manifests, never introduce a label/annotation key that isn't already present.

## Images

- **No `latest` tag**: always pin to a specific version or digest.
- **`imagePullPolicy`**: Set explicitly. Use `IfNotPresent` for tagged images, `Always` only for mutable tags (which should be avoided).

## Security

- **Security contexts**: not added by default. Pods run unhardened unless hardening is asked for. When it is requested, set fields at the correct level: `runAsNonRoot` is pod-level. `allowPrivilegeEscalation`, `readOnlyRootFilesystem`, and `capabilities` are **container-level** and are silently ignored if set only on the pod:

```yaml
# spec.securityContext (pod)
securityContext:
  runAsNonRoot: true

# spec.containers[].securityContext (container)
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

- **Service accounts**: Create dedicated service accounts per workload. Never use `default`.
- **No `hostNetwork`/`hostPID`/`hostIPC`** unless explicitly justified.

## Resource Management

- **Always set `requests` (CPU + memory)**: reflect actual usage.
- Propose a memory `limit` to cap burst. Don't set a CPU `limit` (it throttles via CFS even with spare node capacity). Set limits equal to requests only when you specifically want Guaranteed QoS.
- Use `LimitRange` and `ResourceQuota` at namespace level as guardrails.

## Probes

- **Liveness probe**: Detects deadlocks. Should check internal health, not dependencies.
- **Readiness probe**: Detects readiness to serve. Should check that the app can handle requests.
- **Startup probe**: Use for slow-starting containers to avoid premature liveness kills.
- Set sensible `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, and `failureThreshold`.

## Networking

- **Services**: Use `ClusterIP` by default. Only use `NodePort`/`LoadBalancer` when needed.
- **NetworkPolicies**: Define ingress/egress rules. Default-deny is preferred.

## Structure

- One resource per file, or group tightly related resources (e.g., Deployment + Service + HPA for a single workload).
- Use `---` separator when combining multiple resources in one file.
- File naming: `<resource-kind>-<name>.yaml` (e.g., `deployment-api.yaml`, `service-api.yaml`).
