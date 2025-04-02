// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormFieldValue,
  FormSubmitData,
  FormValues,
} from '#shared/components/Form/types.ts'
import type { ObjectAttributeValueInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId, isGraphQLId } from '#shared/graphql/utils.ts'
import { camelize, toClassName } from '#shared/utils/formatter.ts'

import type { ObjectAttribute } from '../types/store.ts'
import type { Primitive } from 'type-fest'

export const useObjectAttributeFormData = <T = FormValues>(
  objectAttributes: Map<string, ObjectAttribute>,
  values: FormSubmitData<T>,
) => {
  const internalObjectAttributeValues: Record<string, FormFieldValue> = {}
  const additionalObjectAttributeValues: ObjectAttributeValueInput[] = []

  const fullRelationId = (relation: string, value: number | string) => {
    return convertToGraphQLId(toClassName(relation), value)
  }

  const ensureRelationId = (
    attribute: ObjectAttribute,
    value: FormFieldValue,
  ) => {
    const { relation } = attribute.dataOption || {}
    const isInternalID =
      typeof value === 'number' ||
      (typeof value === 'string' && !isGraphQLId(value))

    if (relation && isInternalID) {
      return fullRelationId(relation, value)
    }
    return value
  }

  Object.keys(values).forEach((fieldName) => {
    const objectAttribute = objectAttributes.get(fieldName)
    const value = values[fieldName] as FormFieldValue

    if (!objectAttribute || value === undefined) return

    if (objectAttribute.isInternal) {
      const name = camelize(fieldName)

      let newValue: FormFieldValue
      if (Array.isArray(value)) {
        newValue = value.map((elem) => {
          return ensureRelationId(objectAttribute, elem) as Primitive
        })
      }
      // When the attribute has guess support and is a string count it as an guess (=unknown value).
      else if (objectAttribute.dataOption?.guess && typeof value === 'string') {
        newValue = value
      } else {
        newValue = ensureRelationId(objectAttribute, value)
      }

      internalObjectAttributeValues[name] = newValue
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
