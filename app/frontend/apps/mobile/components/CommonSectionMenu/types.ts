// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { type Props as LinkProps } from './CommonSectionMenuLink.vue'

export interface MenuItem extends LinkProps {
  type: 'link'
  onClick?(event: MouseEvent): void
}
