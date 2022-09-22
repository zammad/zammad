// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '@shared/components/Form/types'
import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import getFieldResolver from './resolver/getFieldResolver'

const getFieldFromAttribute = (
  attribute: ObjectManagerFrontendAttribute,
): FormSchemaField => {
  const fieldResolver = getFieldResolver(attribute)

  return fieldResolver.fieldAttributes()
}

export default getFieldFromAttribute
