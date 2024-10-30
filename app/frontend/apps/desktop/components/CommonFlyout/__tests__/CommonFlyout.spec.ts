// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect } from 'vitest'
import { nextTick } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'

const html = String.raw

describe('CommonFlyout', () => {
  describe('standalone component', () => {
    let flyout: ReturnType<typeof renderComponent>

    beforeEach(() => {
      flyout = renderComponent(CommonFlyout, {
        props: {
          name: 'test-identifier',
          headerTitle: 'Test Title',
          headerIcon: 'buildings',
          showBackdrop: false,
        },
      })
    })

    it('renders the correct title', async () => {
      expect(flyout.getByText('Test Title')).toBeInTheDocument()
    })

    it('renders the correct icon', async () => {
      expect(flyout.queryByIconName('buildings')).toBeInTheDocument()
    })

    it('renders a default submit label', async () => {
      expect(flyout.getByText('Update')).toBeInTheDocument()
    })

    it('renders a custom submit label', async () => {
      await flyout.rerender({
        footerActionOptions: {
          actionLabel: 'Submit',
        },
      })
      expect(flyout.getByText('Submit')).toBeInTheDocument()
    })

    it('renders a default cancel label', () => {
      expect(flyout.getByText('Cancel & Go Back')).toBeInTheDocument()
    })

    it('renders a custom cancel label', async () => {
      await flyout.rerender({
        footerActionOptions: {
          cancelLabel: 'Exit',
        },
      })
      expect(flyout.getByText('Exit')).toBeInTheDocument()
    })

    it('renders the resize handle as a default', () => {
      expect(flyout.queryByLabelText('Resize side panel')).toBeInTheDocument()
    })

    it('does not render the resize handle when allowResizing is false', async () => {
      await flyout.rerender({
        resizable: false,
      })

      expect(
        flyout.queryByLabelText('Resize side panel'),
      ).not.toBeInTheDocument()
    })

    it('renders slot content', async () => {
      const flyout = renderComponent(CommonFlyout, {
        props: {
          name: 'test-identifier',
          label: 'Test',
          headerTitle: 'Test Title',
          titleIcon: 'buildings',
          showBackdrop: false,
        },
        slots: {
          header: 'Foo header',
          default: 'Hello world!',
          footer: 'Foo submit',
        },
      })

      expect(flyout.getByText('Hello world!')).toBeInTheDocument()
      expect(flyout.getByText('Foo header')).toBeInTheDocument()
      expect(flyout.getByText('Foo submit')).toBeInTheDocument()
    })

    it('focuses the first focusable element when opened', async () => {
      const flyout = renderComponent(CommonFlyout, {
        props: {
          headerTitle: 'Test Title',
          name: 'test-identifier',
          showBackdrop: false,
        },
        slots: {
          default: html`<input
            type="text"
            placeholder="test"
            name="test-input"
          />`,
        },
      })

      await nextTick()

      expect(flyout.getByPlaceholderText('test')).toHaveFocus()
    })

    it('has a default container width of 500px', async () => {
      expect(flyout.getByRole('complementary')).toHaveStyle({
        width: '500px',
      })
    })

    describe('events', () => {
      it('emits close event when cancel button is clicked', async () => {
        await flyout.events.click(flyout.getByText('Cancel & Go Back'))

        expect(flyout.emitted('close')).toHaveLength(1)
      })

      it('emits close event when x button is clicked', async () => {
        await flyout.events.click(
          flyout.getAllByLabelText('Close side panel').at(-1) as HTMLElement,
        )

        expect(flyout.emitted('close')).toHaveLength(1)
      })

      it('emits close event when escape key is pressed, by default', async () => {
        await flyout.events.keyboard('{Escape}')

        expect(flyout.emitted('close')).toHaveLength(1)
      })

      it('emits close event when escape key is pressed, if specified', async () => {
        await flyout.rerender({ noCloseOnEscape: true })

        await flyout.events.keyboard('{Escape}')

        expect(flyout.emitted('close')).toBeUndefined()
      })

      it('emits event when action button is clicked', async () => {
        await flyout.events.click(flyout.getByText('Update'))

        expect(flyout.emitted('action')).toHaveLength(1)
      })
    })
  })
})
