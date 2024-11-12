// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type {
  EnumObjectManagerObjects,
  ObjectManagerFrontendAttribute,
} from '#shared/graphql/types.ts'

import type { JsonValue } from 'type-fest'
import type { ComputedRef, Ref } from 'vue'

export interface ObjectAttribute extends ObjectManagerFrontendAttribute {
  isStatic?: boolean
  dataOption?: {
    translate?: boolean
    permission?: string | string[]
    relation?: string
    [index: string]: JsonValue | undefined
  }
}

export interface EntityStaticObjectAttributes {
  name: EnumObjectManagerObjects
  attributes: ObjectAttribute[]
}

export interface ObjectAttributesObject {
  attributes: ComputedRef<ObjectAttribute[]>
  screens: ComputedRef<Record<string, string[]>>
  attributesLookup: ComputedRef<Map<string, ObjectManagerFrontendAttribute>>
  formFieldAttributesLookup: ComputedRef<Map<string, FormSchemaField>>
  loading: Ref<boolean>
}
