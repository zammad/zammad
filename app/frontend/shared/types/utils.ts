// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export type ReactiveFunction<TParam> = () => TParam

export type ImportGlobEagerDefault<T> = Record<string, T>

export type ImportGlobEagerOutput<T> = Record<string, ImportGlobEagerDefault<T>>

type ObjectKeys<T, K extends string | number> = T extends Record<
  string,
  unknown
>
  ? // eslint-disable-next-line no-use-before-define
    K | `${K}.${NestedKeyOf<T>}`
  : K

export type NestedKeyOf<T> = {
  [K in keyof T & (string | number)]: NonNullable<T[K]> extends Array<unknown>
    ? ObjectKeys<NonNullable<NonNullable<T[K]>[number]>, K>
    : ObjectKeys<NonNullable<T[K]>, K>
}[keyof T & (string | number)]

type TakeInternal<T, K extends string | number> = K extends keyof T
  ? NonNullable<T[K]>
  : K extends `${infer L}.${infer M}`
  ? L extends keyof T
    ? NonNullable<T[L]> extends Array<unknown>
      ? TakeInternal<NonNullable<NonNullable<T[L]>[number]>, M>
      : TakeInternal<NonNullable<T[L]>, M>
    : never
  : never

export type ConfidentTake<T, K extends NestedKeyOf<T>> = TakeInternal<T, K>

export type EventHandlers<E> = {
  // eslint-disable-next-line @typescript-eslint/ban-types
  [K in keyof E]?: E[K] extends Function ? E[K] : (payload: E[K]) => void
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ObjectLike = Record<string, any>
