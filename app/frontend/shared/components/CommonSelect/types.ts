// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Props as IconProps } from '#shared/components/CommonIcon/CommonIcon.vue'
import type { ObjectSelectOption } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'
import type { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

export type { ObjectSelectValue as SelectValue } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'

export interface SelectOption extends ObjectSelectOption {
  labelPlaceholder?: string[]
  status?: EnumTicketStateColorCode
  icon?: string
  iconProps?: Omit<IconProps, 'name'>
  match?: RegExpExecArray
}

export interface MatchedSelectOption extends SelectOption {
  matchedLabel?: string
}
