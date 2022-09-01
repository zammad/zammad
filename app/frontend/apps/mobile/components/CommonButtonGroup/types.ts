// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'

export interface CommonButtonOption {
  link?: string
  onAction?(): void | Promise<void>
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  selected?: boolean
  icon?: string | IconProps
}
