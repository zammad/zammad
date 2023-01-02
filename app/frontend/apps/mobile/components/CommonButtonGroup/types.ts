// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'

export interface CommonButtonOption {
  link?: string
  value?: string | number
  onAction?(): unknown | Promise<unknown>
  label: string
  controls?: string
  selected?: boolean
  labelPlaceholder?: string[]
  disabled?: boolean
  hidden?: boolean
  permissions?: string | string[]
  icon?: string | IconProps
}
