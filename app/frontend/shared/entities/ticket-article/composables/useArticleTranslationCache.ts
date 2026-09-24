// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onScopeDispose, ref } from 'vue'

import { TicketArticleTranslationFragmentDoc } from '#shared/entities/ticket-article/graphql/fragments/ticketArticleTranslation.api.ts'
import { TicketArticleTranslationAvailabilityFragmentDoc } from '#shared/entities/ticket-article/graphql/fragments/ticketArticleTranslationAvailability.api.ts'
import type { ArticleTranslationResult } from '#shared/entities/ticket-article/stores/types.ts'
import type {
  TicketArticleTranslationFragment,
  TicketArticleTranslationAvailabilityFragment,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import type { InMemoryCache } from '@apollo/client/core'

type TranslationFields = Pick<TicketArticleTranslationFragment, 'translation'> &
  Pick<TicketArticleTranslationAvailabilityFragment, 'translationAvailable'>

const fragments = {
  translation: TicketArticleTranslationFragmentDoc,
  translationAvailable: TicketArticleTranslationAvailabilityFragmentDoc,
}

export const useArticleTranslationCache = () => {
  const cache = getApolloClient().cache as InMemoryCache
  const subscriptions = new Map<string, { unsubscribe: () => void }>()
  const changes = ref(0)
  let disposed = false

  const fragment = (articleId: string, targetLocale: string, field: keyof TranslationFields) => ({
    id: cache.identify({ __typename: 'TicketArticle', id: articleId })!,
    fragment: fragments[field],
    variables: { targetLocale },
  })

  const readField = <Field extends keyof TranslationFields>(
    articleId: string,
    locale: string,
    field: Field,
  ) => {
    const options = fragment(articleId, locale, field)
    const key = `${articleId}:${locale}:${field}`
    if (!disposed && !subscriptions.has(key)) {
      let initial = true
      subscriptions.set(
        key,
        cache.watchFragment({ ...options, from: options.id }).subscribe(() => {
          // readFragment already returns the initial value; only later changes invalidate Vue.
          if (!initial) changes.value += 1
          initial = false
        }),
      )
    }
    // Apollo's fragment read alone is not a Vue reactive dependency.
    void changes.value
    return cache.readFragment<TranslationFields>(options)?.[field]
  }

  const writeField = <Field extends keyof TranslationFields>(
    articleId: string,
    locale: string,
    field: Field,
    value: TranslationFields[Field],
  ) => {
    const options = fragment(articleId, locale, field)
    cache.writeFragment({
      ...options,
      data: { __typename: 'TicketArticle', id: articleId, [field]: value },
    })
    // writeFragment retains a GC root; the article list owns the lifetime of this entity.
    cache.release(options.id)
  }

  const write = (articleId: string, locale: string, translation: ArticleTranslationResult) => {
    writeField(articleId, locale, 'translation', {
      __typename: 'ContentTranslation',
      content: translation.content,
      backend: translation.backend,
      translated: translation.translated,
    })
    writeField(articleId, locale, 'translationAvailable', true)
  }

  onScopeDispose(() => {
    disposed = true
    subscriptions.forEach((subscription) => subscription.unsubscribe())
  })

  return {
    batch: (update: () => void) => cache.batch({ update }),
    read: (articleId: string, locale: string) => readField(articleId, locale, 'translation'),
    readAvailability: (articleId: string, locale: string) =>
      readField(articleId, locale, 'translationAvailable'),
    write,
    writeAvailability: (
      articleId: string,
      locale: string,
      available: TranslationFields['translationAvailable'],
    ) => {
      if (typeof available === 'boolean')
        writeField(articleId, locale, 'translationAvailable', available)
    },
  }
}
