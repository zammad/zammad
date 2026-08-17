// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'
import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

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

mockRouterHooks()

const renderAttachmentContent = () =>
  renderComponent(TicketSidebarAttachmentContent, {
    props: {
      sidebarPlugin: ticketArticlAttachmentsSidebarPlugin,
      modelValue: {},
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
      api_path: '/api',
      'active_storage.content_types_allowed_inline': ['image/jpeg'],
    })
  })

  it('renders attachments', async () => {
    const wrapper = renderAttachmentContent()

    expect(await wrapper.findByRole('list', { name: 'Attached files' })).toBeInTheDocument()
    expect(wrapper.getAllByRole('listitem')).toHaveLength(3)
  })

  it('opens previewable attachments and downloads the rest', async () => {
    const wrapper = renderAttachmentContent()

    // The image and the calendar file both have a preview, so their rows open it …
    expect(await wrapper.findByRole('button', { name: 'Preview image010.jpg' })).toBeInTheDocument()
    expect(
      await wrapper.findByRole('button', { name: 'Preview Entsorgungstermine.ics' }),
    ).toBeInTheDocument()

    // … while the PDF has none, so its row is the download itself.
    expect(await wrapper.findByRole('link', { name: 'Download Test PDF.pdf' })).toBeInTheDocument()
  })

  it('offers a download for every attachment', async () => {
    const wrapper = renderAttachmentContent()

    expect(
      await wrapper.findByRole('link', { name: 'Download file: image010.jpg' }),
    ).toHaveAttribute('href', '/api/attachments/316?disposition=attachment')
  })

  it('renders no list without attachments', () => {
    const wrapper = renderComponent(TicketSidebarAttachmentContent, {
      props: {
        sidebarPlugin: ticketArticlAttachmentsSidebarPlugin,
        modelValue: {},
        ticketAttachments: [],
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

    expect(wrapper.queryByRole('list')).not.toBeInTheDocument()
    expect(wrapper.getByText('No attached files')).toBeInTheDocument()
  })
})
