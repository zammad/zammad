// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect } from 'vitest'
import { nextTick, toValue, useTemplateRef } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import Form from '#shared/components/Form/Form.vue'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { useFormSubmitShortcut } from '#desktop/composables/useFormSubmitShortcut.ts'
import { useOverlayCoverage } from '#desktop/composables/useOverlayCoverage.ts'

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
        flyout: true,
        router: true,
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
      expect(flyout.getByText('Cancel & go back')).toBeInTheDocument()
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

      expect(flyout.queryByLabelText('Resize side panel')).not.toBeInTheDocument()
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
          default: html` <input type="text" placeholder="test" name="test-input" /> `,
        },
      })

      await nextTick()

      expect(flyout.getByPlaceholderText('test')).toHaveFocus()
    })

    it('has a default container width of 500px', async () => {
      expect(flyout.getByRole('complementary')).toHaveStyle({
        '--flyout-container-width': '500px',
      })
    })

    it('displays by default over the main content', async () => {
      await flyout.rerender({ fullscreen: false })

      expect(document.body).not.include(flyout.baseElement)
      expect(document.body).include(flyout.baseElement)
    })

    it('supports displaying over entire viewport', async () => {
      await flyout.rerender({ fullscreen: true })

      expect(document.body).include(flyout.baseElement)
    })

    describe('events', () => {
      it('emits close event when cancel button is clicked', async () => {
        await flyout.events.click(flyout.getByText('Cancel & go back'))

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

describe('submitting a form in a common flyout', () => {
  it('submits the form with ctrl+enter from one of its fields', async () => {
    const onSubmit = vi.fn()

    const wrapper = renderComponent(
      {
        components: { CommonFlyout, Form },
        template: html`
          <CommonFlyout
            name="form-flyout"
            header-title="Form"
            :form="form"
            :footer-action-options="{ actionButton: { type: 'submit' } }"
          >
            <Form id="flyout-form" ref="form" :schema="schema" @submit="onSubmit" />
          </CommonFlyout>
        `,
        setup: () => {
          useFormSubmitShortcut()

          return {
            form: useTemplateRef('form'),
            schema: [{ type: 'text', name: 'title', label: 'Title' }],
            onSubmit,
          }
        },
      },
      { flyout: true, router: true, form: true },
    )

    await vi.waitFor(() => expect(wrapper.getByLabelText('Title')).toBeVisible())

    wrapper.getByLabelText('Title').focus()
    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')

    await vi.waitFor(() => expect(onSubmit).toHaveBeenCalledOnce())
  })

  describe('coverage', () => {
    const coverage = () =>
      useOverlayCoverage().shownOverlays.value.map(({ id, coversApplication }) => ({
        id,
        coversApplication: toValue(coversApplication),
      }))

    it.each([false, true])(
      'covers the page with its backdrop, in full screen %s the whole application',
      (fullscreen) => {
        renderComponent(CommonFlyout, {
          props: { name: 'covering', fullscreen },
          flyout: true,
          router: true,
        })

        expect(coverage()).toEqual([{ id: 'flyout-covering', coversApplication: fullscreen }])
      },
    )

    it('leaves the page reachable without a backdrop', () => {
      renderComponent(CommonFlyout, {
        props: { name: 'uncovering', showBackdrop: false },
        flyout: true,
        router: true,
      })

      expect(coverage()).toEqual([])
    })
  })
})
