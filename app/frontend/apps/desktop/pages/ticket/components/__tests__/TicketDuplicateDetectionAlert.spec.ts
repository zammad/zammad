// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import TicketDuplicateDetectionAlert from '../TicketCreate/TicketDuplicateDetectionAlert.vue'

describe('TicketDuplicateDetectionAlert.vue', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ticket_duplicate_detection_title: 'some title',
      ticket_duplicate_detection_body: 'some body',
    })
  })

  it('renders duplicate alert without tickets', () => {
    const wrapper = renderComponent(TicketDuplicateDetectionAlert)

    expect(wrapper.getByText('some title')).toBeInTheDocument()
    expect(wrapper.getByText('some body')).toBeInTheDocument()
  })

  it('renders duplicate alert without tickets', () => {
    const wrapper = renderComponent(TicketDuplicateDetectionAlert, {
      props: {
        tickets: [[1, '123', 'some ticket title']],
      },
      router: true,
    })

    expect(wrapper.getByText('some ticket title')).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: '123' })).toBeInTheDocument()
  })
})
