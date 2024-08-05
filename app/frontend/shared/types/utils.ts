// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Scalars } from '#shared/graphql/types.ts'

export type ReactiveFunction<TParam> = () => TParam

export type ImportGlobEagerDefault<T> = Record<string, T>

export type ImportGlobEagerOutput<T> = Record<string, ImportGlobEagerDefault<T>>

type ObjectKeys<T, K extends string | number> =
  T extends Record<string, unknown>
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
  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  [K in keyof E]?: E[K] extends Function ? E[K] : (payload: E[K]) => void
}

export type PartialRequired<T, K extends keyof T> = Omit<T, K> &
  Required<Pick<T, K>>

export type MaybeRecord<K> = {
  [P in keyof K]?: Maybe<K[P]>
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ObjectLike = Record<string, any>

export interface ObjectWithId {
  id: Scalars['ID']['output']
}

export interface ObjectWithUid {
  uid: Scalars['String']['output']
}

export declare type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object | null | undefined
    ? DeepPartial<T[K]> | undefined | null
    : T[K] | null
}

export declare type DeepRequired<T> = {
  [K in keyof T]-?: DeepRequired<NonNullable<T[K]>>
}
