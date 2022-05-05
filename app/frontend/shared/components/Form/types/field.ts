// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitFrameworkContext } from '@formkit/core'
import type { FormFieldAdditionalProps } from '@shared/components/Form/types'
import type { FormDefaultProps } from '@shared/types/form'

export type FormFieldContext<TFieldProps = FormFieldAdditionalProps> =
  FormKitFrameworkContext & FormDefaultProps & TFieldProps
