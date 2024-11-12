// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormSchemaField,
  FormFieldValue,
} from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import getFieldResolver from './resolver/getFieldResolver.ts'

import type { ScreenConfig } from '../types/resolver.ts'
import type { ObjectAttribute } from '../types/store.ts'

export const transformResolvedFieldForScreen = (
  screen: ScreenConfig,
  resolvedField: FormSchemaField,
) => {
  resolvedField.required = screen.required || ('null' in screen && !screen.null)

  if ('default' in screen) {
    resolvedField.value = screen.default as FormFieldValue
  }

  if ('filter' in screen && resolvedField.relation) {
    resolvedField.relation.filterIds = screen.filter as number[]
  }

  // Special handling for the clearable prop in the select/treeselect/autocomplete fields.
  if (
    'nulloption' in screen &&
    resolvedField.props &&
    'clearable' in resolvedField.props
  ) {
    resolvedField.props.clearable = screen.nulloption
  }
}

const getFieldFromAttribute = (
  object: EnumObjectManagerObjects,
  attribute: ObjectAttribute,
): FormSchemaField => {
  const fieldResolver = getFieldResolver(object, attribute)

  return fieldResolver.fieldAttributes()
}

export default getFieldFromAttribute
