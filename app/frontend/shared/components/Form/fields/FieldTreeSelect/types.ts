// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { SelectOption } from '../FieldSelect'

export type TreeSelectOption = SelectOption & {
  children?: TreeSelectOption[]
}

export type FlatSelectOption = SelectOption & {
  hasChildren: boolean
  parents: (string | number)[]
}
