---
title: "Go Context Logger"
date: 2025-10-14
draft: false
summary: "Go's log/slog package can automatically print keys from the passed context using `slog.InfoContext`."
tags: ["Go", "Logging"]
---

In Go 1.21, a new logging package was introduced [log/slog](https://tip.golang.org/doc/go1.21#slog)
to provide structured logs built into Go.

What most people are familiar with is the `slog.Info` and other log levels, such as `slog.Error`, like the example below:

```go
package main

import (
 "log/slog"
 "os"
)

func main() {
 logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

 logger.Info("hello")
 logger.Error("something bad happened")
}
```

This will end up printing:

```text
{"time":"2025-10-14T06:49:41.234716+02:00","level":"INFO","msg":"hello"}
{"time":"2025-10-14T06:49:41.234923+02:00","level":"ERROR","msg":"something bad happened"}
```

## Context Logging

If you look at the package documentation, there is also [InfoContext](https://pkg.go.dev/log/slog#Logger.InfoContext) that takes a context and can print items from the context.

To set this up successfully, you first have to create a [handler](https://pkg.go.dev/log/slog#Handler).

```go
// Use a custom type to store inside the context to prevent key collision.
type ctxKey string

const requestID ctxKey = "request_id"

// ContextHandler implements the Handler interface
type ContextHandler struct {
 handler slog.Handler
}

// Enabled calls the underlying handler's Enabled method.
func (h *ContextHandler) Enabled(ctx context.Context, lvl slog.Level) bool {
 return h.handler.Enabled(ctx, lvl)
}

// Handle checks the context for the values and adds them to the log attributes.
func (h *ContextHandler) Handle(ctx context.Context, r slog.Record) error {
 if requestID, ok := ctx.Value(requestID).(string); ok {
  r.AddAttrs(slog.String("request_id", requestID))
 }

 return h.handler.Handle(ctx, r)
}

// WithAttrs updates the log attributes with attributes from the underlying handler.
func (h *ContextHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
 return &ContextHandler{handler: h.handler.WithAttrs(attrs)}
}

// WithGroup updates the group with the group from the underlying handler.
func (h *ContextHandler) WithGroup(name string) slog.Handler {
 return &ContextHandler{handler: h.handler.WithGroup(name)}
}

// NewContextHandler creates a new ContextHandler wrapping the passed handler.
// It preserves any attributes added to the passed handler.
func NewContextHandler(h slog.Handler) *ContextHandler {
 return &ContextHandler{handler: h}
}
```

After creating the handler, it's a matter of initializing it with a handler from the `log/slog` package like the [`JSONHandler`](https://pkg.go.dev/log/slog#JSONHandler).

```go
func main() {
 handler := NewContextHandler(slog.NewJSONHandler(os.Stdout, nil))
 logger := slog.New(handler)

 logger = logger.With("app", "slog-examples")

 ctx := context.WithValue(context.Background(), requestID, "req-abc-123")

 // Now the request_id is automatically added from context!
 logger.InfoContext(ctx, "user logged in")
 logger.InfoContext(ctx, "fetching user data")
 logger.InfoContext(ctx, "request completed")
}
```

If we run the program, we'll see the logs with `request_id` without having to add it to every log message or use [`With`](https://pkg.go.dev/log/slog#Logger.With).

```text
$ go run main.go
{"time":"2025-10-16T06:49:00.29838+02:00","level":"INFO","msg":"user logged in","app":"slog-examples","request_id":"req-abc-123"}
{"time":"2025-10-16T06:49:00.298526+02:00","level":"INFO","msg":"fetching user data","app":"slog-examples","request_id":"req-abc-123"}
{"time":"2025-10-16T06:49:00.298528+02:00","level":"INFO","msg":"request completed","app":"slog-examples","request_id":"req-abc-123"}
```

A more real-world scenario would be to have an HTTP middleware that adds the request ID and has the HTTP handlers log some information, which prints it from the context.

```go
func main() {
 // Initalize logger
 handler := NewContextHandler(slog.NewJSONHandler(os.Stdout, nil))
 logger := slog.New(handler)
 logger = logger.With("app", "slog-examples")

 // Create a simple handler that logs the request
 mux := http.NewServeMux()
 mux.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
  logger.InfoContext(r.Context(), "logger in hello")
  fmt.Fprint(w, "hello")
 }))

 //middleware to inject request ID in the context
 requestIDMiddlware := func(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
   ctx := context.WithValue(r.Context(), requestID, uuid.New().String())
   next.ServeHTTP(w, r.WithContext(ctx))
  })
 }

 // start HTTP server
 if err := http.ListenAndServe(":8080", requestIDMiddlware(mux)); err != nil {
  logger.Error("failed to start HTTP server", "err", err)
 }
}
```

Running the program above and then sending a curl request, we can see that the request ID gets automatically logged when we use `logger.InfoContext(r.Context(), "logger in hello")

```text
$ curl http://127.0.0.1:8080
{"time":"2025-10-23T06:46:39.409817+02:00","level":"INFO","msg":"logger in hello","app":"slog-examples","request_id":"a81f9559-aaaa-48ea-ae7a-785e406a8e8b"}
```

## Further Reading

- [Logging in Go with Slog: The Ultimate Guide](https://betterstack.com/community/guides/logging/logging-in-go/#using-the-context-package-with-slog)
- [log/slog](https://pkg.go.dev/log/slog)
