// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@common/form/core/initializeFieldDefinition'
import { password as passwordDefinition } from '@formkit/inputs'

initializeFieldDefinition(passwordDefinition)

export default {
  fieldType: 'password',
  definition: passwordDefinition,
}
