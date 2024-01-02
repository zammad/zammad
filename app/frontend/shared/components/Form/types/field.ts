// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitFrameworkContext } from '@formkit/core'
import type { FormDefaultProps } from '#shared/types/form.ts'
import type { FormFieldAdditionalProps } from '../types.ts'

export type FormFieldContext<TFieldProps = FormFieldAdditionalProps> =
  FormKitFrameworkContext & FormDefaultProps & TFieldProps
