// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach } from 'vitest'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useAiSuggestedAnswersAvailability } from '../useAiSuggestedAnswersAvailability.ts'

describe('useAiSuggestedAnswersAvailability', () => {
  beforeEach(() => {
    mockPermissions([
      'ticket.agent',
      'knowledge_base.reader',
      'admin.ai_provider',
      'admin.ai_knowledge_base',
    ])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_kb_answer_suggestions: true,
    })
  })

  it('is available for an agent with knowledge base access, a provider and the feature enabled', () => {
    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

    expect(showAiSuggestedAnswers.value).toBe(true)
  })

  it('is unavailable while the feature is disabled', () => {
    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_kb_answer_suggestions: false,
    })

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('is unavailable without a configured AI provider', () => {
    mockApplicationConfig({
      ai_provider: false,
      ai_assistance_kb_answer_suggestions: true,
    })

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('is unavailable without knowledge base access', () => {
    mockPermissions(['ticket.agent'])

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('is unavailable for a user who is not an agent', () => {
    mockPermissions(['knowledge_base.reader'])

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it.each([
    { permissions: ['admin'] },
    { permissions: ['admin.ai_provider'] },
    { permissions: ['admin.ai_knowledge_base'] },
    { permissions: ['admin.ai_provider', 'admin.ai_knowledge_base'] },
  ])(
    'shows relevance score for an admin with right permissions: $permissions',
    ({ permissions }) => {
      mockPermissions(permissions)

      const { showRelevanceScore } = useAiSuggestedAnswersAvailability()

      expect(showRelevanceScore.value).toBe(true)
    },
  )

  it('hides relevance score for non-admins', () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    const { showRelevanceScore } = useAiSuggestedAnswersAvailability()

    expect(showRelevanceScore.value).toBe(false)
  })
})
