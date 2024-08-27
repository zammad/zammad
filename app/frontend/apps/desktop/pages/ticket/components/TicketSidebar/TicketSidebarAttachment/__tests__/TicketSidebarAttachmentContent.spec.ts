// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import ticketArticlAttachmentsSidebarPlugin from '../../plugins/ticket-article-attachment.ts'
import TicketSidebarAttachmentContent from '../TicketSidebarAttachmentContent.vue'

const ticket = { value: createDummyTicket() }

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticketId: computed(() => ticket.value.id),
    ticket: computed(() => ticket.value),
  }),
}))

const renderAttachmentContent = () =>
  renderComponent(TicketSidebarAttachmentContent, {
    props: {
      sidebarPlugin: ticketArticlAttachmentsSidebarPlugin,
      ticketAttachments: [
        {
          __typename: 'StoredFile',
          id: 'gid://zammad/Store/316',
          internalId: 316,
          name: 'image010.jpg',
          size: 3668,
          type: 'image/jpeg',
          preferences: {
            'Content-Type': 'image/jpeg',
          },
        },
        {
          __typename: 'StoredFile',
          id: 'gid://zammad/Store/314',
          internalId: 314,
          name: 'Test PDF.pdf',
          size: 31324,
          type: 'application/pdf',
          preferences: {
            'Content-Type': 'application/pdf',
          },
        },
        {
          __typename: 'StoredFile',
          id: 'gid://zammad/Store/312',
          internalId: 312,
          name: 'Entsorgungstermine.ics',
          size: 29737,
          type: 'text/calendar',
          preferences: {
            'Content-Type': 'text/calendar',
          },
        },
      ],
      loading: false,
      context: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        formValues: {},
        toggleCollapse: () => {},
        isCollapsed: false,
      },
    },
    router: true,
    form: true,
    dialog: true,
  })

describe('TicketSidebarAttachmentContent', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_zoom_sidebar_article_attachments: true,
    })
  })

  it('renders attachments', async () => {
    const wrapper = renderAttachmentContent()

    expect(await wrapper.findByText('image010.jpg')).toBeInTheDocument()
    expect(await wrapper.findByText('Test PDF.pdf')).toBeInTheDocument()
    expect(
      await wrapper.findByText('Entsorgungstermine.ics'),
    ).toBeInTheDocument()
  })
})
