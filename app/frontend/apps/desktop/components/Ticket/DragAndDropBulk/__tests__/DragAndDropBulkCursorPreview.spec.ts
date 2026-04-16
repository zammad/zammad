// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import { TICKET_BULK_EDIT_SYMBOL } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'

import DragAndDropBulkCursorPreview, { type Props } from '../DragAndDropBulkCursorPreview.vue'

import type { DragPreviewData } from '../types'

const makePreviewData = (overrides: Partial<DragPreviewData> = {}): DragPreviewData => ({
  stateColorCode: EnumTicketStateColorCode.Open,
  columnText: 'Test Ticket Title',
  ...overrides,
})

describe('DragAndDropBulkCursorPreview', () => {
  const cursorPosition = { x: 100, y: 200 }

  const renderPreview = (props: Props, ticketCount = 1) =>
    renderComponent(DragAndDropBulkCursorPreview, {
      props,
      provide: [
        [TICKET_BULK_EDIT_SYMBOL, { currentSelectedTicketCount: computed(() => ticketCount) }],
      ],
    })

  it('renders the first column text from previewData', () => {
    const wrapper = renderPreview({
      cursorPosition,
      previewData: makePreviewData({ columnText: 'Test Ticket Title' }),
    })

    expect(wrapper.getByText('Test Ticket Title')).toBeInTheDocument()
  })

  it('renders an empty preview when previewData is not set', () => {
    const wrapper = renderPreview({
      cursorPosition,
    })

    expect(wrapper.queryByText('Test Ticket Title')).not.toBeInTheDocument()
  })

  it('does not show "+ more" label with a single ticket', () => {
    const wrapper = renderPreview({
      cursorPosition,
      previewData: makePreviewData(),
    })

    expect(wrapper.queryByText(/more/)).not.toBeInTheDocument()
  })

  it('shows "+ N more" label when there are multiple tickets', () => {
    const wrapper = renderPreview(
      {
        cursorPosition,
        previewData: makePreviewData(),
      },
      3,
    )

    expect(wrapper.getByText('+ 2 more')).toBeInTheDocument()
  })

  it('positions the element based on the cursor position', () => {
    const wrapper = renderPreview({
      cursorPosition: { x: 150, y: 300 },
      previewData: makePreviewData(),
    })

    const container = wrapper.baseElement.querySelector('.fixed') as HTMLElement
    expect(container.style.left).toBe('134px')
    expect(container.style.top).toBe('268px')
  })

  it('renders the check-square and check-circle-no icons', () => {
    const wrapper = renderPreview({
      cursorPosition,
      previewData: makePreviewData({ stateColorCode: EnumTicketStateColorCode.Open }),
    })

    expect(wrapper.getByIconName('check-square')).toBeInTheDocument()
    expect(wrapper.getByIconName('check-circle-no')).toBeInTheDocument()
  })

  it('renders state indicator icon based on stateColorCode from previewData', () => {
    const wrapper = renderPreview({
      cursorPosition,
      previewData: makePreviewData({ stateColorCode: EnumTicketStateColorCode.Closed }),
    })

    expect(wrapper.getByIconName('check-circle-outline')).toBeInTheDocument()
  })

  it('does not render state indicator when stateColorCode is null', () => {
    const wrapper = renderPreview({
      cursorPosition,
      previewData: makePreviewData({ stateColorCode: null }),
    })

    expect(wrapper.queryByIconName('check-circle-no')).not.toBeInTheDocument()
  })

  describe('priority icon', () => {
    it('does not render priority icon when ui_ticket_priority_icons is disabled', () => {
      const wrapper = renderPreview({
        cursorPosition,
        previewData: makePreviewData({ priorityUiColor: 'high-priority' }),
      })

      expect(wrapper.queryByIconName('priority-high-micro-2')).not.toBeInTheDocument()
      expect(wrapper.queryByIconName('priority-normal-micro-2')).not.toBeInTheDocument()
    })

    it('renders priority icon when ui_ticket_priority_icons is enabled', () => {
      mockApplicationConfig({ ui_ticket_priority_icons: true })

      const wrapper = renderPreview({
        cursorPosition,
        previewData: makePreviewData({ priorityUiColor: 'high-priority' }),
      })

      expect(wrapper.getByIconName('priority-high-micro-2')).toBeInTheDocument()
    })

    it('renders default priority icon when priorityUiColor is null', () => {
      mockApplicationConfig({ ui_ticket_priority_icons: true })

      const wrapper = renderPreview({
        cursorPosition,
        previewData: makePreviewData({ priorityUiColor: null }),
      })

      expect(wrapper.getByIconName('priority-normal-micro-2')).toBeInTheDocument()
    })
  })

  describe('stack layers', () => {
    it('renders no stack layers for a single ticket', () => {
      const view = renderPreview(
        {
          cursorPosition,
          previewData: makePreviewData(),
        },
        1,
      )

      expect(view.queryByTestId('2')).not.toBeInTheDocument()
      expect(view.queryByTestId('3')).not.toBeInTheDocument()
    })

    it('renders one stack layer for two tickets', () => {
      const view = renderPreview(
        {
          cursorPosition,
          previewData: makePreviewData(),
        },
        2,
      )

      expect(view.queryByTestId('2')).toBeInTheDocument()
      expect(view.queryByTestId('3')).not.toBeInTheDocument()
    })

    it('renders two stack layers for three or more tickets', () => {
      const view = renderPreview(
        {
          cursorPosition,
          previewData: makePreviewData(),
        },
        3,
      )

      expect(view.queryByTestId('2')).toBeInTheDocument()
      expect(view.queryByTestId('3')).toBeInTheDocument()
    })
  })
})
