// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'

export interface CommonButtonOption {
  link?: string
  value?: string | number
  onAction?(): void | Promise<void>
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  icon?: string | IconProps
}
