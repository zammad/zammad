// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export type PermissionsChildOption = {
  value: string
  label: string
  labelPlaceholder?: string[]
  description?: string
}

export type PermissionsParentOption = {
  value: string
  label: string
  description?: string
  disabled?: boolean
  children?: PermissionsChildOption[]
}

export type PermissionsProps = FormFieldContext<{
  options: PermissionsParentOption[]
}>
