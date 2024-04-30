// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface TableHeader {
  key: string
  label: string
  labelPlaceholder?: string[]
  type?: 'timestamp'
}

export interface TableItem {
  [key: string]: unknown
  id: string | number
}
