---
name: kubernetes
description: Kubernetes manifest conventions — applied when writing or editing Kubernetes resource YAML files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# Kubernetes Manifest Conventions

Apply these conventions when writing or editing Kubernetes resource manifests (Deployments, Services, ConfigMaps, etc.).

## General

- **API version**: Use the latest stable API version for each resource kind. Avoid deprecated/beta APIs unless required.
- **Namespaces**: Always specify `metadata.namespace`. Never deploy to `default` namespace.
- **Labels**: Every resource must have at minimum:
  - `app.kubernetes.io/name`
  - `app.kubernetes.io/instance`
  - `app.kubernetes.io/managed-by`

## Images

- **No `latest` tag** — always pin to a specific version or digest.
- **`imagePullPolicy`**: Set explicitly. Use `IfNotPresent` for tagged images, `Always` only for mutable tags (which should be avoided).

## Security

- **Security contexts**: Always set on both pod and container level:

```yaml
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

- **Service accounts**: Create dedicated service accounts per workload. Never use `default`.
- **No `hostNetwork`/`hostPID`/`hostIPC`** unless explicitly justified.

## Resource Management

- **Always set `resources.requests` and `resources.limits`** for CPU and memory.
- Requests should reflect actual usage, limits should cap burst. Don't set them equal unless you want Guaranteed QoS.
- Use `LimitRange` and `ResourceQuota` at namespace level as guardrails.

## Probes

- **Liveness probe**: Detects deadlocks — should check internal health, not dependencies.
- **Readiness probe**: Detects readiness to serve — should check that the app can handle requests.
- **Startup probe**: Use for slow-starting containers to avoid premature liveness kills.
- Set sensible `initialDelaySeconds`, `periodSeconds`, and `failureThreshold`.

## Networking

- **Services**: Use `ClusterIP` by default. Only use `NodePort`/`LoadBalancer` when needed.
- **NetworkPolicies**: Define ingress/egress rules. Default-deny is preferred.

## Structure

- One resource per file, or group tightly related resources (e.g., Deployment + Service + HPA for a single workload).
- Use `---` separator when combining multiple resources in one file.
- File naming: `<resource-kind>-<name>.yaml` (e.g., `deployment-api.yaml`, `service-api.yaml`).
