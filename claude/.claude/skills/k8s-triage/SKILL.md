---
name: k8s-triage
description: Triage a Kubernetes or ArgoCD symptom against the live cluster and return the cause with evidence. Use when the user pastes kubectl, argocd, or pod log output, or reports a pod, sync, PVC, or CNPG problem.
context: fork
agent: investigator
argument-hint: <kube-context> <namespace> <symptom>
---

# Kubernetes Triage

Read-only. Never apply, patch, delete, scale, restart, or sync. Report the cause and hand any fix to the user.

## Target

- Take the context from the argument, else read `kubectl config current-context`. Name it in the report.
- Every context is a read, production included. Run it without asking.
- Pass `-n <namespace>` on every command. Never rely on the context's default namespace.

## Order

Cheapest signal first. Stop once the cause is proven.

1. `kubectl get pods -o wide` and `kubectl get events --sort-by=.lastTimestamp | tail -30`.
2. `kubectl describe` on the failing object. Read `State`, `Last State`, `Reason`, `Exit Code`, and the conditions.
3. `kubectl logs <pod> -c <container> --tail=100`, then `--previous` when the container restarted.
4. Pending pods: node capacity and taints from the event text, then `kubectl get pvc` for a volume that never bound.
5. ArgoCD: `argocd app get <app>` for sync and health state, `argocd app diff <app>` for live against desired. A diff on a controller-mutated field is not drift.
6. CNPG: `kubectl get cluster -o wide`, then the instance pods and their PVCs. A detached volume surfaces as an unbound PVC under a Pending instance.

## Before reporting

- One cause, with the output lines that prove it quoted verbatim.
- When nothing is proven, give the next check and say what was ruled out.
- Write any fix as the command for the user to run, with context and namespace spelled out.
