// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import translateWrapperProps from '@common/form/features/translateWrapperProps'
import type { FormKitTypeDefinition } from '@formkit/core'

const defaulfFieldDefinition: Required<
  Pick<FormKitTypeDefinition, 'props' | 'features'>
> = {
  features: [translateWrapperProps],
  props: ['labelPlaceholder'],
}

export default defaulfFieldDefinition
