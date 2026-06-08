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

type OperatorName = string

export type OperatorFilterProps = Record<OperatorName, Record<string, unknown>>

export interface FilterAttribute {
  name: string
  label: string
  // Optional `%s` placeholders for `label`, interpolated (and themselves
  // translated) at label output — e.g. the accounted-time unit from config.
  labelPlaceholder?: string[]
  operators: string[]
  operatorFilterProps?: OperatorFilterProps
  // Two independent relation signals (set by the resolver):
  // - `relation`: target entity name (e.g. 'User', 'Organization'). Marks the
  //   value as a foreign-key ID — downstream code coerces such values to
  //   integers when restoring from URL state.
  // - `autocompleteFilterType`: FormKit field type used to *pick* the value
  //   (e.g. 'customer', 'agent', 'tags'). Decides the UI strategy — when set,
  //   options are fetched per keystroke instead of pre-resolved by the form
  //   updater.
  // The two can co-exist (customer/agent/organization carry both); tags only
  // sets autocompleteFilterType, since tag values are strings, not IDs.
  relation?: string
  autocompleteFilterType?: string
}

export interface ObjectAttributesObject {
  attributes: ComputedRef<ObjectAttribute[]>
  screens: ComputedRef<Record<string, string[]>>
  attributesLookup: ComputedRef<Map<string, ObjectAttribute>>
  filterAttributes: ComputedRef<FilterAttribute[]>
  formFieldAttributesLookup: ComputedRef<Map<string, FormSchemaField>>
  loading: Ref<boolean>
}
