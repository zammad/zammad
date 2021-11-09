export type ReactiveFunction<TParam> = () => TParam

export type ImportGlobEagerResult = Record<
  string,
  {
    [key: string]: unknown
  }
>
