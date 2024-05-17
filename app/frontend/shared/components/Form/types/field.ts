// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormDefaultProps } from '#shared/types/form.ts'

import type { FormFieldAdditionalProps } from '../types.ts'
import type { FormKitFrameworkContext } from '@formkit/core'

// TODO: Workaround for a missing FormKit context attribute, remove when we update to include the fix.
//   https://github.com/formkit/formkit/pull/1303
interface FormKitFrameworkContextExtended extends FormKitFrameworkContext {
  describedBy?: string
}

export type FormFieldContext<TFieldProps = FormFieldAdditionalProps> =
  FormKitFrameworkContextExtended & FormDefaultProps & TFieldProps
