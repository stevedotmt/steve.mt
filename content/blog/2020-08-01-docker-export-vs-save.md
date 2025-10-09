---
title: "Docker Export vs Docker Save"
date: 2020-08-01T21:38:21+02:00
draft: false
tags: [
  "TIL",
  "Docker",
]
---

## [Docker Export](https://docs.docker.com/engine/reference/commandline/export/)

The export takes a snapshot of the container file system and export it's
as a tarball, all container layers are flattened. Any metadata about the
entry point is lost, such as `ENTRYPOINT` and `CMD`.

You can run `docker import` to create a Docker image from that tarball.

## [Docker Save](https://docs.docker.com/engine/reference/commandline/save/)

Creates a tarball on the **image** and not the container so all the
layers are saved, and any metadata around it such as `ENTRYPOINT`.

You can run `docker load` to create a Docker image from that tarball.

## When to use what

If you only care about the files that are inside of the running
container you should use `docker export` since it only takes the
snapshot of the container. If you care about everything about the image,
you should use `docker save`.

## Reference

- Learned when debugging problems in https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/2058#note_388341301
- https://github.com/moby/moby/issues/8334#issuecomment-57471427
