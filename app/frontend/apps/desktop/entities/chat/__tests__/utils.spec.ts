// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { formatChatAgentName } from '../utils.ts'

describe('formatChatAgentName', () => {
  it('prefers the full name', () => {
    const agent = { firstname: 'Other', lastname: 'Agent', fullname: 'Other Agent' }

    expect(formatChatAgentName(agent, 'last_first_comma')).toBe('Other Agent')
  })

  it.each([
    ['first_last', 'Other Agent'],
    ['last_first', 'Agent Other'],
    ['last_first_comma', 'Agent, Other'],
    [undefined, 'Other Agent'],
  ])('composes the name without a full name in the format %s', (nameFormat, name) => {
    const agent = { firstname: 'Other', lastname: 'Agent', fullname: null }

    expect(formatChatAgentName(agent, nameFormat)).toBe(name)
  })
})
