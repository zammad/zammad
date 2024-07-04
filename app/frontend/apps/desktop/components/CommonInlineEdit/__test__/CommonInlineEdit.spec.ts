// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { h } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonInlineEdit, {
  type Props,
} from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'

const renderInlineEdit = (props: Partial<Props> = {}) => {
  return renderComponent(CommonInlineEdit, {
    props: {
      name: 'inlineEditTest',
      value: 'test value',
      label: 'Inline Edit Label',
      submitLabel: 'Submit',
      cancelLabel: 'Cancel',
      ...props,
    },
    form: true,
    slots: {
      default: () => h('h2', 'test value'),
    },
  })
}

describe('CommonInlineEdit', async () => {
  it('shows by default slot content', () => {
    const wrapper = renderInlineEdit()

    expect(wrapper.getByText('test value')).toBeInTheDocument()
    expect(wrapper.queryByDisplayValue('test value')).not.toBeInTheDocument()
  })

  it('submits edit on button click', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update')

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    expect(wrapper.emitted()['submit-edit']).toBeTruthy()

    // KEYDOWN ENTER

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update 2')

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    await wrapper.events.keyboard('{enter}')

    expect(wrapper.emitted()['submit-edit']).toBeTruthy()
  })

  it('submits edit on enter key', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update 2')

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    await wrapper.events.keyboard('{enter}')

    expect(wrapper.emitted()['submit-edit']).toBeTruthy()
  })

  it('focuses field on edit', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    expect(
      wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
    ).toHaveFocus()
  })

  it('cancels on button click', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Cancel' }))

    expect(
      wrapper.queryByRole('textbox', { name: 'Inline Edit Label' }),
    ).not.toBeInTheDocument()

    expect(wrapper.emitted()['cancel-edit']).toBeTruthy()
  })

  it('cancels on escape key', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    await wrapper.events.keyboard('{esc}')

    expect(wrapper.emitted()['cancel-edit']).toBeTruthy()
  })

  it('disables submit if input is incorrect and required is true', async () => {
    const wrapper = renderInlineEdit({ required: true })

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    await wrapper.events.type(wrapper.getByRole('textbox'), ' ')

    expect(wrapper.emitted()['submit-edit']).toBeFalsy()

    expect(wrapper.getByRole('button', { name: 'Submit' })).toBeDisabled()

    expect(
      wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
    ).toBeInTheDocument()
  })

  it('disables submit if input has not changed', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(
        wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
      ).toBeInTheDocument(),
    )

    expect(wrapper.emitted()['submit-edit']).toBeFalsy()

    expect(wrapper.getByRole('button', { name: 'Submit' })).toBeDisabled()

    expect(
      wrapper.getByRole('textbox', { name: 'Inline Edit Label' }),
    ).toBeInTheDocument()
  })
})
