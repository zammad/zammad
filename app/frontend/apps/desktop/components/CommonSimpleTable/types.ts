// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import type { Props as CommonLinkProps } from '#shared/components/CommonLink/CommonLink.vue'

type TableColumnType = 'timestamp' | 'timestamp_absolute' | 'link'

export interface TableHeader<K = string> {
  key: K
  label: string
  labelPlaceholder?: string[]
  columnClass?: string
  columnSeparator?: boolean
  alignContent?: 'center' | 'right'
  type?: TableColumnType
  truncate?: boolean
  labelClass?: string
  [key: string]: unknown
}
export interface TableItem {
  [key: string]: unknown | Partial<CommonLinkProps>
  id: string | number
}
