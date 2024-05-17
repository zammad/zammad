// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldOrganizationWrapper from './FieldOrganizationWrapper.vue'

const fieldDefinition = createInput(
  FieldOrganizationWrapper,
  autoCompleteProps,
  { features: [addLink, formUpdaterTrigger()] },
  { addArrow: true },
)

export default {
  fieldType: 'organization',
  definition: fieldDefinition,
}
