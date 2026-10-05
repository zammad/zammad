// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useBubbleHeader } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleHeader.ts'

const isActive = vi.hoisted(() => vi.fn())

vi.mock(
  '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/composables/useHighlightMenuState.ts',
  () => ({
    useHighlightMenuState: () => ({
      isActive: {
        get value() {
          return isActive()
        },
      },
    }),
  }),
)

const createClickEvent = (detail = 1, target: HTMLElement = document.createElement('div')) => {
  const event = new MouseEvent('click', { detail })

  Object.defineProperty(event, 'target', {
    value: target,
    writable: false,
  })

  return event
}

const getSelection = vi.spyOn(window, 'getSelection')

const mockSelectionType = (type: string) => getSelection.mockReturnValue({ type } as Selection)

describe('useBubbleHeader', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    isActive.mockReset()
    isActive.mockReturnValue(false)
  })

  afterEach(() => {
    vi.useRealTimers()
    getSelection.mockReset()
  })

  it('should toggle showMetaInformation after the double-click delay', () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    expect(showMetaInformation.value).toBe(false)

    toggleHeader(createClickEvent())

    vi.advanceTimersByTime(499)

    expect(showMetaInformation.value).toBe(false)

    vi.advanceTimersByTime(1)

    expect(showMetaInformation.value).toBe(true)

    toggleHeader(createClickEvent())

    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(false)
  })

  it('should not toggle on a double-click within the delay', () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent(1))

    vi.advanceTimersByTime(300)

    toggleHeader(createClickEvent(2))

    vi.advanceTimersByTime(1000)

    expect(showMetaInformation.value).toBe(false)
  })

  it('should revert the toggle on a double-click slower than the delay', () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent(1))

    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(true)

    toggleHeader(createClickEvent(2))

    expect(showMetaInformation.value).toBe(false)
  })

  it('should not toggle on a triple-click', () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent(1))
    vi.advanceTimersByTime(100)
    toggleHeader(createClickEvent(2))
    vi.advanceTimersByTime(100)
    toggleHeader(createClickEvent(3))

    vi.advanceTimersByTime(1000)

    expect(showMetaInformation.value).toBe(false)
  })

  it('should not revert an earlier single click on a later double-click', () => {
    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent(1))
    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(true)

    vi.advanceTimersByTime(5000)

    toggleHeader(createClickEvent(1))
    vi.advanceTimersByTime(100)
    toggleHeader(createClickEvent(2))

    vi.advanceTimersByTime(1000)

    expect(showMetaInformation.value).toBe(true)
  })

  it('should not toggle when text is selected by the click', () => {
    mockSelectionType('Range')

    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent())

    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(false)
  })

  it('should not toggle when text gets selected before the delay ends', () => {
    mockSelectionType('Caret')

    const { showMetaInformation, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent())

    mockSelectionType('Range')

    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(false)
  })

  it('should not toggle when highlight is active', () => {
    isActive.mockReturnValue(true)

    const { showMetaInformation, toggle, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent())
    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(false)

    toggle()

    expect(showMetaInformation.value).toBe(false)
  })

  it('should toggle immediately without a click', () => {
    const { showMetaInformation, toggle } = useBubbleHeader()

    toggle()

    expect(showMetaInformation.value).toBe(true)

    toggle()

    expect(showMetaInformation.value).toBe(false)
  })

  it('should cancel a pending click toggle on a keyboard toggle', () => {
    const { showMetaInformation, toggle, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent())
    vi.advanceTimersByTime(300)

    toggle()

    expect(showMetaInformation.value).toBe(true)

    vi.advanceTimersByTime(1000)

    expect(showMetaInformation.value).toBe(true)
  })

  it('should not revert a keyboard toggle on a later double-click', () => {
    const { showMetaInformation, toggle, toggleHeader } = useBubbleHeader()

    toggleHeader(createClickEvent(1))
    vi.advanceTimersByTime(500)

    expect(showMetaInformation.value).toBe(true)

    toggle()

    expect(showMetaInformation.value).toBe(false)

    toggleHeader(createClickEvent(2))

    expect(showMetaInformation.value).toBe(false)
  })

  it.each(['a', 'button', 'button>span'])(
    'should not toggle if clicked node is a %s',
    (tagName) => {
      const { showMetaInformation, toggleHeader } = useBubbleHeader()

      const [parentTag, childTag] = tagName.split('>')
      const parent = document.createElement(parentTag)
      let target = parent

      if (childTag) {
        target = document.createElement(childTag)
        parent.appendChild(target)
      }

      toggleHeader(createClickEvent(1, target))
      vi.advanceTimersByTime(500)

      expect(showMetaInformation.value).toBe(false)
    },
  )
})
