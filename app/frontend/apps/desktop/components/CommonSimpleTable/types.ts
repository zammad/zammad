// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface TableHeader {
  key: string
  label: string
  labelPlaceholder?: string[]
}

export interface TableItem {
  [key: string]: unknown
  id: string | number
}
