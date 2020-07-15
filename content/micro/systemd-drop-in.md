---
title: "Systemd Drop In"
date: 2020-07-14T07:04:32+02:00
draft: false
tags: [
  "TIL",
  "Linux",
  "systemd",
]
---

At work, I was debugging an
[issues](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/265820)
where it was failing to update the systemd configuration to the new
installation path.

By default, systemd service definitions go under
`/etc/systemd/system/name.service`. There are cases where you as an
administrator have no control over the service generated. So how do you
override a service configuration without overriding the original service
or the service definition from scratch?

Systemd has a functionality called [`drop-in
units`](https://coreos.com/os/docs/latest/using-systemd-drop-in-units.html)
where you can write parts of the service definition and it will override
it.

For example in the GitLab Runner scenario we had:

```ini
# cat /etc/systemd/system/gitlab-runner.service
[Unit]
Description=GitLab Runner
After=syslog.target network.target
ConditionFileIsExecutable=/usr/bin/gitlab-runner

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/bin/gitlab-runner "run" "--working-directory" "/home/gitlab-runner" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner" "--syslog" "--user" "gitlab-runner"

Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
```

```ini
# cat /etc/systemd/system/gitlab-runner.service.d/exec_start.conf
[Service]
ExecStart=/usr/lib/gitlab-runner/gitlab-runner "--log-format" "json" "run" "--working-directory" "/home/gitlab-runner" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner" "--user" "gitlab-runner"
```

In this case
`/etc/systemd/system/gitlab-runner.service.d/exec_start.conf` is
overrideing the `[Service]` section.

If you want to see if the service you are debugging has any drop-in
units you can run `systemctl show name.service` and it will show all the
configuration loaded.
