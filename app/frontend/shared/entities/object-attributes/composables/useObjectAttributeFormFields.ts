// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects, PolicyDefault } from '#shared/graphql/types.ts'

import { transformResolvedFieldForScreen } from '../form/getFieldFromAttribute.ts'
import {
  policyBasedObjectAttributeScreenMappersByEntity,
  useObjectAttributesStore,
} from '../stores/objectAttributes.ts'

import type { ObjectAttribute } from '../types/store.ts'

export const useObjectAttributeFormFields = <TPolicy = PolicyDefault>(
  skippedFields: string[] = [],
  policy?: TPolicy,
) => {
  const { getObjectAttributesForObject } = useObjectAttributesStore()

  const getScreensForObject = (object: EnumObjectManagerObjects) => {
    return getObjectAttributesForObject(object).screens as unknown as Record<string, string[]>
  }

  const resolveScreenName = (screen: string, object: EnumObjectManagerObjects) => {
    if (!policy) return screen

    const mappers = policyBasedObjectAttributeScreenMappersByEntity[object]
    if (!mappers || !mappers[screen]) return screen

    const mappedScreen = mappers[screen](policy as unknown as PolicyDefault)
    const screens = getScreensForObject(object)

    // Fallback to the original screen if the mapped screen doesn't exist
    return screens[mappedScreen] ? mappedScreen : screen
  }

  const getFormFieldSchema = (name: string, object: EnumObjectManagerObjects, screen?: string) => {
    const objectAttributesObject = getObjectAttributesForObject(object)

    const resolvedField = (
      objectAttributesObject.formFieldAttributesLookup as unknown as Map<string, FormSchemaField>
    ).get(name)

    if (!screen) return resolvedField

    const resolvedScreen = resolveScreenName(screen, object)
    const screens = getScreensForObject(object)

    if (!screens[resolvedScreen] || !screens[resolvedScreen].includes(name)) return

    // We need to transform the resolved the field for the current screen (e.g. for the required information).
    const screenConfig = (
      objectAttributesObject.attributesLookup as unknown as Map<string, ObjectAttribute>
    ).get(name)?.screens[resolvedScreen]

    if (resolvedField && screenConfig) {
      transformResolvedFieldForScreen(screenConfig, resolvedField)
    }

    return resolvedField
  }

  const getFormFieldsFromScreen = (screen: string, object: EnumObjectManagerObjects) => {
    const resolvedScreen = resolveScreenName(screen, object)
    const screens = getScreensForObject(object)

    if (!screens[resolvedScreen]) return []

    const formFields: FormSchemaField[] = []

    screens[resolvedScreen].forEach((attributeName) => {
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
