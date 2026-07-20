// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { knowledgeBasePreviewUrl } from '../useKnowledgeBasePreviewUrl.ts'

describe('knowledgeBasePreviewUrl', () => {
  it('builds the category preview endpoint URL from the GraphQL id and locale', () => {
    const url = knowledgeBasePreviewUrl(
      'KnowledgeBaseCategory',
      convertToGraphQLId('KnowledgeBase::Category', 42),
      'en-us',
    )

    expect(url).toBe('/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/42/en-us')
  })

  it('builds the knowledge base root preview endpoint URL', () => {
    const url = knowledgeBasePreviewUrl(
      'KnowledgeBase',
      convertToGraphQLId('KnowledgeBase', 1),
      'de-de',
    )

    expect(url).toBe('/api/v1/knowledge_bases/preview/KnowledgeBase/1/de-de')
  })
})
