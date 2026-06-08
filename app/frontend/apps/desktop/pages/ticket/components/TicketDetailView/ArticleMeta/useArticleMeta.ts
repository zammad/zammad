// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { i18n } from '#shared/i18n.ts'

import { lookupArticlePlugin } from '#desktop/pages/ticket/components/TicketDetailView/article-type/index.ts'
import ArticleMetaAddress from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaAddress.vue'
import ArticleMetaDetectedLanguage from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaDetectedLanguage.vue'
import type { ChannelMetaField } from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/types.ts'

const getNestedProperty = (article: TicketArticle, nestedKeys: string[]) => {
  return nestedKeys.reduce((accumulator, currentKey) => {
    if (accumulator && typeof accumulator === 'object') {
      return accumulator[currentKey as keyof typeof article]
    }
    return undefined
  }, article)
}

const addNewFields = (fields: ChannelMetaField[], article: Ref<TicketArticle>) => {
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
        component: ArticleMetaAddress,
        props: {
          metaHeader: 'from',
        },
        show: () => !!(article.value.from?.parsed?.length || article.value.from?.raw),
        order: 200,
      },
      {
        label: __('To'),
        name: 'to',
        component: ArticleMetaAddress,
        props: {
          metaHeader: 'to',
        },
        show: () => !!(article.value.to?.parsed?.length || article.value.to?.raw),
        order: 300,
      },
      {
        label: __('CC'),
        name: 'cc',
        component: ArticleMetaAddress,
        props: {
          metaHeader: 'cc',
        },
        show: () => !!(article.value.cc?.parsed?.length || article.value.cc?.raw),
        order: 350,
      },
      {
        label: __('Detected language'),
        name: 'detectedLanguage',
        component: ArticleMetaDetectedLanguage,
        show: () => !!article.value.detectedLanguage?.length,
        order: 375,
      },
      {
        label: __('Channel'),
        name: 'channel',
        value: i18n.t(plugin?.metaLabel),
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
