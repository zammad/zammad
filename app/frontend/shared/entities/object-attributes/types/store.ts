// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, Ref } from 'vue'
import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import type { FormSchemaField } from '@shared/components/Form/types'

export interface ObjectAttributesObject {
  attributes: ComputedRef<ObjectManagerFrontendAttribute[]>
  screens: ComputedRef<Record<string, string[]>>
  attributesLookup: ComputedRef<Map<string, ObjectManagerFrontendAttribute>>
  formFieldAttributesLookup: ComputedRef<Map<string, FormSchemaField>>
  loading: Ref<boolean>
}
