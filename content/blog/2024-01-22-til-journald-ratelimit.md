---
title: "journald RateLimitBurst"
date: 2024-01-22
draft: false
summary: "Introduces journald RateLimitBurst/Interval, why throttling noisy logs matters, and how to scope limits per unit."
tags: ["TIL", "Linux"]
---

Whilst reading [An overview of Cloudflare's logging pipeline](https://blog.cloudflare.com/an-overview-of-cloudflares-logging-pipeline),
it mentioned that it uses Journald for managing logs on the Linux VM, it mentioned both `RateLimitBurst` and `RateLimitInterval`.

- `RateLimitBurst`: Number of messages processed in a burst.
- `RateLimitInterval`: The window during which the rate limit is applied.

For example, the configuration below says that we can log 5 messages every 10 seconds, any more will be dropped.

```ini
RateLimitBurst=5
RateLimitInterval=10s
```

Why would we want to rate limit logs:

- Disk I/O pressure.
- Some chatty systems fill up disk space.
- Prevent backpressure on upstream services by not sending a flood of logs.

These settings are for the whole system (journald process) if you want to limit a specific systemd unit you can use [`LogRateLimitBurst` & `LogRateLimitInterval`](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#LogRateLimitIntervalSec=) to limit that specific unit.
