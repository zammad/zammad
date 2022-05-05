// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import translateWrapperProps from '@shared/form/features/translateWrapperProps'
import { FormDefaultProps } from '@shared/types/form'
import type { FormKitTypeDefinition } from '@formkit/core'

const defaultProps: (keyof FormDefaultProps)[] = ['formId', 'labelPlaceholder']

const defaulfFieldDefinition: Required<
  Pick<FormKitTypeDefinition, 'props' | 'features'>
> = {
  features: [translateWrapperProps],
  props: defaultProps,
}

export default defaulfFieldDefinition
