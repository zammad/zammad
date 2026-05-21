// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { ObjectSelectOption } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import type { FilterSelectorEntityOverride } from '#desktop/components/Search/types.ts'

import type { FormKitInputs } from '@formkit/inputs'

// A single value-side input for an operator. Each compound operator declares
// one entry per input it needs from the user; `name` identifies the input
// within the operator's `filterFields` list.
export type FilterField = Partial<FormSchemaField> & Pick<FormSchemaField, 'type'>

export type Operator = {
  name: string
  label: string
  // Value-side inputs the operator wants rendered for a given attribute.
  // One entry for single-input operators (e.g. `matches`); multiple
  // entries describe a compound operator with separate inputs the user
  // fills in together (e.g. a "between" with `from` / `to`). The function
  // form lets the operator vary the rendered input by attribute (e.g. `is`
  // picks autocomplete vs multiselect based on the attribute's relation).
  //
  // Return `null` to declare that the operator does not apply to this
  // attribute (e.g. autocomplete-style relations until that path is
  // validated). Distinct from `[]`, which would mean "applies but takes
  // no value input" (future valueless operators like `is empty`).
  filterFields: (attribute: FilterAttribute) => FilterField[] | null
}

// Per-row state. Storage is flat: the row's primary input lives in `value`,
// and any additional operator-specific inputs (e.g. `range`) are stored as
// top-level keys alongside, keyed by the input's `name`.
export type FilterSelectorEntry = {
  name: string
  operator: string
  value: unknown
  [extra: string]: unknown
}

// Render-relevant slice of a `FilterSelectorEntry`: the parts that determine
// what gets rendered for a row (attribute resolved against the available
// attributes + the chosen operator), value deliberately excluded so that
// keystrokes don't invalidate structural computeds.
export type FilterSelectorRow = {
  name: string
  attribute: FilterAttribute
  operator: string
}

export type FilterSelectorProps = {
  filterAttributes: FilterAttribute[]
  filterAttributesOverride?: FilterSelectorEntityOverride[]
  // Per-attribute option lists supplied by the form updater. Used for relation
  // sub-fields (e.g. group/state/priority) whose options aren't carried by the
  // static attribute config. Keyed by the dotted attribute name from the
  // selector (e.g. `ticket.group_id`).
  filterAttributeOptions?: Record<string, ObjectSelectOption[]>
  addLabel: string
  id: string
  min?: number
  max?: number
}

declare module '@formkit/inputs' {
  // oxlint-disable eslint(no-unused-vars)
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    filterRepeater: {
      type: 'filterRepeater'
      filterAttributes: FilterAttribute[]
      addLabel: string
      value?: FilterSelectorEntry[]
      min?: number
      max?: number
    }
  }
  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    filterRepeater: FormKitBaseSlots<Props>
  }
}
