// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import ImageAltForm from '../ImageAltForm.vue'

const renderForm = (alt?: string | null) =>
  renderComponent(ImageAltForm, {
    props: { alt },
    form: true,
  })

type View = ReturnType<typeof renderForm>

describe('ImageAltForm', () => {
  it('is a dialog named after its field, prefilled with the alternative text', async () => {
    const view = renderForm('Example chart')

    expect(view.getByRole('dialog', { name: 'Alternative text' })).toBeInTheDocument()
    expect(await view.findByRole('textbox', { name: 'Alternative text' })).toHaveValue(
      'Example chart',
    )
  })

  it('saves the trimmed alternative text', async () => {
    const view = renderForm()

    await view.events.type(
      await view.findByRole('textbox', { name: 'Alternative text' }),
      ' Example chart ',
    )
    await view.events.click(view.getByRole('button', { name: 'Save' }))

    await waitForNextTick()

    expect(view.emitted('save')).toEqual([['Example chart']])
  })

  it('saves with Enter', async () => {
    const view = renderForm('Example chart')

    await view.events.type(
      await view.findByRole('textbox', { name: 'Alternative text' }),
      '{Enter}',
    )

    await waitForNextTick()

    expect(view.emitted('save')).toEqual([['Example chart']])
  })

  it('saves an empty alternative text, which marks the image decorative', async () => {
    const view = renderForm('Example chart')

    await view.events.clear(await view.findByRole('textbox', { name: 'Alternative text' }))
    await view.events.click(view.getByRole('button', { name: 'Save' }))

    await waitForNextTick()

    expect(view.emitted('save')).toEqual([['']])
  })

  it.each([
    [
      'the cancel button',
      (view: View) => view.events.click(view.getByRole('button', { name: 'Cancel' })),
    ],
    ['Escape', (view: View) => view.events.keyboard('{Escape}')],
  ])('cancels with %s', async (_, cancel) => {
    const view = renderForm('Example chart')

    await view.events.click(await view.findByRole('textbox', { name: 'Alternative text' }))
    await cancel(view)

    expect(view.emitted('cancel')).toHaveLength(1)
    expect(view.emitted('save')).toBeUndefined()
  })
})
