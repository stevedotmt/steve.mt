---
title: "Kubernetes Conditions"
date: "2026-06-25"
draft: false
tags: ["Kubernetes"]
---

Many Kubernetes resources show `conditions` in their `status`. You can quickly view them with `kubectl describe`.

```text
$ kubectl describe pod/nginx
...
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
...
```

Conditions appear as a list. Each condition type represents a separate observation about the resource, not a step in one shared state machine.
You generally cannot summarize a resource by assuming all conditions should be `True`; some condition types use `False` as the healthy value.

The modern standard condition shape, [`metav1.Condition`](https://kubernetes.io/docs/reference/kubernetes-api/definitions/condition-v1-meta/), has these fields:

- `Type`: the name of the condition, usually PascalCase or CamelCase, such as `Ready`.
- `Status`: one of `True`, `False`, or `Unknown`.
- `Reason`: a machine-readable, usually CamelCase identifier that explains why the condition has its current status.
- `Message`: a human-readable message with more detail.
- `ObservedGeneration`: the `.metadata.generation` the condition was computed from, which is useful for knowing whether the status reflects the latest spec.
- `LastTransitionTime`: when the condition last changed status.

## Walkthrough: a Pod becoming ready

For a simple `nginx` Pod without init containers, the conditions might move like this:

```text
# 1. Created, but not scheduled yet
PodScheduled                False
Initialized                 False
PodReadyToStartContainers   False
ContainersReady             False
Ready                       False

# 2. The scheduler picked a node
PodScheduled                True
Initialized                 False
PodReadyToStartContainers   False
ContainersReady             False
Ready                       False

# 3. There are no init containers, so the Pod is initialized
PodScheduled                True
Initialized                 True
PodReadyToStartContainers   False
ContainersReady             False
Ready                       False

# 4. The Pod sandbox and networking are ready
PodScheduled                True
Initialized                 True
PodReadyToStartContainers   True
ContainersReady             False
Ready                       False

# 5. Containers are running, and readiness probes pass
PodScheduled                True
Initialized                 True
PodReadyToStartContainers   True
ContainersReady             True
Ready                       True

# 6. Later, a readiness probe starts failing
PodScheduled                True
Initialized                 True
PodReadyToStartContainers   True
ContainersReady             False
Ready                       False
```

The important part is that only the relevant observations change.
A failing readiness probe does not make the Pod unscheduled or uninitialized,
it just changes the conditions that describe whether the Pod should currently receive traffic.

## Updating inside a controller

If you are building your own controller, make sure you update all the relevant conditions correctly, not just a single one.

A useful real-world example is the [cert-manager operator](https://github.com/openshift/cert-manager-operator/blob/4cae75589c8ca349c3c7253d24ff182d5903aeee/pkg/controller/common/reconcile_result.go#L30-L31).
In one reconciliation result, it sets both `Degraded=True` and `Ready=False`.
Those are two separate observations: the operator is not ready, and it is degraded.

## Takeaway

Conditions are not phases, they are named observations about different aspects of a resource.

Read the `Type` first, then interpret the `Status`, `Reason`, and `Message` in that context.

If you are writing a controller, update all conditions affected by a reconciliation result.
Each condition should describe one specific aspect of the resource's current observed state.
