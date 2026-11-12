// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { NamedAgent } from '#desktop/entities/chat/utils.ts'

import { useChatAgentName } from '../useChatAgentName.ts'

describe('useChatAgentName', () => {
  beforeEach(() => {
    mockApplicationConfig({ user_name_format: 'first_last' })
  })

  it('prefers the full name', () => {
    const agent = { firstname: 'Other', lastname: 'Agent', fullname: 'Other Agent' }

    expect(useChatAgentName(agent).value).toBe('Other Agent')
  })

  it('composes the name of an agent whose full name is not readable', () => {
    mockApplicationConfig({ user_name_format: 'last_first_comma' })

    const agent = { firstname: 'Other', lastname: 'Agent', fullname: null }

    expect(useChatAgentName(agent).value).toBe('Agent, Other')
  })

  it('is empty without an agent', () => {
    expect(useChatAgentName(undefined).value).toBe('')
  })

  it('follows the agent, its name and the name format', () => {
    const agent = ref<NamedAgent>({ firstname: 'Other', lastname: 'Agent' })
    const agentName = useChatAgentName(agent)

    expect(agentName.value).toBe('Other Agent')

    agent.value.firstname = 'Another'
    expect(agentName.value).toBe('Another Agent')

    agent.value = { firstname: 'Chat', lastname: 'Agent' }
    expect(agentName.value).toBe('Chat Agent')

    mockApplicationConfig({ user_name_format: 'last_first_comma' })
    expect(agentName.value).toBe('Agent, Chat')
  })
})
