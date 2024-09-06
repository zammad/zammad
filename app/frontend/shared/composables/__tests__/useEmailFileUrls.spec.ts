// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useEmailFileUrls } from '#shared/composables/useEmailFileUrls.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

describe('useEmailFileUrls', () => {
  it('should return originalFormattingUrl and rawMessageUrl for email articles', () => {
    const { originalFormattingUrl, rawMessageUrl } = useEmailFileUrls(
      ref(
        createDummyArticle({
          articleType: 'email',
          attachmentsWithoutInline: [
            {
              id: convertToGraphQLId('Store', 123),
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
        }),
      ),
      ref(222),
    )

    expect(originalFormattingUrl.value).toBe(
      '/api/v1/ticket_attachment/222/1/123?disposition=attachment',
    )
    expect(rawMessageUrl.value).toBe('/api/v1/ticket_article_plain/1')
  })

  it('should return only rawMessageUrl for email articles without original format attachment', () => {
    const { originalFormattingUrl, rawMessageUrl } = useEmailFileUrls(
      ref(
        createDummyArticle({
          articleType: 'email',
        }),
      ),
      ref(222),
    )

    expect(originalFormattingUrl.value).toBeUndefined()
    expect(rawMessageUrl.value).toBe('/api/v1/ticket_article_plain/1')
  })

  it('should return nothing for other article types', () => {
    const { originalFormattingUrl, rawMessageUrl } = useEmailFileUrls(
      ref(createDummyArticle()),
      ref(222),
    )

    expect(originalFormattingUrl.value).toBeUndefined()
    expect(rawMessageUrl.value).toBeUndefined()
  })
})
