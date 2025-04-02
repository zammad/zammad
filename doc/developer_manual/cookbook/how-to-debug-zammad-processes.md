# How to Debug Zammad Processes

Sometimes it can be helpful to understand the internal state of threads running in a Zammad process. This can be
achieved by sending a `SIGWINCH` signal to any Zammad service (railsserver, websocket or background worker) process,
which will cause the process to print the state of its threads to STDOUT.

Beware by default this is only available in a production environment. It can be forced by setting the environment
variable ENFORCE_THREAD_STATUS_HANDLER to "true".

- Find out process ID of Zammad webserver

```screen
ps
PID TTY           TIME CMD
…
77926 ttys001    0:03.02 puma 6.5.0 (tcp://localhost:3000) [zammad]
…
```

- Send the SIGWINCH signal to that process or any of its forked workers. This doesn't actually "kill" the process.

```screen
kill -SIGWINCH 77926
```

- Observe the log output in the process' STDOUT, e.g. via journalctl

```screen
PID: 77926 Thread: TID-jqk AR Pool Reaper
  /path/to/gems/ruby-3.2.4/gems/activerecord-7.2.2.1/lib/active_record/connection_adapters/abstract/connection_pool/reaper.rb:49:in `sleep'
  /path/to/gems/ruby-3.2.4/gems/activerecord-7.2.2.1/lib/active_record/connection_adapters/abstract/connection_pool/reaper.rb:49:in `block in spawn_thread'
PID: 77926 Thread: TID-jr4 listen-wait_thread
  <internal:thread_sync>:18:in `pop'
  /path/to/rubies/ruby-3.2.4/lib/ruby/3.2.0/forwardable.rb:240:in `pop'
  /path/to/gems/ruby-3.2.4/gems/listen-3.9.0/lib/listen/event/processor.rb:89:in `_wait_until_events'
  /path/to/gems/ruby-3.2.4/gems/listen-3.9.0/lib/listen/event/processor.rb:21:in `block in loop_for'
…
```
