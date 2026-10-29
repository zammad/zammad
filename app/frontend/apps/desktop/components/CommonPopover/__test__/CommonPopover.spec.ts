// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPopover from '../CommonPopover.vue'
import { usePopover } from '../usePopover.ts'

const isSmallScreen = ref(false)

vi.mock('#desktop/composables/responsiveness/useAppBreakpoints.ts', () => ({
  useAppBreakpoints: () => ({
    isSmallScreen,
  }),
}))

const html = String.raw

const renderPopover = () => {
  const wrapper = renderComponent({
    components: { CommonPopover },
    template: html`
      <CommonPopover ref="popover" :owner="popoverTarget"
        ><span>Example Content</span></CommonPopover
      >
      <button ref="popoverTarget" @click="toggle">Click me</button>
    `,
    setup() {
      const { popover, popoverTarget, toggle } = usePopover()

      return {
        toggle,
        popover,
        popoverTarget,
      }
    },
  })

  return wrapper
}

describe('CommonPopover.vue', () => {
  it('does not render when popover is not open', () => {
    const wrapper = renderComponent(CommonPopover, {
      props: {
        owner: null,
      },
      slots: {
        default: 'Example Content',
      },
    })

    expect(wrapper.queryByText('Example Content')).not.toBeInTheDocument()
  })

  it('does toggle popover when target was clicked', async () => {
    const wrapper = renderPopover()

    await wrapper.events.click(wrapper.getByText('Click me'))

    expect(await wrapper.findByText('Example Content')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('Click me'))

    expect(wrapper.queryByText('Example Content')).not.toBeInTheDocument()
  })

  it('ignores horizontal orientation on small screens and falls back to vertical orientation', async () => {
    isSmallScreen.value = false

    const renderPopoverWithOrientation = () => {
      return renderComponent({
        components: { CommonPopover },
        template: html`
          <CommonPopover ref="popover" :owner="popoverTarget" orientation="right"
            ><span>Example Content</span></CommonPopover
          >
          <button ref="popoverTarget" @click="toggle">Click me</button>
        `,
        setup() {
          const { popover, popoverTarget, toggle } = usePopover()
          return { toggle, popover, popoverTarget }
        },
      })
    }

    const wrapper = renderPopoverWithOrientation()

    // Check with isSmallScreen = false (should use horizontal orientation 'right')
    await wrapper.events.click(wrapper.getByText('Click me'))
    let popoverElement = wrapper.getByRole('region')
    expect(popoverElement).toHaveStyle({
      top: '-28px',
      left: '16px',
    })

    // Close the popover
    await wrapper.events.click(wrapper.getByText('Click me'))

    // Check with isSmallScreen = true (should fall back to vertical orientation 'autoVertical')
    isSmallScreen.value = true
    await wrapper.events.click(wrapper.getByText('Click me'))
    popoverElement = wrapper.getByRole('region')
    expect(popoverElement).toHaveStyle({
      left: '-2px',
      top: '16px',
    })
  })

  describe('wide', () => {
    const renderWidePopover = (props: Record<string, unknown>) =>
      renderComponent({
        components: { CommonPopover },
        template: html`
          <CommonPopover ref="popover" :owner="popoverTarget" v-bind="props"
            ><span>Example Content</span></CommonPopover
          >
          <button ref="popoverTarget" @click="toggle">Click me</button>
        `,
        setup() {
          const { popover, popoverTarget, toggle } = usePopover()
          return { toggle, popover, popoverTarget, props }
        },
      })

    const openWithOwnerAt = async (
      props: Record<string, unknown>,
      bounds: { left: number; right: number },
    ) => {
      isSmallScreen.value = false

      const wrapper = renderWidePopover(props)
      const owner = wrapper.getByText('Click me')

      vi.spyOn(owner, 'getBoundingClientRect').mockReturnValue(
        DOMRect.fromRect({ x: bounds.left, y: 100, width: bounds.right - bounds.left, height: 20 }),
      )

      await wrapper.events.click(owner)

      return wrapper
    }

    it('keeps the regular width without the wide prop', async () => {
      const wrapper = await openWithOwnerAt({ orientation: 'right' }, { left: 100, right: 200 })

      expect(wrapper.getByRole('region').style.maxWidth).toBe('')
      expect(wrapper.getByText('Example Content').parentElement).toHaveClass('max-w-md')
    })

    it.each([
      {
        case: 'right',
        props: { orientation: 'right' },
        bounds: { left: 100, right: 200 },
        maxWidth: '800px',
      },
      {
        case: 'left',
        props: { orientation: 'left' },
        bounds: { left: 700, right: 800 },
        maxWidth: '676px',
      },
      {
        case: 'below, start',
        props: { orientation: 'bottom', placement: 'start' },
        bounds: { left: 100, right: 200 },
        maxWidth: '916px',
      },
      {
        case: 'below, end',
        props: { orientation: 'bottom', placement: 'end' },
        bounds: { left: 800, right: 900 },
        maxWidth: '892px',
      },
      {
        case: 'too little space',
        props: { orientation: 'right' },
        bounds: { left: 700, right: 800 },
        maxWidth: '',
      },
      {
        case: 'arrow placement',
        props: { orientation: 'bottom', placement: 'arrowStart' },
        bounds: { left: 100, right: 200 },
        maxWidth: '',
      },
    ])(
      'limits the width to the space next to the owner ($case)',
      async ({ props, bounds, maxWidth }) => {
        const wrapper = await openWithOwnerAt({ ...props, wide: true }, bounds)

        expect(wrapper.getByRole('region').style.maxWidth).toBe(maxWidth)
        expect(wrapper.getByText('Example Content').parentElement).toHaveClass('max-w-3xl')
      },
    )
  })
})
