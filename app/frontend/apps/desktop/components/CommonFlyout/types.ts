// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'

import { type Props as ButtonProps } from '#desktop/components/CommonButton/CommonButton.vue'

export type FlyoutSizes = 'medium' | 'large'

export interface ActionFooterOptions {
  hideActionButton?: boolean
  actionLabel?: string
  actionButton?: Pick<
    ButtonProps,
    'prefixIcon' | 'variant' | 'type' | 'disabled'
  >
  hideCancelButton?: boolean
  cancelLabel?: string
  cancelButton?: Pick<ButtonProps, 'prefixIcon' | 'variant' | 'disabled'>
  form?: FormRef
}
