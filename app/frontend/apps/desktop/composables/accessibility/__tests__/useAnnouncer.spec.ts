// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

describe('useAnnouncer', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    document.body.innerHTML = ''
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  const renderDummyComponent = () => {
    const announceFn = vi.fn()
    const nodeId = vi.fn()

    const wrapper = renderComponent({
      template: '<div></div>',
      setup() {
        const { announce, messageNodeId } = useAnnouncer()
        announceFn.mockImplementation(announce)
        nodeId.mockReturnValue(messageNodeId)
        return {}
      },
    })

    return { wrapper, nodeId, announceFn }
  }

  it('creates a live region on first use', async () => {
    const { wrapper, nodeId } = renderDummyComponent()

    const liveRegion = wrapper.getByRole('status')
    expect(liveRegion.getAttribute('aria-live')).toBe('polite')
    expect(liveRegion.getAttribute('aria-relevant')).toBe('additions text')
    expect(liveRegion.getAttribute('aria-atomic')).toBe('true')
    expect(liveRegion.className).toContain('sr-only')

    expect(wrapper.getByTestId(nodeId())).toBeInTheDocument()
  })

  it('keeps a single live region across consumers', async () => {
    renderDummyComponent()
    renderDummyComponent()

    expect(document.querySelectorAll('[role="status"]')).toHaveLength(1)
  })

  it('announces messages', async () => {
    const { wrapper, announceFn, nodeId } = renderDummyComponent()

    const messageNode = wrapper.getByTestId(nodeId())

    announceFn('Hello world')
    vi.runAllTimers()
    expect(messageNode).toHaveTextContent('Hello world')

    announceFn('Second')
    vi.runAllTimers()
    expect(messageNode).toHaveTextContent('Second')
  })

  it('re-announces an identical message by clearing the region first', async () => {
    const { wrapper, announceFn, nodeId } = renderDummyComponent()

    const messageNode = wrapper.getByTestId(nodeId())

    announceFn('Same message')
    vi.runAllTimers()
    expect(messageNode).toHaveTextContent('Same message')

    announceFn('Same message')
    expect(messageNode).toBeEmptyDOMElement()

    vi.runAllTimers()
    expect(messageNode).toHaveTextContent('Same message')
  })

  it('announces only the latest of several rapid messages', async () => {
    const { wrapper, announceFn, nodeId } = renderDummyComponent()

    const messageNode = wrapper.getByTestId(nodeId())

    announceFn('First')
    announceFn('Second')
    announceFn('Third')

    vi.runAllTimers()
    expect(messageNode).toHaveTextContent('Third')
  })

  it('rebuilds the live region when it was removed from the document', async () => {
    const { announceFn } = renderDummyComponent()

    document.body.innerHTML = ''

    announceFn('After teardown')
    vi.runAllTimers()

    expect(document.getElementById('announcer-message')).toHaveTextContent('After teardown')
    expect(document.querySelectorAll('[role="status"]')).toHaveLength(1)
  })
})
