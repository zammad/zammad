// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { afterEach, expect } from 'vitest'

const html = String.raw

describe('CommonOverlayContainer', () => {
  let main: HTMLElement
  let wrapper: ReturnType<typeof renderComponent>

  beforeEach(() => {
    main = document.createElement('main')
    main.id = 'page-main-content'
    document.body.appendChild(main)
    wrapper = renderComponent(CommonOverlayContainer, {
      props: { tag: 'div' },
      attachTo: main,
    })
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('renders correctly with a11y specification', async () => {
    expect(wrapper.getByRole('dialog')).toBeInTheDocument()
    expect(main.querySelector('[role=presentation]')).toBeInTheDocument()

    await wrapper.rerender({ tag: 'aside' })

    expect(wrapper.getByRole('complementary')).toBeInTheDocument()
  })

  it('hides background when showBackdrop is false', async () => {
    await wrapper.rerender({ showBackdrop: false })
    expect(main.querySelector('[role=presentation]')).not.toBeInTheDocument()
  })

  it('should emit close event when backdrop is clicked', async () => {
    const view = renderComponent({
      template: html`<div id="test-backdrop"></div>`,
    })

    const dialog = renderComponent(CommonOverlayContainer, {
      props: {
        tag: 'div',
        teleportTo: '#test-backdrop',
        noCloseOnBackdropClick: true,
      },
    })

    await view.events.click(
      view
        .getAllByRole('presentation', {
          hidden: true,
        })
        .at(-1) as HTMLElement,
    )

    expect(dialog.emitted('click-background')).toHaveLength(1)
  })
})
