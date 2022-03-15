// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@common/form/core/initializeFieldDefinition'
import { select as selectDefinition } from '@formkit/inputs'

// TODO: at the moment only the FormKit-BuildIn, but will be replaces with a own version.

initializeFieldDefinition(selectDefinition)

export default {
  fieldType: 'select',
  definition: selectDefinition,
}
