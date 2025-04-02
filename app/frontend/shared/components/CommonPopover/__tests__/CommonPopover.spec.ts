// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPopover from '../CommonPopover.vue'
import { usePopover } from '../usePopover.ts'

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
    const view = renderComponent(CommonPopover, {
      props: {
        owner: null,
      },
      slots: {
        default: 'Example Content',
      },
    })

    expect(view.queryByText('Example Content')).not.toBeInTheDocument()
  })

  it('does toggle popover when target was clicked', async () => {
    const view = renderPopover()

    await view.events.click(view.getByText('Click me'))

    expect(view.getByText('Example Content')).toBeInTheDocument()

    await view.events.click(view.getByText('Click me'))

    expect(view.queryByText('Example Content')).not.toBeInTheDocument()
  })
})
