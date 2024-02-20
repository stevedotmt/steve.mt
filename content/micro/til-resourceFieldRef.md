---
title: "Kubernetes Downward API"
date: 2024-02-20
draft: false
tags: ["TIL", "Kubernetes"]
---

Sometimes you want to expose information about the constraints the container is running without duplicating values
or have the application reach out to the Kubernetes API.

The [Downward API](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/) helps with this problem where you can inject pod information to the container via env variables.

For example, let's imagine we want to set the `GOMAXPROCS` depending on the CPU limit:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-app
      image: golang
      resources:
        requests:
          memory: "32Mi"
          cpu: "125m"
        limits:
          memory: "64Mi"
          cpu: "250m"
      env:
        - name: GOMAXPROCS
          valueFrom:
            resourceFieldRef:
              containerName: my-app
              resource: limits.cpu`
```

The example above would set `GOMAXPROCS` to `1` because `resourceFieldRef` gets the `limits.cpu` for that container.
