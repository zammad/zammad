// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export interface TaskbarTabDetailDataLoader {}

export type TaskbarTabDetailDataLoaderComposable =
  () => TaskbarTabDetailDataLoader

export interface TaskbarTabContext {
  formValues?: FormValues
  formIsDirty?: boolean
  formIsSettled?: boolean

  // Add generic properties to the context (e.g. overview information in ticket detail view context).
  [index: string]: unknown
}
