# How to Log

## 1. Choosing a level

Pick the level based on who needs to react, not how noisy the event feels:

| Level     | When to use it                                                                             | Reaches production?             |
| --------- | ------------------------------------------------------------------------------------------ | ------------------------------- |
| `debug`   | Development/troubleshooting detail; too verbose for normal operation                       | No — production runs at `:info` |
| `info`    | A normal, expected event happened                                                          | Yes                             |
| `warn`    | Something unexpected happened but was handled/recovered automatically; no one needs to act | Yes                             |
| `error`   | An operation failed, work was lost, or a human should investigate                          | Yes                             |
| `fatal`   | A process or subsystem had to abort                                                        | Yes                             |
| `unknown` | Always-emitted catch-all; avoid, prefer a DB audit trail instead                           | Yes                             |

The most common mistake is defaulting to `error` for anything that isn't `info`. Client-caused
failures (bad request, validation failure, 404/422) are `warn` or `info`, not `error` — reserve
`error` for cases where the operation genuinely failed and someone should look at it. Zammad has
no external error tracker, so `Rails.logger.error` is the only alerting signal available; treating
it as a generic "not quite info" bucket destroys that signal.

## 2. Where to log

Logging and then raising isn't inherently wrong. A lower layer often has context — an object id, a
loop counter, a hostname — that the exception itself doesn't carry, and code in `lib/` can't
assume every caller will log the exception it re-raises. Keep the log call when it adds
information the exception message doesn't already have, or when you can't rely on something
upstream to log it.

Drop the log call when its message is redundant with what the exception already says and you know
it reaches a boundary that logs exceptions (a controller's `rescue_from`, a background job's
failure handler). Logging the same string twice for one failure only adds noise:

```ruby
# redundant — the same message is logged twice for one failure
Rails.logger.error "Request failed! (code: #{response.code})"
raise "Request failed! (code: #{response.code})"

# better — raise once, let the boundary that handles it log the exception
raise "Request failed! (code: #{response.code})"
```

When you do log at the point where an error is handled, pass the exception object itself rather
than just its message, so the formatter can attach a cleaned backtrace:

```ruby
rescue => e
  Rails.logger.error(e)
end
```

## 3. Use the logger, not stdout

Always use `Rails.logger` (or bare `logger` inside a class that includes the `RailsLogger` mixin,
see `lib/mixin/rails_logger.rb`). Never use `puts`/`print` — they bypass the log level, the
formatter, and the log destination entirely.

## 4. Defer expensive messages with the block form

If building the log message does non-trivial work (interpolating large objects, serializing,
querying), use the block form so the cost is only paid when the level is actually enabled:

```ruby
logger.debug { "Payload: #{payload.inspect}" }
```

This matters in particular for `debug`, which is filtered out at runtime in production
(the block is only evaluated when the level is enabled).

## 5. Never log secrets

Rails' `filter_parameters` only scrubs the _automatic_ request log — it does not apply to manual
`logger.*` calls. Never interpolate tokens, passwords, private keys, or other credentials into a
log message. If a value could plausibly be a credential, redact it explicitly before logging:

```ruby
# bad
Rails.logger.error("OAuth refresh failed for #{credentials.to_json}")

# good
Rails.logger.error("OAuth refresh failed for client_id=#{credentials.client_id}")
```

## 6. Testing

Avoid asserting on exact log message strings — they are an implementation detail and turn brittle
whenever wording changes. Where a test needs to assert that something was logged, prefer matching
on level and a stable partial pattern rather than mocking `Rails.logger` to accept anything, which
can pass without testing that logging actually happened as expected.
