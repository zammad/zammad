// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@common/form/core/initializeFieldDefinition'
import { FormFieldsTypeDefinition, FormFieldType } from '@common/types/form'
import {
  color as inputColorDefinition,
  date as inputDateDefinition,
  datetimeLocal as inputDatetimeLocalDefinition,
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
  date: inputDateDefinition,
  datetimeLocal: inputDatetimeLocalDefinition,
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
