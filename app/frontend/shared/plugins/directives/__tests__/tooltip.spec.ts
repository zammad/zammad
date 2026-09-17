// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent, waitFor } from '@testing-library/vue'
import { describe, vi } from 'vitest'
import { nextTick, ref } from 'vue'

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
      vi.useFakeTimers()

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
      vi.advanceTimersByTime(350)

      expect(wrapper.queryByRole('tooltip', { hidden: true })).not.toBeInTheDocument()

      vi.useRealTimers()
    })
  })

  describe('supportive modifier', () => {
    it('exposes the message via aria-description instead of aria-label', async () => {
      const wrapper = renderComponent({
        template: `
          <div v-tooltip.supportive="'Hello, Tooltip'">Foo Test World</div>
        `,
      })

      const target = wrapper.getByText('Foo Test World')

      expect(target).not.toHaveAttribute('aria-label')
      expect(target).toHaveAttribute('aria-description', 'Hello, Tooltip')

      await wrapper.events.hover(target)

      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).toBeInTheDocument())

      // The message is a description, not an accessible name/label.
      expect(wrapper.queryByLabelText('Hello, Tooltip')).not.toBeInTheDocument()
    })
  })

  describe('clearing the message', () => {
    it('removes the tooltip when the message becomes empty', async () => {
      const message = ref<string | undefined>('Hello, Tooltip')

      const wrapper = renderComponent({
        template: `<div v-tooltip="message">Foo Test World</div>`,
        setup: () => ({ message }),
      })

      const target = wrapper.getByText('Foo Test World')

      expect(target).toHaveAttribute('aria-label', 'Hello, Tooltip')
      expect(target).toHaveAttribute('data-tooltip', 'true')

      message.value = undefined
      await nextTick()

      expect(target).not.toHaveAttribute('aria-label')
      expect(target).not.toHaveAttribute('data-tooltip')

      message.value = 'Hello again, Tooltip'
      await nextTick()

      expect(target).toHaveAttribute('aria-label', 'Hello again, Tooltip')
      expect(target).toHaveAttribute('data-tooltip', 'true')
    })

    it('does not show the old message on hover after it was cleared', async () => {
      const message = ref<string | undefined>('Hello, Tooltip')

      const wrapper = renderComponent({
        template: `<div v-tooltip="message">Foo Test World</div>`,
        setup: () => ({ message }),
      })

      const target = wrapper.getByText('Foo Test World')

      await wrapper.events.hover(target)
      await waitFor(() => expect(wrapper.queryByText('Hello, Tooltip')).toBeInTheDocument())
      await wrapper.events.unhover(target)

      message.value = undefined
      await nextTick()

      vi.useFakeTimers()
      await wrapper.events.hover(target)

      // Give the 300ms tooltip delay a chance to fire without actually showing.
      vi.advanceTimersByTime(350)

      expect(wrapper.queryByText('Hello, Tooltip')).not.toBeInTheDocument()

      vi.useRealTimers()
    })

    it('treats an empty string as no tooltip', async () => {
      const message = ref('Hello, Tooltip')

      const wrapper = renderComponent({
        template: `<div v-tooltip="message">Foo Test World</div>`,
        setup: () => ({ message }),
      })

      message.value = ''
      await nextTick()

      const target = wrapper.getByText('Foo Test World')

      expect(target).not.toHaveAttribute('aria-label')
      expect(target).not.toHaveAttribute('data-tooltip')
    })

    it('keeps a message attribute it did not set itself', () => {
      const wrapper = renderComponent({
        template: `<div v-tooltip="undefined" aria-label="Remove image">Foo Test World</div>`,
      })

      expect(wrapper.getByText('Foo Test World')).toHaveAttribute('aria-label', 'Remove image')
    })

    it('keeps a message attribute that a binding set to the same value', async () => {
      const message = ref<string | undefined>('Remove image')
      const label = ref('Remove image')

      const wrapper = renderComponent({
        template: `<div v-tooltip="message" :aria-label="label">Foo Test World</div>`,
        setup: () => ({ message, label }),
      })

      const target = wrapper.getByText('Foo Test World')

      expect(target).toHaveAttribute('aria-label', 'Remove image')

      message.value = undefined
      await nextTick()

      // The binding still provides the accessible name, only the tooltip is gone.
      expect(target).toHaveAttribute('aria-label', 'Remove image')
      expect(target).not.toHaveAttribute('data-tooltip')
    })

    it('stops showing a tooltip when another binding replaced its message', async () => {
      const message = ref<string | undefined>('Hello, Tooltip')
      const label = ref<string | undefined>()

      const wrapper = renderComponent({
        template: `<div v-tooltip="message" :aria-label="label">Foo Test World</div>`,
        setup: () => ({ message, label }),
      })

      const target = wrapper.getByText('Foo Test World')

      expect(target).toHaveAttribute('aria-label', 'Hello, Tooltip')

      message.value = undefined
      label.value = 'Remove image'
      await nextTick()

      expect(target).toHaveAttribute('aria-label', 'Remove image')
      expect(target).not.toHaveAttribute('data-tooltip')

      vi.useFakeTimers()
      await wrapper.events.hover(target)

      // Give the 300ms tooltip delay a chance to fire without actually showing.
      vi.advanceTimersByTime(350)

      expect(wrapper.queryByRole('tooltip', { hidden: true })).not.toBeInTheDocument()

      vi.useRealTimers()
    })

    it('clears the supportive message from aria-description', async () => {
      const message = ref<string | undefined>('Hello, Tooltip')

      const wrapper = renderComponent({
        template: `<div v-tooltip.supportive="message">Foo Test World</div>`,
        setup: () => ({ message }),
      })

      const target = wrapper.getByText('Foo Test World')

      expect(target).toHaveAttribute('aria-description', 'Hello, Tooltip')

      message.value = undefined
      await nextTick()

      expect(target).not.toHaveAttribute('aria-description')
      expect(target).not.toHaveAttribute('data-tooltip')
    })
  })
})
