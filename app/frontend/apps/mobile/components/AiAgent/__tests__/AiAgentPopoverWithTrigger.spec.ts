// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import AiAgentAvatar from '#mobile/components/AiAgent/AiAgentAvatar.vue'

describe('AiAgentAvatar', () => {
  it('renders AiAgentAvatar', () => {
    const wrapper = renderComponent(AiAgentAvatar)

    expect(wrapper.getByIconName('ai-agent')).toBeInTheDocument()

    expect(wrapper.getByLabelText('AI Agent')).toBeInTheDocument()
  })
})
