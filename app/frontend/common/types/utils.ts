// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

export type ReactiveFunction<TParam> = () => TParam

export type ImportGlobEagerResult = Record<
  string,
  {
    [key: string]: unknown
  }
>
