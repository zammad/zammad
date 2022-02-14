// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormFieldTypeImportModules,
  FormFieldsTypeDefinition,
} from '@common/types/form'
import type {
  ImportGlobEagerDefault,
  ImportGlobEagerOutput,
} from '@common/types/utils'
import type { FormKitPlugin } from '@formkit/core'
import {
  createLibraryPlugin as formKitCreateLibraryPlugin,
  form as formFieldDefinition,
} from '@formkit/inputs'
import { isArray } from 'lodash-es'

const fieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.globEager('../../components/form/field/**/*.ts')

// The main field type "form" from FormKit is a fixed type.
const fields: FormFieldsTypeDefinition = {
  form: formFieldDefinition,
}

const registerFieldFromModules = (
  fieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules>,
) => {
  Object.values(fieldModules).forEach(
    (module: ImportGlobEagerDefault<FormFieldTypeImportModules>) => {
      const formFieldTypes = module.default

      // A object with multiple fields will be returned in the case that one field nidzke handles multiple fields.
      // E.g. the FormKit default input fields (text, color, ...).
      if (isArray(formFieldTypes)) {
        formFieldTypes.forEach((formFieldType) => {
          fields[formFieldType.fieldType] = formFieldType.definition
        })
      } else {
        fields[formFieldTypes.fieldType] = formFieldTypes.definition
      }
    },
  )
}

const createFieldPlugin = (
  appSpecificFieldModues?: ImportGlobEagerOutput<FormFieldTypeImportModules>,
): FormKitPlugin => {
  // Register first the common fields and then the app specific fields so
  // that the app specific fields can override the common ones.
  registerFieldFromModules(fieldModules)

  if (appSpecificFieldModues) {
    registerFieldFromModules(appSpecificFieldModues)
  }

  return formKitCreateLibraryPlugin(fields)
}

export default createFieldPlugin
