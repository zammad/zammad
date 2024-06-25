// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonContentPanel from '../CommonContentPanel.vue'

describe('CommonContentPanel.vue', () => {
  it('renders CommonContentPanel', () => {
    const wrapper = renderComponent(CommonContentPanel, {
      slots: {
        default: 'some content',
      },
    })

    expect(wrapper.getByText('some content')).toBeInTheDocument()
  })
})
