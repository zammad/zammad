// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { h } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'

import CommonPopoverMenu from '../CommonPopoverMenu.vue'

import type { MenuItem } from '../types.ts'

const html = String.raw
const fn = vi.fn()

describe('rendering section', () => {
  it('no output without default slot and items', () => {
    const view = renderComponent(CommonPopoverMenu, {
      props: {
        popover: null,
        headerLabel: 'Test Header',
      },
      router: true,
    })

    expect(view.queryByText('Test Header')).not.toBeInTheDocument()
  })

  it('if have header prop, renders header', () => {
    const view = renderComponent(CommonPopoverMenu, {
      props: {
        popover: null,
        headerLabel: 'Test Header',
        items: [
          {
            label: 'Example',
          },
        ],
      },
      router: true,
      store: true,
    })

    expect(view.getByText('Test Header')).toBeInTheDocument()
  })

  it('if have header slot, renders header', () => {
    const view = renderComponent(CommonPopoverMenu, {
      props: {
        popover: null,
      },
      slots: {
        header: '<div>Test Header</div>',
        default: 'Example',
      },
      router: true,
    })

    expect(view.getByText('Test Header')).toBeInTheDocument()
  })

  it('rendering items', () => {
    const items: MenuItem[] = [
      { key: 'login', link: '/login', label: 'Login' },
      { key: 'dashboard', link: '/', label: 'Link' },
    ]

    const view = renderComponent(CommonPopoverMenu, {
      shallow: false,
      props: {
        popover: null,
        items,
      },
      router: true,
    })

    expect(view.getByText('Login')).toBeInTheDocument()
    expect(view.getByText('Link')).toBeInTheDocument()
  })

  it('rendering only items with permission', () => {
    const items: MenuItem[] = [
      { key: 'login', link: '/login', label: 'Login' },
      { key: 'dashboard', link: '/', label: 'Link', permission: ['example'] },
    ]

    const view = renderComponent(CommonPopoverMenu, {
      shallow: false,
      props: {
        popover: null,
        items,
      },
      router: true,
    })

    expect(view.getByText('Login')).toBeInTheDocument()
    expect(view.queryByText('Link')).not.toBeInTheDocument()
  })

  it('support click handler on item', async () => {
    const clickHandler = vi.fn()

    const items: MenuItem[] = [
      { key: 'example', onClick: clickHandler, label: 'Example' },
    ]

    const view = renderComponent(CommonPopoverMenu, {
      shallow: false,
      props: {
        popover: null,
        items,
      },
      router: true,
    })

    await view.events.click(view.getByText('Example'))

    expect(clickHandler).toHaveBeenCalledOnce()
  })

  it('close popover on click on item or avoid closing', async () => {
    const clickHandlerExample = vi.fn()
    const clickHandlerOther = vi.fn()

    const view = renderComponent({
      components: { CommonPopover, CommonPopoverMenu },
      template: html`
        <CommonPopover ref="popover" :owner="popoverTarget"
          ><CommonPopoverMenu :popover="popover" :items="items"
        /></CommonPopover>
        <button ref="popoverTarget" @click="toggle">Click me</button>
      `,
      setup() {
        const { popover, popoverTarget, toggle } = usePopover()

        const items: MenuItem[] = [
          { key: 'example', onClick: clickHandlerExample, label: 'Example' },
          {
            key: 'other',
            onClick: clickHandlerOther,
            label: 'Other',
            noCloseOnClick: true,
          },
        ]

        return {
          items,
          toggle,
          popover,
          popoverTarget,
        }
      },
    })

    await view.events.click(view.getByText('Click me'))

    expect(view.queryByText('Example')).toBeInTheDocument()

    await view.events.click(view.getByText('Example'))
    expect(clickHandlerExample).toHaveBeenCalledOnce()

    expect(view.queryByText('Example')).not.toBeInTheDocument()

    await view.events.click(view.getByText('Click me'))

    await view.events.click(view.getByText('Other'))
    expect(clickHandlerOther).toHaveBeenCalledOnce()

    expect(view.queryByText('Other')).toBeInTheDocument()
  })

  it('can use an own component for item rendering', async () => {
    const CustomComponent = (props: any) => {
      return h('div', `Example ${props.label}`)
    }
    CustomComponent.props = ['label']

    const items: MenuItem[] = [
      { key: 'menu-item', component: CustomComponent, label: 'Menu item' },
    ]

    const view = renderComponent(CommonPopoverMenu, {
      shallow: false,
      props: {
        popover: null,
        items,
      },
      router: true,
    })

    expect(view.getByText('Example Menu item')).toBeInTheDocument()
  })

  it('yields entity data on show if prop is passed', async () => {
    renderComponent(CommonPopoverMenu, {
      props: {
        popover: null,
        headerLabel: 'Test Header',
        entity: {
          id: 'example',
          name: 'vitest',
        },
        items: [
          {
            label: 'Example',
            show: (event: { id: string; name: string }) => {
              fn(event)
              return true
            },
          },
        ],
      },
      router: true,
      store: true,
    })

    expect(fn).toBeCalledWith({ id: 'example', name: 'vitest' })
  })
})
