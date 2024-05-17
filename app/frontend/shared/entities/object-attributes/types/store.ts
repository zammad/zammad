// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'

import type { ComputedRef, Ref } from 'vue'

export interface ObjectAttributesObject {
  attributes: ComputedRef<ObjectManagerFrontendAttribute[]>
  screens: ComputedRef<Record<string, string[]>>
  attributesLookup: ComputedRef<Map<string, ObjectManagerFrontendAttribute>>
  formFieldAttributesLookup: ComputedRef<Map<string, FormSchemaField>>
  loading: Ref<boolean>
}
