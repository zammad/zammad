// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormData } from '@shared/components/Form'
import type { FormFieldValue } from '@shared/components/Form/types'
import type {
  ObjectAttributeValueInput,
  ObjectManagerFrontendAttribute,
} from '@shared/graphql/types'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { camelize, toClassName } from '@shared/utils/formatter'

export const useObjectAttributeFormData = (
  objectAttributes: Map<string, ObjectManagerFrontendAttribute>,
  formData: FormData,
) => {
  const internalObjectAttributeValues: Record<string, FormFieldValue> = {}
  const additionalObjectAttributeValues: ObjectAttributeValueInput[] = []

  const fullRelationID = (relation: string, value: number | string) => {
    return convertToGraphQLId(toClassName(relation), value)
  }

  Object.keys(formData).forEach((fieldName) => {
    const objectAttribute = objectAttributes.get(fieldName)
    const value = formData[fieldName]

    if (!objectAttribute || value === undefined) return

    if (objectAttribute.isInternal) {
      internalObjectAttributeValues[camelize(objectAttribute.name)] =
        objectAttribute.dataOption.relation &&
        (typeof value === 'number' || typeof value === 'string')
          ? fullRelationID(objectAttribute.dataOption.relation, value)
          : value
    } else {
      additionalObjectAttributeValues.push({
        name: objectAttribute.name,
        value,
      })
    }
  })

  return {
    internalObjectAttributeValues,
    additionalObjectAttributeValues,
  }
}
