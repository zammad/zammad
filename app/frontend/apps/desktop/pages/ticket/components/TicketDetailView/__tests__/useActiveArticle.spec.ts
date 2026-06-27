// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mount } from '@vue/test-utils'
import { useIntersectionObserver } from '@vueuse/core'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { nextTick, ref, shallowRef } from 'vue'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { TicketArticleRow } from '#desktop/pages/ticket/composables/useTicketArticlesRows.ts'

import { useActiveArticle } from '../useActiveArticle.ts'

vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  useIntersectionObserver: vi.fn(),
}))

const mockedUseIntersectionObserver = vi.mocked(useIntersectionObserver)

const rows = ref<TicketArticleRow[]>([])

let intersectionCallback: IntersectionObserverCallback

const renderComposable = () => {
  let api!: ReturnType<typeof useActiveArticle>

  mount({
    setup() {
      api = useActiveArticle(rows, shallowRef<HTMLElement[]>([]), ref<HTMLElement | null>(null))
      return () => null
    },
  })

  return api
}

// Simulates the single IntersectionObserver reporting an article's visibility.
const setIntersecting = (key: string, isIntersecting: boolean) =>
  intersectionCallback(
    [{ target: { id: `article-${key}` }, isIntersecting } as IntersectionObserverEntry],
    {} as IntersectionObserver,
  )

describe('useActiveArticle', () => {
  beforeEach(() => {
    mockedUseIntersectionObserver.mockImplementation(((
      _target: unknown,
      callback: IntersectionObserverCallback,
      _options?: IntersectionObserverInit,
    ) => {
      intersectionCallback = callback
      return { stop: vi.fn() }
    }) as never)

    rows.value = [
      {
        type: 'article-bubble',
        key: '1',
        article: { id: convertToGraphQLId('Article', 1), internalId: 1 },
      },
      {
        type: 'article-bubble',
        key: '2',
        article: { id: convertToGraphQLId('Article', 2), internalId: 2 },
      },
      { type: 'more', key: 'more', count: 1 },
      {
        type: 'article-bubble',
        key: '3',
        article: { id: convertToGraphQLId('Article', 3), internalId: 3 },
      },
    ] as TicketArticleRow[]
  })

  it('returns the topmost visible article', async () => {
    const { activeArticleKey } = renderComposable()

    setIntersecting('2', true)
    await nextTick()
    expect(activeArticleKey.value).toBe('2')

    // The first article scrolls into view above the second one and wins.
    setIntersecting('1', true)
    await nextTick()
    expect(activeArticleKey.value).toBe('1')

    // Scrolling past the first article hands the active state to the next one.
    setIntersecting('1', false)
    await nextTick()
    expect(activeArticleKey.value).toBe('2')
  })
})
