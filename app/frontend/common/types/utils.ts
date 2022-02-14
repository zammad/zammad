// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export type ReactiveFunction<TParam> = () => TParam

export type ImportGlobEagerDefault<T> = Record<string, T>

export type ImportGlobEagerOutput<T> = Record<string, ImportGlobEagerDefault<T>>
