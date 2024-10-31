// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { useBubbleHeader } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleHeader.ts'

describe('useBubbleHeader', () => {
  it('should toggle showMetaInformation', async () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    expect(showMetaInformation.value).toBe(false)

    const event = new MouseEvent('click')

    Object.defineProperty(event, 'target', {
      value: document.createElement('div'),
      writable: false,
    })

    toggleHeader(event)

    await waitFor(() => expect(showMetaInformation.value).toBe(true))

    toggleHeader(event)

    await waitFor(() => expect(showMetaInformation.value).toBe(false))
  })

  it.each(['a', 'button', 'button>span'])(
    'should not toggle if clicked node is a %s',
    (tagName) => {
      const { showMetaInformation, toggleHeader } = useBubbleHeader()

      // Split tagName by '>' to handle nested elements like 'button>span'
      const tags = tagName.split('>')
      let element: HTMLElement

      if (tags.length > 1) {
        // For nested elements, create parent and child elements accordingly
        element = document.createElement(tags[0])
        const childElement = document.createElement(tags[1])
        element.appendChild(childElement)
      } else {
        element = document.createElement(tagName)
      }

      const event = new MouseEvent('click')

      Object.defineProperty(event, 'target', {
        value: element,
        writable: false,
      })

      expect(showMetaInformation.value).toBe(false)

      toggleHeader(event)

      expect(showMetaInformation.value).toBe(false)
    },
  )
})
