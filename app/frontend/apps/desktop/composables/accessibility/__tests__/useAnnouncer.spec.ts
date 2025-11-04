// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

describe('useAnnouncer', () => {
  beforeEach(() => {
    vi.useFakeTimers()
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
    expect(liveRegion!.getAttribute('aria-live')).toBe('polite')
    expect(liveRegion!.getAttribute('aria-relevant')).toBe('text')
    expect(liveRegion!.className).toContain('sr-only')
    expect(liveRegion!.className).toContain('invisible')

    expect(wrapper.getByTestId(nodeId)).toBeInTheDocument()
  })

  it('announces messages', async () => {
    const { wrapper, announceFn, nodeId } = renderDummyComponent()

    announceFn('Hello world')

    const messageNode = wrapper.getByTestId(nodeId)
    expect(messageNode).toHaveTextContent('Hello world')

    expect(messageNode).toHaveTextContent('Hello world')

    announceFn('Second')
    expect(messageNode).toHaveTextContent('Second')
  })
})
