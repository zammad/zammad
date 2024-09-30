// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'

describe('CommonTicketLabel', () => {
  it('display unauthorized state if unauthorized prop is true', () => {
    const wrapper = renderComponent(CommonTicketLabel, {
      props: {
        unauthorized: true,
        ticket: null,
      },
      router: true,
    })

    expect(wrapper.getByText('Access denied')).toBeInTheDocument()
    expect(wrapper.getByIconName('x-lg')).toBeInTheDocument()
  })

  it.each([
    EnumTicketStateColorCode.Open,
    EnumTicketStateColorCode.Closed,
    EnumTicketStateColorCode.Pending,
    EnumTicketStateColorCode.Escalating,
  ])('shows label in %s', (colorState) => {
    const wrapper = renderComponent(CommonTicketLabel, {
      props: {
        unauthorized: false,
        ticket: createDummyTicket({
          title: 'Foo test title',
          colorCode: colorState,
        }),
      },
      router: true,
    })

    expect(wrapper.getByText('Foo test title')).toBeInTheDocument()
  })
})
