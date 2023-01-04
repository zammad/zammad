// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue, FormValues } from '@shared/components/Form/types'
import type {
  ObjectAttributeValueInput,
  ObjectManagerFrontendAttribute,
} from '@shared/graphql/types'
import { convertToGraphQLId, isGraphQLId } from '@shared/graphql/utils'
import { camelize, toClassName } from '@shared/utils/formatter'

export const useObjectAttributeFormData = (
  objectAttributes: Map<string, ObjectManagerFrontendAttribute>,
  formData: FormValues,
  keyMap: Record<string, string | false> = {},
) => {
  const internalObjectAttributeValues: Record<string, FormFieldValue> = {}
  const additionalObjectAttributeValues: ObjectAttributeValueInput[] = []

  const fullRelationId = (relation: string, value: number | string) => {
    return convertToGraphQLId(toClassName(relation), value)
  }

  const ensureRelationId = (
    attribute: ObjectManagerFrontendAttribute,
    value: FormFieldValue,
  ) => {
    const { relation } = attribute.dataOption
    const isInternalID =
      typeof value === 'number' ||
      (typeof value === 'string' && !isGraphQLId(value))

    if (relation && isInternalID) {
      return fullRelationId(relation, value)
    }
    return value
  }

  Object.keys(formData).forEach((fieldName) => {
    const objectAttribute = objectAttributes.get(fieldName)
    const value = formData[fieldName]

    if (!objectAttribute || value === undefined) return

    if (objectAttribute.isInternal) {
      const name = keyMap[fieldName] ?? camelize(fieldName)
      if (name === false) return
      internalObjectAttributeValues[name] = ensureRelationId(
        objectAttribute,
        value,
      )
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
