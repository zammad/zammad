// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { initializeAppName } from '#shared/composables/useAppName.ts'
import type { KnowledgeBaseAnswerTranslation } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import builder from '../knowledge-base-answer.ts'

const buildMetaObject = (): KnowledgeBaseAnswerTranslation =>
  ({
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    title: 'Reset your password',
    kbLocale: {
      systemLocale: { locale: 'en-us' },
    },
    answer: {
      id: convertToGraphQLId('KnowledgeBase::Answer', 1),
      category: {
        id: convertToGraphQLId('KnowledgeBase::Category', 1),
      },
    },
  }) as unknown as KnowledgeBaseAnswerTranslation

describe('activityMessageBuilder for KnowledgeBase::Answer::Translation', () => {
  it('links into the desktop view for an agent with knowledge base permission', () => {
    initializeAppName('desktop')
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    expect(builder.path(buildMetaObject())).toBe('knowledge-base/locale/en-us/answer/1')
  })

  it('links from the mobile app into the desktop view, which has an answer view', () => {
    initializeAppName('mobile')
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    expect(builder.path(buildMetaObject())).toBe('desktop/knowledge-base/locale/en-us/answer/1')
  })

  it('links to the public answer page for a user without knowledge base permission', () => {
    initializeAppName('mobile')
    mockPermissions(['ticket.agent'])

    expect(builder.path(buildMetaObject())).toBe('help/en-us/1/1')
  })
})
