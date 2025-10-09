---
title: "System Performance - Chapter 3"
date: 2021-10-13
draft: false
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

### Answer the following questions about OS terminology:

#### What is the difference between a process, a thread, and a task?

- **Process:** An environment for executing a program, which is in user mode and
  has access to the kernel via system calls.
- **Thread:** An executable amount of work that is going to be scheduled on the
  CPU. The kernel has multiple threads whilst a process can have 1 thread or
  more.
- **Task:** A runnable entity which refers to a process when it's single
  threaded, or a single thread from a multithread process or a kernel task.

#### What is a mode switch and a context switch?

- **Mode switch:** Switch between kernel mode and user mode.
- **Context switch:** The switch between running one thread to another.

#### What is the difference between paging and process swapping?

- **Paging:** Moves a small unit of memory between main and secondary storage.
  The unit of memory is called a `page`. A page is a chunk of memory that is
  managed by the kernel and process. The typical size of a page is 4Kbytes and
  2 Mbytes which depends on the processer.
- **Process swapping:** This is the original Unix method where it moves the
  entire process between main memory (RAM) and secondary storage (disks). This
  had a massive performance hit. In Linux, `swapping` refers to `paging` since
  it doesn't support the original Unix copy method.

#### What is the difference between I/O-bound and CPU-bound workloads?

- **I/O-bound:** A workload that does a lot of I/O operations, and needs to
  wait for the I/O to finish before it goes back on the CPU.
- **CPU-bound:** A workload that is computationally intenstive that needs a lot
  of time on the CPU to finish its work rather than wait for network
  calls or disk writes.

### Answer the following conceptual questions:

#### Describe the role of the kernel.

Manages the system, hardware devices, memory, and CPU scheduling. It has direct
access to the hardware.

#### Describe the role of system calls.

The user mode process calls a system call that the kernel will perform. This
can be creating a process or any other privileged operation.

#### Describe the role of VFS and its location in the I/O stack.

The virtual file system is an abstraction and interface that the kernel and
user interacts with. This allows multiple file systems to coexist on the same
machine and it's transparent to the user.

The VFS is between the System Calls and the File system.

### Answer the following deeper questions:

#### List the reasons why a thread would leave the current CPU.

- **Blocked Thread:** When a thread is blocked waiting for I/O to finish, it
  will be moved back to the queue so that the CPU can run a task/thread.
- **Preemption:** When a high-priority user-level thread interrupts the kernel
  and executes it instead of the current running thread.
- **Locks:** A thread waiting for a lock, it is removed off the CPU.
- **Context Switch:** High demand on the CPU will try to give enough CPU to
  each thread.
- **Interrupts:** Some event occurred and needs processing. It saves the
  current thread state and then runs an interrupt service routine.

#### Describe the advantages of virtual memory and demand paging.

- **Virtual Memory:** An abstraction over the main memory. This provides a
  dedicated view of the main memory to processes and the kernel. It allows
  processes and the kernel to operate on their own private address space
  without worrying about contention. Since virtual memory can be considered
  infinite, it supports the oversubscription of main memory and uses secondary
  memory such as disks.
- **Deman paging:** Defers the mapping of the physical memory to virtual
  memory. This is to help avoid performance and memory costs for pages that
  might not be used.

## Addtional Notes

- [The Tragedy of systemd](https://www.youtube.com/watch?v=o_AIw9bGogo)
- [Off-CPU Analysis](https://www.brendangregg.com/offcpuanalysis.html#:~:text=Threads%20can%20leave%20CPU%20for,for%20CPU%20resources%2C%20and%20interrupts.)
- [Using SCHED_DEADLINE](https://www.youtube.com/watch?v=TDR-rgWopgM)
