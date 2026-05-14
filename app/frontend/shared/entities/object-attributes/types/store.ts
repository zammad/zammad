// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type {
  EnumObjectManagerObjects,
  ObjectManagerFrontendAttribute,
  PolicyDefault,
} from '#shared/graphql/types.ts'

import type { JsonValue } from 'type-fest'
import type { ComputedRef, Ref } from 'vue'

export interface ObjectAttribute extends ObjectManagerFrontendAttribute {
  id?: string
  isStatic?: boolean
  dataOption?: {
    display_config?: string
    translate?: boolean
    permission?: string | string[]
    relation?: string
    belongs_to?: string
    item_class?: string
    [index: string]: JsonValue | undefined
  }
}

export interface EntityStaticObjectAttributes {
  name: EnumObjectManagerObjects
  attributes: ObjectAttribute[]
}

export interface EntityPolicyBasedObjectAttributeScreenMapper<TPolicy = PolicyDefault> {
  name: EnumObjectManagerObjects
  mappings: {
    [key: string]: (policy: TPolicy) => string
  }
}

export interface FilterAttribute {
  name: string
  label: string
  operators: string[]
}

export interface ObjectAttributesObject {
  attributes: ComputedRef<ObjectAttribute[]>
  screens: ComputedRef<Record<string, string[]>>
  attributesLookup: ComputedRef<Map<string, ObjectAttribute>>
  filterAttributes: ComputedRef<FilterAttribute[]>
  formFieldAttributesLookup: ComputedRef<Map<string, FormSchemaField>>
  loading: Ref<boolean>
}
