// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { FormSchemaField } from '@shared/components/Form/types'
import { useObjectAttributesStore } from '../stores/objectAttributes'

export const useObjectAttributeFormFields = (skippedFields: string[] = []) => {
  const { getObjectAttributesForObject } = useObjectAttributesStore()

  const getFormFieldSchema = (
    name: string,
    object: EnumObjectManagerObjects,
  ) => {
    return (
      getObjectAttributesForObject(object)
        .formFieldAttributesLookup as unknown as Map<string, FormSchemaField>
    ).get(name)
  }

  const getFormFieldsFromScreen = (
    screen: string,
    object: EnumObjectManagerObjects,
  ) => {
    const screens = getObjectAttributesForObject(object)
      .screens as unknown as Record<string, string[]>

    if (!screens[screen]) return []

    const formFields: FormSchemaField[] = []

    screens[screen].forEach((attributeName) => {
      if (skippedFields.includes(attributeName)) {
        return
      }
      const formField = getFormFieldSchema(attributeName, object)
      if (!formField) {
        return
      }
      formFields.push(formField)
    })
    return formFields
  }

  return {
    getFormFieldSchema,
    getFormFieldsFromScreen,
  }
}
