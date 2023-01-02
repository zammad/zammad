// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumObjectManagerObjects,
  ObjectManagerFrontendAttribute,
} from '@shared/graphql/types'
import type { FormSchemaField } from '@shared/components/Form/types'
import { useObjectAttributesStore } from '../stores/objectAttributes'
import { transformResolvedFieldForScreen } from '../form/getFieldFromAttribute'

export const useObjectAttributeFormFields = (skippedFields: string[] = []) => {
  const { getObjectAttributesForObject } = useObjectAttributesStore()

  const getFormFieldSchema = (
    name: string,
    object: EnumObjectManagerObjects,
    screen?: string,
  ) => {
    const objectAttributesObject = getObjectAttributesForObject(object)

    const resolvedField = (
      objectAttributesObject.formFieldAttributesLookup as unknown as Map<
        string,
        FormSchemaField
      >
    ).get(name)

    if (!screen) return resolvedField

    // We need to transform the resolved the field for the current screen (e.g. for the required information).
    const screenConfig = (
      objectAttributesObject.attributesLookup as unknown as Map<
        string,
        ObjectManagerFrontendAttribute
      >
    ).get(name)?.screens[screen]

    if (resolvedField && screenConfig) {
      transformResolvedFieldForScreen(screenConfig, resolvedField)
    }

    return resolvedField
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
      const formField = getFormFieldSchema(attributeName, object, screen)
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
