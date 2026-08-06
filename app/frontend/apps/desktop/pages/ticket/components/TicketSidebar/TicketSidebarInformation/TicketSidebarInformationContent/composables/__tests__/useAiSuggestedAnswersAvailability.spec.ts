// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach } from 'vitest'
import { nextTick, ref } from 'vue'

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
    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(true)

    expect(showAiSuggestedAnswers.value).toBe(true)
  })

  it('is unavailable while the feature is disabled', () => {
    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_kb_answer_suggestions: false,
    })

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(true)

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('is unavailable without a configured AI provider', () => {
    mockApplicationConfig({
      ai_provider: false,
      ai_assistance_kb_answer_suggestions: true,
    })

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(true)

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('is available without knowledge base access', () => {
    mockPermissions(['ticket.agent'])

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(true)

    expect(showAiSuggestedAnswers.value).toBe(true)
  })

  // An agent who is the customer of a ticket in a group they cannot access has agent permission,
  //   but no agent read access to that ticket - the server denies the search for it.
  it('is unavailable without agent read access to the ticket', () => {
    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(false)

    expect(showAiSuggestedAnswers.value).toBe(false)
  })

  it('reacts to a change of the agent read access', async () => {
    const hasAgentReadAccess = ref(false)

    const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability(hasAgentReadAccess)

    expect(showAiSuggestedAnswers.value).toBe(false)

    hasAgentReadAccess.value = true
    await nextTick()

    expect(showAiSuggestedAnswers.value).toBe(true)
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

      const { showRelevanceScore } = useAiSuggestedAnswersAvailability(true)

      expect(showRelevanceScore.value).toBe(true)
    },
  )

  it('hides relevance score for non-admins', () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    const { showRelevanceScore } = useAiSuggestedAnswersAvailability(true)

    expect(showRelevanceScore.value).toBe(false)
  })
})
