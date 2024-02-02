// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { TreeSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'

export interface GroupAccess {
  access: string
  label: string
}

export type GroupPermissionsContext = FormFieldContext<{
  groups: TreeSelectOption[]
  groupAccesses: GroupAccess[]
}>

export interface GroupAccessLookup {
  [access: string]: boolean
}

export interface GroupPermissionReactive {
  groups: SelectValue
  groupAccess: GroupAccessLookup
}
