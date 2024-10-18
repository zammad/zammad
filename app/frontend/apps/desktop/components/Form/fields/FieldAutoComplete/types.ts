// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  AutoCompleteOption,
  AutoCompleteProps as DefaultAutoCompleteProps,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'

import type { DropdownOptionsAction } from '#desktop/components/CommonSelect/types.ts'

import type { Dictionary } from 'ts-essentials'

export interface AutoCompleteProps extends DefaultAutoCompleteProps {
  actions?: DropdownOptionsAction[]
  stripFilter?: (filter: string) => string
}

export type AutoCompleteOptionValueDictionary = Dictionary<AutoCompleteOption>

export type SelectOptionFunction = (
  option: AutoCompleteOption,
  focus?: boolean,
) => void

export type ClearFilterInputFunction = () => void
