// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import { FormFieldsTypeDefinition, FormFieldType } from '@shared/types/form'
import {
  color as inputColorDefinition,
  email as inputEmailDefinition,
  number as inputCNumberDefinition,
  search as inputSearchDefinition,
  tel as inputTelDefinition,
  text as inputTextDefinition,
  time as inputTimeDefinition,
} from '@formkit/inputs'

const inputFieldDefinitionList: FormFieldsTypeDefinition = {
  text: inputTextDefinition,
  color: inputColorDefinition,
  email: inputEmailDefinition,
  number: inputCNumberDefinition,
  search: inputSearchDefinition,
  tel: inputTelDefinition,
  time: inputTimeDefinition,
}

const inputFields: FormFieldType[] = []

Object.keys(inputFieldDefinitionList).forEach((inputType) => {
  initializeFieldDefinition(inputFieldDefinitionList[inputType])

  inputFields.push({
    fieldType: inputType,
    definition: inputFieldDefinitionList[inputType],
  })
})

export default inputFields
