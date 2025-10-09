---
title: "import \"context\""
date: 2021-04-03
draft: false
tags: [
  "stdlib",
  "Go",
]
---

What can you do when you `import "context"` inside of your go
project? Looking at the [source
code](https://github.com/golang/go/blob/go1.16.3/src/context/context.go) it's a
fairly small package and provides a [small
api](https://pkg.go.dev/context#pkg-index). We also see this package
imported almost everywhere and the standard library also uses it.

`context` provides the following functionality:

- Cancellation
- Context scope values
- Deadlines/Timeouts

There are two things that you need to keep in mind when you are using
`context`:

1. The `context.Context` should be passed around your application.
1. Every time you want to add functionality to your context such as
cancellation you always wrap another context, usually called the "parent
context".

I always like to think of the context as a tree-like below, and if one
of the parent context is canceled it's propagated to its children, but
not to its parents.

![context tree](/import-context/tree.png)

## Cancellation

What do we mean by cancellation? It's having control over a
unit of work and being able to cancel it at will, if you decide it's no
longer needed, for example an expensive HTTP request or a background task
that is running in a different goroutine.

The best part of cancellation is that if you have multiple contexts
derived from the parent context and the parent context is canceled it
will propagate the cancellation to its child contexts as shown in the
diagram above.

### HTTP Requests

One of the common use cases is when you are sending an HTTP request, the
`net/http` allows you to specify a context which you can cancel at any
time. Let's look at an example.

```go
func main() {
	ctx, cancel := context.WithCancel(context.Background())

	// Send both requests
	go sendRequest(ctx, cancel, "http://google.com")
	go sendRequest(ctx, cancel, "http://duckduckgo.com")

	time.Sleep(5 *time.Second)
}

// sendRequest will send a GET request to the specified URL and call the cancel
// function as soon as it's done.
func sendRequest(ctx context.Context, cancel context.CancelFunc, url string)  {
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		log.Fatalf("Failed to set up request for %q: %v", url, err)
	}

	log.Printf("Sending request to %q", url)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
	    log.Fatalf("Failed to send request for %q: %v", url, err)
	}
	defer resp.Body.Close()

	log.Printf("Received %d from %s", resp.StatusCode, url)
}
```
*Source code can be found at
https://gitlab.com/context-talk/cancellation/-/tree/master/http*

If we run the following code we see the following:

```shell
2021/04/03 12:54:54 Sending request to "http://duckduckgo.com"
2021/04/03 12:54:54 Sending request to "http://google.com"
2021/04/03 12:54:54 Received 200 from http://google.com
2021/04/03 12:54:54 Failed to send request for "http://duckduckgo.com": Get "https://duckduckgo.com/": context canceled
```

OK, let's break it down to understand what is going on.

```go
ctx, cancel := context.WithCancel(context.Background())
```

Here we are creating a new
[context.WithCancel](https://pkg.go.dev/context#WithCancel) that is
taking the parent context and creating a new context, just
like the tree shown above. However, this function returns two things, the
child context but also a
[`CancelFunc`](https://pkg.go.dev/context#CancelFunc) function.

```go
// Send both requests
go sendRequest(ctx, cancel, "http://google.com")
go sendRequest(ctx, cancel, "http://duckduckgo.com")
```

The next step is to create 2 goroutines that will send a request to the desired URL,
passing in the context and the `CancelFunc` so that the request we send
can use the context, and also cancel the context when it's done.

```go
defer cancel()
```

Before we send the actual request we are deferring the cancellation of the
context, so as soon as the function returns it cancels the context. This
means as soon we get a response we are going to cancel all of the other
requests.

```go
req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
```

At this point, you might be wondering how the request is actually
canceled. This is why we need to pass in the context from the main
function to
[`sendRequest`](https://gitlab.com/context-talk/cancellation/-/blob/7ede7b3d8400eaba2c99fc682ee87a27ec255ca9/http/main.go#L22)
so that we can [add it to the
request](https://gitlab.com/context-talk/cancellation/-/blob/7ede7b3d8400eaba2c99fc682ee87a27ec255ca9/http/main.go#L25).
Go is then smart enough to detect that the context is canceled and
will cancel that request.

### Concurrent code

Another way to use context is to handle the life cycle of concurrent
code, you might be creating multiple goroutines. Imagine that you have
a worker in a separate goroutine that is computing something expensive
and you want to have control over the worker. This is where we
can use [`context.Done()`](https://pkg.go.dev/context#Context) inside of
that worker to check if the context is canceled and stop whatever that
worker is doing. Let's look at an
example.

```go
func main() {
	ctx, cancel := context.WithCancel(context.Background())

	go expensiveWorker(ctx)

	time.Sleep(5 * time.Second)
	cancel()
	time.Sleep(time.Second)
}

func expensiveWorker(ctx context.Context) {
	for {
		select {
		case <-time.Tick(time.Second):
			log.Print("tick")
		case <-ctx.Done():
			log.Fatalf("done")
		}
	}
}
```
*Source code can be found at
https://gitlab.com/context-talk/cancellation/-/tree/master/concurrent*

If we run the program we see the following:

```shell
2021/04/03 13:38:49 tick
2021/04/03 13:38:50 tick
2021/04/03 13:38:51 tick
2021/04/03 13:38:52 tick
2021/04/03 13:38:53 done
exit status 1
```

Going line by line let's understand how this snippet is working.

```go
ctx, cancel := context.WithCancel(context.Background())
```

We are creating a new
[context.WithCancel](https://pkg.go.dev/context#WithCancel), where the parent context is
`context.Background` since we don't have any parent context.

```go
go expensiveWorker(ctx)
```

We then pass the context to the worker that is in a separate goroutine,
this will allow the worker to check if the context is canceled or not.

```go
select {
case <-time.Tick(time.Second):
	log.Print("tick")
case <-ctx.Done():
	log.Fatalf("done")
}
```

A `select` statement is used to wait until one of the channels is
returned. In this case `ctx.Done`. `Done()` will only return when the
`cancel` function from the [main function is
called](https://gitlab.com/context-talk/cancellation/-/blob/7ede7b3d8400eaba2c99fc682ee87a27ec255ca9/concurrent/main.go#L15).
This means that as soon as `Done()` returns we are getting the signal
that we should stop the work we are doing and exit.

### Command line applications

It's fairly common to write command-line applications in Go given it's
creates single statically linked binary that can run on the most popular
environments.

The application might be sending HTTP requests, computing a number, or
some other expensive operation. The user might want to cancel the
execution by pressing `CTRL+C` because they changed their mind. The
program should try and halt as soon as possible and gracefully. Context
can help achieve this, let's look at an example.

```go
func main() {
	ctx, cancel := context.WithCancel(context.Background())

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		cancel()
	}()

	for {
		select {
		case <-time.Tick(time.Second):
			log.Print("tick")
		case <-ctx.Done():
			log.Fatalf("cancelled")
		}
	}
}
```
*Source code can be found at
https://gitlab.com/context-talk/cancellation/-/tree/master/cli*

If we run the application and press `CTRL+C` we will see the following
in the logs:

```shell
2021/04/03 14:02:40 tick
2021/04/03 14:02:41 tick
^C2021/04/03 14:02:42 cancelled
exit status 1
```

Going through the code we see the following:

```go
ctx, cancel := context.WithCancel(context.Background())
```

This is similar to the other ones, where we create a new context passing
the parent context.

```go
sigs := make(chan os.Signal, 1)
signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
go func() {
	<-sigs
	cancel()
}()
```

Here we are listening for [signals](https://pkg.go.dev/os/signal#Notify)
which for the case of `CTRL+C` is `SIGINT`. The [`sigs`
channel](https://gitlab.com/context-talk/cancellation/-/blob/7ede7b3d8400eaba2c99fc682ee87a27ec255ca9/cli/main.go#L18) will
return when the Go application receives the signal.

```go
select {
case <-time.Tick(time.Second):
	log.Print("tick")
case <-ctx.Done():
	log.Fatalf("cancelled")
}
```

We are again waiting for `context.Done()` to return since we [call
`cancel`](https://gitlab.com/context-talk/cancellation/-/blob/7ede7b3d8400eaba2c99fc682ee87a27ec255ca9/cli/main.go#L19)
on `SIGINT`.

This allows us to create the context in the `main` function and then
if we pass this context around our application we can call `cancel` for
our application to stop whatever it's doing gracefully.

Another way to achieve the code above is by calling
[NotifyContext](https://pkg.go.dev/os/signal#NotifyContext).

## Timeouts & Deadlines

Timeouts and Deadlines are very similar to cancellation but instead of
manually calling [CancelFunc](https://pkg.go.dev/context#CancelFunc) it
will be automatically called for you at the specified time.

The only difference between a Timeout and a Deadline is calling
[`context.WithTimeout`](https://pkg.go.dev/context#WithTimeout) where you
specify a duration and
[`context.WithDeadline`](https://pkg.go.dev/context#WithDeadline) where
you specify the time. They are so similar if you look at the
source code for
[`WithTimeout`](https://go.googlesource.com/go/+/go1.16.2/src/context/context.go#502)
you see that it's just calling
[`WithDeadline`](https://go.googlesource.com/go/+/go1.16.2/src/context/context.go#503).

Both functions also return a
[CancelFunc](https://pkg.go.dev/context#CancelFunc) which we can call at
any time if we want to cancel it before the deadline. It's best practice
to always call the `CancelFunc` inside of a defer to prevent any leaking
of resources if the function returns before the timer expires.

### Timeout

Let's look at an example for timeouts, imagine that we are creating a
worker and we only are willing to wait up for the worker to finish it's
works for 1 second.

```go
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	nums := make(chan int)
	go func() {
		nums <- expensiveWorker()
	}()

	select {
	case num := <-nums:
		fmt.Printf("Got number! %d", num)
	case <-ctx.Done():
		fmt.Print("Timed out!")
	}
}
```
*Source code can be found at
https://gitlab.com/context-talk/timeout/-/tree/master*

```go
ctx, cancel := context.WithTimeout(context.Background(), time.Second)
defer cancel()
```

We create a new context with a timeout where we pass in the parent
context and specify a timeout of 1 second. We also call cancel on a
`defer` as a best practice to prevent any resources from leaking.

```go
select {
case num := <-nums:
	fmt.Printf("Got number! %d", num)
case <-ctx.Done():
	fmt.Print("Timed out!")
}
```

By now this should be familiar we are calling `context.Done` to check if
the context has been canceled, in this case with the timeout function.

### Deadline

The example below is the same as the timeout, but instead of specifying
the duration we specify a specific timestamp when we want to cancel the
work of the expensive worker.

```go
func main() {
	deadline := time.Now().Add(time.Second)
	ctx, cancel := context.WithDeadline(context.Background(), deadline)
	defer cancel()

	nums := make(chan int)
	go func() {
		nums <- expensiveWorker()
	}()

	select {
	case num := <-nums:
		fmt.Printf("Got number! %d", num)
	case <-ctx.Done():
		fmt.Print(ctx.Err())
	}
}
```
*Source code can be found at
https://gitlab.com/context-talk/deadline/-/tree/master*

## Logging

We can also use
[`context.WithValue`](https://pkg.go.dev/context#WithValue) to pass a
value with a specific key that is globally available for the rest of the
application that has access to that context. The data type can be
anything, it can be a string or a struct. One of the most common use cases is
for request-scoped variables, such as a request ID that can be logged as
part of a structured logger so each log line has a request ID
attached to it.

We have to be careful what values we put in the context and shouldn't
relay on it for any critical business logic such as authorization,
since these are global variables with no static type
checking so everything can writing anything to it.

Let's take a look at how we can use context to log a requestID for each
request.

```go
type correlationIDType int

const (
	requestIDKey correlationIDType = iota
)

func main() {
	// Set up logger
	// ...

	api := api{
		logger: *logger,
	}
	http.Handle("/", reqIDMiddleware(api.rootHandler()))
	log.Fatal(http.ListenAndServe(":8000", nil))
}

// ctxLogger will read values from the specified context and add them to the
// logger as keys.
func ctxLogger(ctx context.Context, logger zap.Logger) zap.Logger {
	if ctx == nil {
		return logger
	}

	reqID, ok := ctx.Value(requestIDKey).(string)
	if ok {
		logger = *logger.With(zap.String("reqID", reqID))
	}

	return logger
}

type api struct {
	logger zap.Logger
}

func (a *api) rootHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logger := ctxLogger(r.Context(), a.logger)
		logger.Info("handling /")
		w.Write([]byte("Hello world"))
	})
}

// reqIDMiddleware is the middleware that will attach a unique request ID to
// each request via the context.
func reqIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqID, _ := uuid.NewRandom()
		reqCtx := context.WithValue(r.Context(), requestIDKey, reqID.String())
		r = r.WithContext(reqCtx)

		next.ServeHTTP(w, r)
	})
}
```
*Source code can be found at
https://gitlab.com/context-talk/logging/-/blob/master*

If we run the application and send some HTTP requests we can see the
following logs, where each log has its requestID, which can helpful
if we have an endpoint that logs multiple things.

```json
{"level":"info","ts":1617457804.547617,"caller":"logging/main.go:56","msg":"handling /","reqID":"fe5e42e7-4685-416f-979d-9be8e9673834"}
{"level":"info","ts":1617457806.909491,"caller":"logging/main.go:56","msg":"handling /","reqID":"b19a7bad-8729-46df-b6d4-f1f0114dcc8d"}
{"level":"info","ts":1617457807.876866,"caller":"logging/main.go:56","msg":"handling /","reqID":"b91b58f2-7ba2-4376-80de-1b66e265e06e"}
{"level":"info","ts":1617457808.7434099,"caller":"logging/main.go:56","msg":"handling /","reqID":"2ee52858-43d4-4c18-b4e3-584d59b83280"}
```

There is quite a lot of code so let's dive in.

```go
type correlationIDType int

const (
	requestIDKey correlationIDType = iota
)
```

This might seem strange at first, but this gives us a small safety net.
Since we are dealing with global values we need a way to avoid
key collisions. Creating a new type that is scoped to the package will give
us back the type safety that we need so if we just request the key with
`requidIDKey` and always get the expected value.

```go
func reqIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqID, _ := uuid.NewRandom()
		reqCtx := context.WithValue(r.Context(), requestIDKey, reqID.String())
		r = r.WithContext(reqCtx)

		next.ServeHTTP(w, r)
	})
}
```

This is a normal HTTP middleware where it takes the context from the
[http.Request](https://pkg.go.dev/net/http#Request.Context) and create a
new [`context.WithValue`](https://pkg.go.dev/context#WithValue) with the
`requestIDKey` type that we created earlier as a key and a random UUID for that
request as a value. The request context is then updated with
[request.WithContext](https://gitlab.com/context-talk/logging/-/blob/17a9f04839230fbb4da9fbe329d33cc4c10ecaae/main.go#L67).

```go
func ctxLogger(ctx context.Context, logger zap.Logger) zap.Logger {
	if ctx == nil {
		return logger
	}

	reqID, ok := ctx.Value(requestIDKey).(string)
	if ok {
		logger = *logger.With(zap.String("reqID", reqID))
	}

	return logger
}
```

Then we have `ctxLogger` where it will take a logger and return a new
one with the `reqID` key added to it. The value of the `reqID` is taken
from the context by calling
[context.Value](https://gitlab.com/context-talk/logging/-/blob/17a9f04839230fbb4da9fbe329d33cc4c10ecaae/main.go#L41).
`ctxLogger` is called in
[handlers](https://gitlab.com/context-talk/logging/-/blob/17a9f04839230fbb4da9fbe329d33cc4c10ecaae/main.go#L55)
so that it can access the context and logger scoped to it.

## Distributed Tracing

Another cool example where context can be used is for [Distributed
Tracing](https://opentelemetry.lightstep.com/tracing/). For example,
looking at the opentelmetry implementation you can add baggage using Go
context as shown in https://pkg.go.dev/go.opentelemetry.io/otel@v0.18.0/baggage

## Best practices

We covered a lot for such a small package and there is a lot of to keep
in mind when you are using the context package, here are a few rules
that I keep in mind:

1. Always call the `CancelFunc` when it's returned to be safe nothing is
leaking resources.
1. Only use `context.WithValue` to enrich logging and there should be no
business logic depending on values from the context.
1. You should always pass the context as the first parameter of a
function instead of embedding it in a struct, you can read more about
this in the [Go blog](https://blog.golang.org/context-and-structs).
1. As much as possible make sure you have the context available in your
function so that you can keep wrapping the parent context which might
help with cancellation.
1. The `main` function should create the root context and passed around
in the application.

## Other resources to learn more

- [justforfunc #9: The context
  package](https://www.youtube.com/watch?v=LSzR0VEraWw)
- [justforfunc #10: Implementing the context
  package](https://www.youtube.com/watch?v=8M90t0KvEDY)
- [Go reference](https://pkg.go.dev/context)
- [Go Concurrency Patterns: Context](https://blog.golang.org/context)
- [Context and structs](https://blog.golang.org/context-and-structs)
