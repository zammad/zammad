// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { computed, effectScope, type EffectScope } from 'vue'

import { mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { TicketArticleTranslationAvailabilityFragmentDoc } from '#shared/entities/ticket-article/graphql/fragments/ticketArticleTranslationAvailability.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useArticleTranslationCache } from '../useArticleTranslationCache.ts'

import type { InMemoryCache } from '@apollo/client/core'

const articleId = convertToGraphQLId('Ticket::Article', 1)
const cache = mockedApolloClient.cache as InMemoryCache
let scope: EffectScope

beforeEach(() => {
  scope = effectScope()
})
afterEach(() => scope.stop())

it('shares reactive availability per locale through Apollo without loading content', async () => {
  const writer = scope.run(useArticleTranslationCache)!
  writer.writeAvailability(articleId, 'de-de', true)
  writer.writeAvailability(articleId, 'fr-fr', false)

  const reader = scope.run(useArticleTranslationCache)!
  const readAvailability = vi.fn(() => reader.readAvailability(articleId, 'de-de'))
  const available = computed(readAvailability)
  expect(available.value).toBe(true)
  expect(reader.readAvailability(articleId, 'fr-fr')).toBe(false)
  expect(reader.read(articleId, 'de-de')).toBeUndefined()
  expect(
    cache.readFragment({
      id: cache.identify({ __typename: 'TicketArticle', id: articleId }),
      fragment: TicketArticleTranslationAvailabilityFragmentDoc,
      variables: { targetLocale: 'de-de' },
    }),
  ).toMatchObject({ translationAvailable: true })

  await waitForNextTick(true)
  expect(available.value).toBe(true)
  expect(readAvailability).toHaveBeenCalledTimes(1)

  writer.writeAvailability(articleId, 'de-de', false)
  await waitFor(() => expect(available.value).toBe(false))
  expect(readAvailability).toHaveBeenCalledTimes(2)
})

it('observes content updates and releases watches and cached articles', async () => {
  const writer = scope.run(useArticleTranslationCache)!
  const reader = scope.run(useArticleTranslationCache)!
  const translated = { content: 'Hallo', backend: 'ai', translated: true }
  writer.write(articleId, 'de-de', translated)
  const content = computed(() => reader.read(articleId, 'de-de'))
  expect(content.value).toMatchObject(translated)
  expect(reader.readAvailability(articleId, 'de-de')).toBe(true)

  writer.write(articleId, 'de-de', { ...translated, content: 'Updated' })
  await waitFor(() => expect(content.value?.content).toBe('Updated'))

  const watchFragment = vi.spyOn(cache, 'watchFragment')
  scope.stop()
  reader.readAvailability(articleId, 'fr-fr')
  expect(watchFragment).not.toHaveBeenCalled()
  watchFragment.mockRestore()
  expect(cache.gc()).toContain(cache.identify({ __typename: 'TicketArticle', id: articleId }))
  expect(reader.read(articleId, 'de-de')).toBeUndefined()
})
