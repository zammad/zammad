// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Link } from '#shared/types/router.ts'

import type { ComputedRef } from 'vue'

export interface BreadcrumbItem {
  label: string | ComputedRef<string>
  noOptionLabelTranslation?: boolean
  route?: Link
  icon?: string
  count?: number
  isActive?: boolean
}
