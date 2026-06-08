# How to Calculate the Required Database Connection Count

This document intends to aid with calculating a proper PostgreSQL `max_connections` value for Zammad.

## Introduction

The _technical maximum connection count_ is the number of physical Zammad/Rails processes (not threads inside them)
multiplied by the size of the connection pool (default 50).

The _actually used connection count_ is lower and depends on a number of other factors which is hard to
predict / calculate. Therefore we'll provide only the technical maximum value.

## Formula

```ruby
max_connections = number_of_zammad_processes * connection_pool_size

number_of_zammad_processes =
  number_of_railsserver_processes +
  number_of_background_worker_processes +
  number_of_other_processes +
  1 # for websocket

number_of_railsserver_processes = number_of_railsserver_pods * (WEB_CONCURRENCY || 1)

number_of_background_worker_processes =
  1 + # main process
  ZAMMAD_MANAGE_SESSIONS_JOBS_WORKERS +
  ZAMMAD_PROCESS_SCHEDULED_JOBS_WORKERS +
  ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS +
  ZAMMAD_PROCESS_DELAYED_AI_JOBS_WORKERS +
  ZAMMAD_PROCESS_DELAYED_JOBS_WORKERS

number_of_other_processes =
  count_of_concurrent_cronjobs_or_service_pods + # automatic processes starting Zammad, such as reindex cronjobs
  count_of_concurrent_manual_rails_commands      # manual `rails r / rails c` calls.
```
