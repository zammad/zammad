// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, reactive, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/HighlightMenu.vue'
import { items as highlightMenuItems } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/useHighlightMenuState.ts'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const ticket = createDummyTicket()

describe('HighlightMenu', () => {
  const renderHighlightMenu = (
    ticketId = ticket.id,
    highlightMenuState = {
      activeMenuItem: highlightMenuItems[0],
      isActive: false,
      isEraserActive: false,
    },
  ) =>
    renderComponent(HighlightMenu, {
      provide: [
        [
          TICKET_KEY,
          {
            ticketId: computed(() => ticketId),
            ticket: computed(() => ticket),
            form: ref(),
            showTicketArticleReplyForm: () => {},
            isTicketEditable: computed(() => true),
            newTicketArticlePresent: ref(false),
            ticketInternalId: computed(() => getIdFromGraphQLId(ticketId)),
            highlightMenu: reactive(highlightMenuState),
          },
        ],
      ],
    })

  it('renders component correctly', () => {
    const wrapper = renderHighlightMenu()

    expect(wrapper.getAllByRole('button')).toHaveLength(2)
    expect(wrapper.getByRole('button', { name: 'Highlight options' })).toBeInTheDocument()
    expect(wrapper.getByIconName('highlighter2')).toBeInTheDocument()
    expect(wrapper.getByIconName('chevron-down')).toBeInTheDocument()
  })

  it('shows all highlight options in context menu', async () => {
    const wrapper = renderHighlightMenu()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))

    expect(wrapper.getByText('Yellow')).toBeInTheDocument()
    expect(wrapper.getByText('Green')).toBeInTheDocument()
    expect(wrapper.getByText('Blue')).toBeInTheDocument()
    expect(wrapper.getByText('Pink')).toBeInTheDocument()
    expect(wrapper.getByText('Purple')).toBeInTheDocument()
    expect(wrapper.getByText('Remove highlight')).toBeInTheDocument()
    expect(wrapper.getByIconName('eraser-fill')).toBeInTheDocument()
  })

  it('toggles active highlight class on main button click', async () => {
    const wrapper = renderHighlightMenu()

    const button = wrapper.getByRole('button', { name: 'Highlighter color: Yellow' })

    expect(button).not.toHaveClass('bg-yellow-100')

    await wrapper.events.click(button)

    expect(button).toHaveClass('bg-yellow-200!')
  })

  it('switches to eraser icon when remove highlight is selected', async () => {
    const wrapper = renderHighlightMenu()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
    await wrapper.events.click(wrapper.getByText('Remove highlight'))

    expect(wrapper.getByIconName('eraser-fill')).toBeInTheDocument()
    expect(wrapper.queryByIconName('highlighter')).not.toBeInTheDocument()
  })

  it('keeps the eraser icon when the selected item is remove highlight', () => {
    const wrapper = renderHighlightMenu(ticket.id, {
      activeMenuItem: highlightMenuItems[5],
      isActive: true,
      isEraserActive: false,
    })

    expect(wrapper.getByIconName('eraser-fill')).toBeInTheDocument()
    expect(wrapper.queryByIconName('highlighter2')).not.toBeInTheDocument()
  })

  it('switches back to highlighter icon when a color is selected', async () => {
    const wrapper = renderHighlightMenu()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
    await wrapper.events.click(wrapper.getByText('Remove highlight'))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
    await wrapper.events.click(wrapper.getByText('Blue'))

    expect(wrapper.getByIconName('highlighter2')).toBeInTheDocument()
    expect(wrapper.queryByIconName('eraser-fill')).not.toBeInTheDocument()
  })

  describe('accessibility', () => {
    it('main button has aria-label reflecting the default selected color', () => {
      const wrapper = renderHighlightMenu()

      expect(wrapper.getByRole('button', { name: 'Highlighter color: Yellow' })).toBeInTheDocument()
    })

    it('main button aria-label updates when a new color is selected', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
      await wrapper.events.click(wrapper.getByText('Blue'))

      expect(wrapper.getByRole('button', { name: 'Highlighter color: Blue' })).toBeInTheDocument()
    })

    it('main button aria-label updates when remove highlight is selected', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
      await wrapper.events.click(wrapper.getByText('Remove highlight'))

      expect(wrapper.getByRole('button', { name: 'Remove highlight' })).toBeInTheDocument()
    })

    it('main button has aria-pressed=false by default', () => {
      const wrapper = renderHighlightMenu()

      const button = wrapper.getByRole('button', { name: 'Highlighter color: Yellow' })

      expect(button).toHaveAttribute('aria-pressed', 'false')
    })

    it('main button aria-pressed becomes true when toggled on', async () => {
      const wrapper = renderHighlightMenu()

      const button = wrapper.getByRole('button', { name: 'Highlighter color: Yellow' })
      await wrapper.events.click(button)

      expect(button).toHaveAttribute('aria-pressed', 'true')
    })

    it('main button aria-pressed toggles back to false on second click', async () => {
      const wrapper = renderHighlightMenu(convertToGraphQLId('4', 'Ticket'))

      const button = wrapper.getByRole('button', { name: 'Highlighter color: Yellow' })
      await wrapper.events.click(button)
      await wrapper.events.click(button)

      expect(button).toHaveAttribute('aria-pressed', 'false')
    })

    it('default color option (Yellow) has aria-pressed=true in the menu', async () => {
      const wrapper = renderHighlightMenu(convertToGraphQLId('6', 'Ticket'))

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))

      const yellowButton = wrapper.getByRole('button', { name: 'Yellow' })

      expect(yellowButton).toHaveAttribute('aria-pressed', 'true')
    })

    it('other color options have aria-pressed=false by default', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))

      for (const color of ['Green', 'Blue', 'Pink', 'Purple']) {
        expect(wrapper.getByRole('button', { name: color })).toHaveAttribute(
          'aria-pressed',
          'false',
        )
      }
    })

    it('selected color option updates aria-pressed state in the menu', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
      await wrapper.events.click(wrapper.getByText('Green'))

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))

      expect(wrapper.getByRole('button', { name: 'Green' })).toHaveAttribute('aria-pressed', 'true')
      expect(wrapper.getByRole('button', { name: 'Yellow' })).toHaveAttribute(
        'aria-pressed',
        'false',
      )
    })

    it('sr-only description region has aria-live=polite', () => {
      const wrapper = renderHighlightMenu()

      const liveRegion = wrapper.baseElement.querySelector('#highlight-menu-description')

      expect(liveRegion).toHaveAttribute('aria-live', 'polite')
    })

    it('sr-only description shows the selected color name', () => {
      const wrapper = renderHighlightMenu(convertToGraphQLId('22', 'Ticket'))

      expect(wrapper.getByText('Selected highlight color: Yellow')).toBeInTheDocument()
    })

    it('sr-only description updates when color changes', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlight options' }))
      await wrapper.events.click(wrapper.getByText('Pink'))

      expect(wrapper.getByText('Selected highlight color: Pink')).toBeInTheDocument()
    })

    it('sr-only description reflects inactive state by default', () => {
      const wrapper = renderHighlightMenu()

      expect(wrapper.getByText('Highlighting is inactive.')).toBeInTheDocument()
      expect(
        wrapper.queryByText(
          'Highlighting is active. Select content in the ticket article to apply.',
        ),
      ).not.toBeInTheDocument()
    })

    it('sr-only description reflects active state when highlighter is toggled on', async () => {
      const wrapper = renderHighlightMenu()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Highlighter color: Yellow' }))

      expect(
        wrapper.getByText('Highlighting is active. Select content in the ticket article to apply.'),
      ).toBeInTheDocument()
      expect(wrapper.queryByText('Highlighting is inactive.')).not.toBeInTheDocument()
    })
  })
})
