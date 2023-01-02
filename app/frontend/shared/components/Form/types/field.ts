// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitFrameworkContext } from '@formkit/core'
import type { FormDefaultProps } from '@shared/types/form'
import type { FormFieldAdditionalProps } from '../types'

export type FormFieldContext<TFieldProps = FormFieldAdditionalProps> =
  FormKitFrameworkContext & FormDefaultProps & TFieldProps
