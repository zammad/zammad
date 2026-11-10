// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import type { FieldResolver } from '../form/resolver/FieldResolver.ts'
import type { EntityAttribute } from './store.ts'

export interface ScreenConfig {
  required?: boolean
  null?: boolean
  [index: string]: unknown
}

export type FieldResolverClass = new (
  object: EnumObjectManagerObjects,
  attribute: EntityAttribute,
) => FieldResolver

export interface FieldResolverModule {
  type: string
  resolver: FieldResolverClass
}

interface EntityAttributeSelectOption {
  name: string
  value: string
}

export type EntityAttributeSelectOptions =
  | Array<EntityAttributeSelectOption>
  | Record<string, string>

export type EntityAttributeTreeSelectOption = EntityAttributeSelectOption & {
  children?: EntityAttributeSelectOption[]
}

export type FilterSchemaField = {
  $formkit: string
  name: string
  label: string
  [key: string]: unknown
}
