// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { knowledgeBaseAnswerRoute, knowledgeBaseBrowseRoute } from '../utils/routeLocation.ts'

describe('knowledgeBaseBrowseRoute', () => {
  it('targets the section entry without a locale', () => {
    expect(knowledgeBaseBrowseRoute()).toEqual({ name: 'KnowledgeBaseBrowse', params: {} })
  })

  it('targets the localized root without a category', () => {
    expect(knowledgeBaseBrowseRoute('en-us')).toEqual({
      name: 'KnowledgeBaseBrowse',
      params: { localeCode: 'en-us' },
    })
  })

  it('uses the internal id in the category URL', () => {
    expect(
      knowledgeBaseBrowseRoute('en-us', convertToGraphQLId('KnowledgeBase::Category', 42)),
    ).toEqual({
      name: 'KnowledgeBaseCategory',
      params: { localeCode: 'en-us', categoryInternalId: 42 },
    })
  })
})

describe('knowledgeBaseAnswerRoute', () => {
  it('uses the internal id in the answer URL', () => {
    expect(
      knowledgeBaseAnswerRoute('de-de', convertToGraphQLId('KnowledgeBase::Answer', 7)),
    ).toEqual({
      name: 'KnowledgeBaseAnswer',
      params: { localeCode: 'de-de', answerInternalId: 7 },
    })
  })
})
