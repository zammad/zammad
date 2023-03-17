// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormSchemaField,
  FormFieldValue,
} from '@shared/components/Form/types'
import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import type { ScreenConfig } from '../types/resolver'
import getFieldResolver from './resolver/getFieldResolver'

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

  // Special handling for the clearable prop in the select/treeselect fields.
  if (
    'nulloption' in screen &&
    resolvedField.props &&
    'clearable' in resolvedField.props
  ) {
    resolvedField.props.clearable = screen.nulloption
  }
}

const getFieldFromAttribute = (
  attribute: ObjectManagerFrontendAttribute,
): FormSchemaField => {
  const fieldResolver = getFieldResolver(attribute)

  return fieldResolver.fieldAttributes()
}

export default getFieldFromAttribute
