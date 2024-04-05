// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'

export const useBreadcrumb = (currentItem: string | BreadcrumbItem) => {
  const baseBreadcrumbItem: BreadcrumbItem = {
    label: __('Profile'),
    route: '/personal-setting',
  }

  const breadcrumbItems: BreadcrumbItem[] = [baseBreadcrumbItem]

  if (typeof currentItem === 'string') {
    breadcrumbItems.push({
      label: currentItem,
    })
  } else {
    breadcrumbItems.push(currentItem)
  }

  return {
    breadcrumbItems,
  }
}
