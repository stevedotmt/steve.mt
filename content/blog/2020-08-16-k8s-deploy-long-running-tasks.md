---
title: "Deploy long-running tasks on Kubernetes"
date: 2020-08-16
draft: false
tags: [
  "TIL",
  "Kubernetes",
]
---

Whilst reading this [extremly detailed and well written
article](https://learnk8s.io/graceful-shutdown#terminating-long-running-tasks)
about how graceful shutdowns work on Kubernetes. It touched on the
subject of long running tasks.

When we update the deployment inside of Kubernetes, it will start by
deleting a pod with the old version of the image, and starts a new pod
with the new version.

The pod can be attached to a service it might be the case that the pod
is removed from the service **before** the process/pod has finished. The
process is still running and outputting useful information whilst it
removed from the service.

This is not a big problem for a process that is just handling incoming
web requests but for processes like [GitLab
Runner](https://gitlab.com/gitlab-org/gitlab-runner) where the process
can run for a few hours before we can shut it down it might be
problematic because we can't access the pod over the network since it
has been removed from the service. We can't monitor it, we can debug it
we can reach it at all.

It's not ideal to have a process running that you can't monitor. The
article mentioned above suggests to create a brand new deployment
instead of updating the version of the existing deployment. You can have
both of the versions running at the same time and start draining the old
version. If we create a new deployment Kubernetes wouldn't start
deleting the old pods so they won't be removed from the services and we
can still monitor them. These are called [rainbow
deployments](https://brandon.dimcheff.com/2018/02/rainbow-deploys-with-kubernetes/).
