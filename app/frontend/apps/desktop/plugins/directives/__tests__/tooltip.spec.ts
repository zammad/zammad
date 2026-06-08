// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent, waitFor } from '@testing-library/vue'
import { describe, vi } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockLocale } from '#tests/support/mock-locale.ts'

vi.mock('#shared/composables/useTouchDevice.ts', () => ({
  useTouchDevice: vi.fn().mockReturnValue({ isTouchDevice: { value: true } }),
}))

describe('TooltipDirective', () => {
  describe('on non-touch device', () => {
    it('should show/hide tooltip on hover', async () => {
      const wrapper = renderComponent({
        template: `
          <div v-tooltip="'Hello, Tooltip'">Foo Test World</div>
         `,
      })

      await wrapper.events.hover(wrapper.getByText('Foo Test World'))

      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).toBeInTheDocument())

      await wrapper.events.unhover(wrapper.getByText('Foo Test World'))

      await waitFor(() => {
        expect(wrapper.queryByText('Hello, Tooltip')).not.toBeInTheDocument()
      })
    })

    it('has accessibility attribute', async () => {
      const wrapper = renderComponent({
        template: `
        <div v-tooltip="'Hello, Tooltip'">Foo Test World</div>
      `,
      })
      await waitFor(() => expect(wrapper.queryByLabelText('Hello, Tooltip')).toBeInTheDocument())
    })

    it('should hide tooltip on scroll', async () => {
      const wrapper = renderComponent({
        template: `
        <div v-tooltip="'Hello, Tooltip'">Foo Test World</div>
      `,
      })

      await wrapper.events.hover(wrapper.getByText('Foo Test World'))

      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).toBeInTheDocument())

      window.dispatchEvent(new Event('scroll'))

      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).not.toBeInTheDocument())
    })
  })

  describe('on touch device', () => {
    it('should hide tooltip on first touch', async () => {
      const wrapper = renderComponent({
        template: `
        <div v-tooltip="'Hello, Tooltip'">Foo Test World</div>
      `,
      })

      await fireEvent.touchStart(wrapper.getByText('Foo Test World'))

      await waitFor(() => {
        expect(wrapper.queryByText('Hello, Tooltip')).toBeInTheDocument()
      })

      await fireEvent.touchStart(wrapper.getByText('Foo Test World'))
      await fireEvent.touchEnd(wrapper.getByText('Foo Test World'))

      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).not.toBeInTheDocument())
    })

    it('updated tooltip locale', async () => {
      const translationSpy = mockLocale('Hello, Tooltip', 'Hola, Tooltip')

      const wrapper = renderComponent({
        template: `
      <div v-tooltip="$t('Hello, Tooltip')">Foo Test World</div>
    `,
      })

      await wrapper.events.hover(wrapper.getByText('Foo Test World'))

      await waitFor(() => {
        expect(wrapper.queryByText('Hola, Tooltip')).toBeInTheDocument()
        expect(wrapper.getByLabelText('Hola, Tooltip')).toBeInTheDocument()
      })

      expect(translationSpy).toHaveBeenCalledOnce()
    })
  })

  describe('truncate modifier', () => {
    it('shows tooltip when the element itself is truncated', async () => {
      const wrapper = renderComponent({
        template: `
          <div style="width: 50px; display: flex;">
            <span v-tooltip.truncate="'Full text content'" class="truncate">Full text content</span>
          </div>
        `,
      })

      const target = wrapper.getByText('Full text content')
      Object.defineProperty(target, 'offsetWidth', { configurable: true, value: 50 })
      Object.defineProperty(target, 'scrollWidth', { configurable: true, value: 200 })

      await wrapper.events.hover(target)

      await waitFor(() => {
        expect(wrapper.queryByRole('tooltip', { hidden: true })).toBeInTheDocument()
      })
    })

    it('does not show tooltip when the element is not truncated', async () => {
      const wrapper = renderComponent({
        template: `
          <div style="width: 300px; display: flex;">
            <span v-tooltip.truncate="'Short'" class="truncate">Short</span>
          </div>
        `,
      })

      const target = wrapper.getByText('Short')
      Object.defineProperty(target, 'offsetWidth', { configurable: true, value: 50 })
      Object.defineProperty(target, 'scrollWidth', { configurable: true, value: 50 })
      const { parentElement } = target
      Object.defineProperty(parentElement, 'offsetWidth', { configurable: true, value: 300 })
      Object.defineProperty(parentElement, 'scrollWidth', { configurable: true, value: 300 })

      await wrapper.events.hover(target)

      // Give the 300ms tooltip delay a chance to fire without actually showing.
      await new Promise((resolve) => setTimeout(resolve, 350))

      expect(wrapper.queryByRole('tooltip', { hidden: true })).not.toBeInTheDocument()
    })
  })
})
