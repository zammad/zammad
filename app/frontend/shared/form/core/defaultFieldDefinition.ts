// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitTypeDefinition } from '@formkit/core'
import type { FormDefaultProps } from '@shared/types/form'
import hideField from '../features/hideField'
import translateWrapperProps from '../features/translateWrapperProps'
import addBlurEvent from '../features/addBlurEvent'

const defaultProps: (keyof FormDefaultProps)[] = [
  'formId',
  'labelSrOnly',
  'labelPlaceholder',
  'internal',
]

const defaulfFieldDefinition: Required<
  Pick<FormKitTypeDefinition, 'props' | 'features'>
> = {
  features: [translateWrapperProps, hideField, addBlurEvent],
  props: defaultProps,
}

export default defaulfFieldDefinition
