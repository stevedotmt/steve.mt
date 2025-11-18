---
title: "System Performance - Chapter 2"
date: 2021-10-04T00:00:00Z
draft: false
summary: "Answers Systems Performance chapter 2 exercises, clarifying metrics like IOPS, utilization, and troubleshooting methodologies."
tags: [
  "linux",
  "system-performance-book"
]
---

When reading the [Systems Performance: Enterprise and the Cloud, 2nd Edition
(2020)](https://www.brendangregg.com/systems-performance-2nd-edition-book.html)
by Brendan Gregg, I saw that each chapter has an `Exercises` section with a set
of questions. This series of blogs will be my attempt to answer them and also
give additional links I've read whilst reading the chapter. The answers might
not be correct, not detailed but this is to help me explain what I learned to
make sure I understand it.

You can follow [system-performance-book]({{< ref "/tags/system-performance-book" >}}) for this series.

## Exercises

### Answer the following questions about key performance terminology:

#### What are IOPS?

Input/Output operations per second to measure the rate of the data transfer,
for example, the disk IOPS refers to the number of reads and writes per second.
The higher the number the better performance.

#### What is utilization?

Defines how busy a resource was performing work for a specific set of time, for
example to serve a request 20% of the CPU is utilized.

#### What is saturation?

When a resource is utilized and there is no free resources left and can no
longer use the resource, which leads to queueing.

#### What is latency?

The time taken to finish a specific request, for example, the time taken to
respond to a specific request.

#### What is micro-benchmarking?

Create an artificial workload to test the throughput for a small part of the
application or system, for example, using `iperf` to test the TCP throughput of
the machine.

### Choose five methodologies to use for your (or a hypothetical) environment. Select the order in which they can be conducted, and explain the reason for choosing each.

- **Problem Statement:** First define the problem by asking questions like when the
  problem showed up if there were any changes to the environment.
- **Request, Errors, Duration (RED):** After you have the problem statement, then
  you need to understand how the user is perceiving this problem, are they
  seeing a bunch of errors or slow requests. Like this, we can understand the
  severity of the problem.
- **Utilization, Saturation, Error (USE):** See the underlying machine of the
  service and see you can find the bottleneck from a hardware level.
- **Scientific Method:** Now that we know the severity of the defined problem and
  how the service is behaving you can start creating hypothesis and test that
  the hypothesis with the next step which is drill-down.
- **Drill-down analysis:** When we have a hypothesis, start drill-down analysis of
  that problem statement until you reach a dead-end or disprove your
  hypothesis.

### Summarize problems when using average latency as a sole performance metric. Can these problems be solved by including the 99th percentile?

Averages hide details and outliers, time is also important, for example, if you
take the CPU utilization 5-minute-average and it's 50% it's possible that the
CPU spiked at 100% for 2 seconds and it doesn't show in the average.

99th percentile can solve this since it measures the variance from the average
and shows the minimum and maximum variance.

## Addtional Notes

- [The RED Method: How To Instrument Your Services](https://www.youtube.com/watch?v=zk77VS98Em8)
- [Methodologies](https://www.brendangregg.com/methodology.html)
