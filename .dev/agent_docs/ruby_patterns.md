# Ruby Patterns

Conventions for any Ruby class or module in `app/` and `lib/`. Rules for a specific
kind of class (services, GraphQL, migrations) live in their own docs and build on
these.

## Instance state

Assign instance variables directly, read them only through readers.

- **Assign** with `@name =` — in `initialize`, or where the value changes
  (`@usage = event['usage']`, `@block_error = e`).
- **Read** through an `attr_reader`, never as `@name` in a condition, a call or a
  return value. A reader fails loudly on a typo (`NameError`) where a
  misspelled `@name` is silently `nil`, and the class can later compute the value
  without touching its callers.
- **Memoized values** are read through the method that memoizes them:
  `def config = @config ||= load_config` is the reader, so no `attr_reader` next
  to it.
- **Flags** get a predicate method instead of a reader: `complete?` returning
  `@complete`. The predicate is the flag's only reader — no `attr_reader` next to it.
- Declare the readers at the top of the class, after its constants and `include`s,
  not in the private section — that is how the codebase does it (about 300 readers
  at the top, a handful private).

```ruby
class Example
  attr_reader :url, :options, :response

  def initialize(url, options)
    @url     = url
    @options = options
    @done    = false
  end

  def perform
    @response = UserAgent.get(url, {}, options)
    @done     = true

    response
  end

  def done?
    @done
  end
end
```

### Reader, writer, accessor

| Macro | Generates | Use for |
| --- | --- | --- |
| `attr_reader :name` | `name` | Reading state — the default |
| `attr_writer :name` | `name=` | Rarely: a value someone outside the class sets |
| `attr_accessor :name` | `name` and `name=` | Public, configurable fields set from outside (`provider.options = …`) |

Do not add an `attr_accessor` just to write internal state: inside the class
a writer has to be called as `self.name = …` (a bare `name = …` is a local
variable), and the codebase assigns internal state with `@name =`.

## Acronyms in constant names

An acronym in a file or constant name (`frames_sse.rb` → `FramesSSE`) goes into
`config/initializers/inflections.rb`. Zeitwerk falls back to it, so
`config/application.rb` needs no entry. A Zeitwerk-only entry there is invisible to
`Mixin::RequiredSubPaths` and other code that camelizes file names with
ActiveSupport.

## Text from outside

Bytes from a socket, a file or another system are binary until checked. Before
any string method — `split`, `strip` or a regex raise `ArgumentError` on an invalid
byte sequence — decide which kind of text it is:

- **Protocol data** (stream frames, headers, a format's own syntax):
  `force_encoding('UTF-8')`, then `valid_encoding?`. Invalid input is an error of
  that input — raise the class's own error, not a crash.
- **Content Zammad keeps** (a mail body, an attachment, imported ticket text):
  repair it with `TextEncoding.utf8_encode(value, from: charset, fallback:
  :read_as_sanitized_binary)` instead of rejecting it.

Decode a stream per complete frame or line, never per network read, so that a
character split across two reads stays whole.

## Timeouts around a caller's block

Do not run a caller's block inside `Timeout.timeout`: it raises wherever the block
happens to be, for example halfway through writing a record.

- Bound I/O with its own timeouts. With a total deadline over many reads, set each
  read timeout to the time left.
- Where a phase without the block still needs `Timeout.timeout` (connecting,
  reading headers), defer it around the block with
  `Thread.handle_interrupt(Timeout::ExitException => :never)`. Deferring does not
  cancel it: it still fires when the section ends, also after a stream that
  succeeded. Give it the total deadline and keep the reads within the time left.
- A deferred interrupt fires when that section ends and replaces any exception in
  flight. Record the block's own exception and re-raise it whenever one was
  recorded — not only when it is the exception that arrived.

```ruby
def each_event
  block_error = nil
  deadline    = monotonic_now + total_timeout

  Timeout.timeout(total_timeout) do
    connect
    read_headers

    Thread.handle_interrupt(Timeout::ExitException => :never) do
      # sets each read timeout to the time left until the deadline
      read_events(deadline) do |event|
        yield event
      rescue => e
        block_error = e
        raise
      end
    end
  end
rescue Timeout::Error
  raise block_error if block_error

  raise
end
```
