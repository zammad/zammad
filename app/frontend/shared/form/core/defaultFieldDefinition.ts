// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitTypeDefinition } from '@formkit/core'
import type { FormDefaultProps } from '@shared/types/form'
import translateWrapperProps from '../features/translateWrapperProps'

const defaultProps: (keyof FormDefaultProps)[] = ['formId', 'labelPlaceholder']

const defaulfFieldDefinition: Required<
  Pick<FormKitTypeDefinition, 'props' | 'features'>
> = {
  features: [translateWrapperProps],
  props: defaultProps,
}

export default defaulfFieldDefinition
