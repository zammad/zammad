// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { knowledgeBaseVisibilityMeta } from '../composables/useKnowledgeBaseVisibility.ts'

import type { CategoryBreadcrumb, KnowledgeBaseBreadcrumbItem } from '../types.ts'

interface KnowledgeBaseBreadcrumbOptions {
  localeCode?: string
  categoryBreadcrumb?: CategoryBreadcrumb
  // Appended after the categories (an opened answer). With one present, every
  //   category links — including the last, which is no longer the opened node.
  trailingItem?: KnowledgeBaseBreadcrumbItem
}

// The knowledge base root, the category path, and optionally the opened answer.
//   The last item is the opened node, so it carries no route and renders as the
//   page's `<h1>`.
export const knowledgeBaseBreadcrumbItems = ({
  localeCode,
  categoryBreadcrumb = [],
  trailingItem,
}: KnowledgeBaseBreadcrumbOptions): KnowledgeBaseBreadcrumbItem[] => {
  const items: KnowledgeBaseBreadcrumbItem[] = [
    {
      label: __('Knowledge Base Home') as string,
      noOptionLabelTranslation: false, // only the root is translated, the rest is user content
      icon: 'book',
      iconOnly: true,
      // Link back to the localized root only while browsing below it.
      route:
        (categoryBreadcrumb.length || trailingItem) && localeCode
          ? knowledgeBaseBrowseRoute(localeCode)
          : undefined,
    },
  ]

  categoryBreadcrumb.forEach((category, index) => {
    const isLast = index === categoryBreadcrumb.length - 1 && !trailingItem

    items.push({
      label: category.title ?? '',
      icon: category.categoryIcon,
      iconSet: category.iconSet,
      visibility: category.visibility,
      iconClass: category.visibility
        ? knowledgeBaseVisibilityMeta[category.visibility].class
        : undefined,
      route: isLast || !localeCode ? undefined : knowledgeBaseBrowseRoute(localeCode, category.id),
    })
  })

  if (trailingItem) items.push(trailingItem)

  return items
}
