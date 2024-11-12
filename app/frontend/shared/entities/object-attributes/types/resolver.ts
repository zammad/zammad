// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import type { ObjectAttribute } from './store.ts'
import type FieldResolver from '../form/resolver/FieldResolver.ts'

export interface ScreenConfig {
  required?: boolean
  null?: boolean
  [index: string]: unknown
}

export type FieldResolverClass = new (
  object: EnumObjectManagerObjects,
  attribute: ObjectAttribute,
) => FieldResolver

export interface FieldResolverModule {
  type: string
  resolver: FieldResolverClass
}

interface ObjectAttributeSelectOption {
  name: string
  value: string
}

export type ObjectAttributeSelectOptions =
  | Array<ObjectAttributeSelectOption>
  | Record<string, string>

export type ObjectAttributeTreeSelectOption = ObjectAttributeSelectOption & {
  children?: ObjectAttributeSelectOption[]
}
