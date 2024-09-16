// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import { lookupArticlePlugin } from '#desktop/pages/ticket/components/TicketDetailView/article-type/index.ts'
import ArticleMetaFieldAddress from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaAddress.vue'
import type { ChannelMetaField } from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/types.ts'

const getNestedProperty = (article: TicketArticle, nestedKeys: string[]) => {
  return nestedKeys.reduce((accumulator, currentKey) => {
    if (accumulator && typeof accumulator === 'object') {
      return accumulator[currentKey as keyof typeof article]
    }
    return undefined
  }, article)
}

const addNewFields = (
  fields: ChannelMetaField[],
  article: Ref<TicketArticle>,
) => {
  const plugin = lookupArticlePlugin(article.value.type?.name as string)
  if (!plugin?.additionalFields?.length) return fields

  plugin.additionalFields.forEach((field) => {
    const nestedKeys = field.name.split('.')

    const fieldValue = getNestedProperty(article.value, nestedKeys)

    if (field.show !== undefined && !field.show?.(article)) return fields

    if (fieldValue)
      fields.push({
        label: field.label || (article.value.type?.name as string),
        name: field.name,
        component: field.component,
        order: field.order,
        value: fieldValue,
      })
  })

  return fields
}

export const useArticleMeta = (article: Ref<TicketArticle>) => {
  const links = computed(() => article.value.preferences?.links || [])

  const fields = computed(() => {
    const plugin = lookupArticlePlugin(article.value.type?.name as string)

    const base = [
      {
        label: __('Created at'),
        name: 'created_at',
        component: CommonDateTime,
        props: {
          class: 'text-sm',
          dateTime: article.value.createdAt,
          type: 'absolute',
        },
        order: 100,
      },
      {
        label: __('From'),
        name: 'from',
        component: ArticleMetaFieldAddress,
        props: {
          type: 'from',
        },
        show: () =>
          !!(article.value.from?.parsed?.[0]?.name || article.value.from?.raw),
        order: 200,
      },
      {
        label: __('To'),
        name: 'to',
        component: ArticleMetaFieldAddress,
        props: {
          type: 'to',
        },
        show: () =>
          !!(article.value.to?.parsed?.[0]?.name || article.value.to?.raw),
        order: 300,
      },
      {
        label: __('CC'),
        name: 'cc',
        component: ArticleMetaFieldAddress,
        props: {
          type: 'cc',
        },
        show: () =>
          !!(article.value.cc?.parsed?.[0]?.name || article.value.cc?.raw),
        order: 350,
      },
      {
        label: __('Channel'),
        name: 'channel',
        value: plugin?.name,
        icon: plugin?.icon,
        links: article.value.preferences?.links,
        component: plugin?.channel?.component,
        order: 400,
      },
    ]

    return addNewFields(base as ChannelMetaField[], article)
      .filter((field) => (field.show ? field.show(article.value) : true))
      .sort((a, b) => a.order - b.order)
  })

  return { fields, links }
}
