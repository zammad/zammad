// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  color as inputColorDefinition,
  email as inputEmailDefinition,
  number as inputCNumberDefinition,
  tel as inputTelDefinition,
  text as inputTextDefinition,
  time as inputTimeDefinition,
  textInput as formKitTextInput,
  url as inputUrlDefinition,
} from '@formkit/inputs'
import { cloneDeep } from 'lodash-es'

import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import addLink from '#shared/form/features/addLink.ts'
import addSubmitEvent from '#shared/form/features/addSubmitEvent.ts'
import defaultEmptyValueString from '#shared/form/features/defaultEmptyValueString.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import { setPopulatedOnWebkitAutofill } from '#shared/form/features/setPopulatedOnWebkitAutofill.ts'
import { textInput } from '#shared/form/sections/textInput.ts'
import type { FormFieldsTypeDefinition, FormFieldType } from '#shared/types/form.ts'

// FormKit exports all these types as aliases of one shared `text` definition
//   object, and initializeFieldDefinition mutates in place — without a clone per
//   type, the last initialized type would define the schema for all of them.
const inputFieldDefinitionList: FormFieldsTypeDefinition = {
  text: cloneDeep(inputTextDefinition),
  color: cloneDeep(inputColorDefinition),
  email: cloneDeep(inputEmailDefinition),
  number: cloneDeep(inputCNumberDefinition),
  tel: cloneDeep(inputTelDefinition),
  time: cloneDeep(inputTimeDefinition),
  url: cloneDeep(inputUrlDefinition),
}

const inputFields: FormFieldType[] = []

// Native color and time pickers ignore the readonly attribute, so these two
//   keep FormKit's stock section and stay really disabled.
const stockSectionTypes = new Set(['color', 'time'])

Object.keys(inputFieldDefinitionList).forEach((inputType) => {
  const definition = inputFieldDefinitionList[inputType]
  const usesStockSection = stockSectionTypes.has(inputType)

  initializeFieldDefinition(
    definition,
    {
      props: ['alternativeBackground'],
      features: [
        addLink,
        addSubmitEvent,
        formUpdaterTrigger('delayed'),
        setPopulatedOnWebkitAutofill,
        defaultEmptyValueString,
      ],
    },
    { schema: usesStockSection ? formKitTextInput : textInput },
  )

  // All these definitions carry FormKit's shared text schemaMemoKey, which keys
  //   a global compile cache — the readonly variant renders differently, so it
  //   needs its own key or the first compiled type would define all of them.
  if (!usesStockSection) definition.schemaMemoKey = `readonly_${definition.schemaMemoKey}`

  inputFields.push({
    fieldType: inputType,
    definition,
  })
})

export default inputFields
