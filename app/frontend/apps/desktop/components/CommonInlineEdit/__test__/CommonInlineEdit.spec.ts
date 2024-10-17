// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent, waitFor } from '@testing-library/vue'

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
    router: true,
  })
}

describe('CommonInlineEdit', () => {
  it('shows by default non editable node', () => {
    const wrapper = renderInlineEdit()

    expect(wrapper.getByText('test value')).toBeInTheDocument()
    expect(wrapper.queryByDisplayValue('test value')).not.toBeInTheDocument()
  })

  it('supports placeholder on edit input', async () => {
    const wrapper = renderInlineEdit({ placeholder: 'test placeholder' })
    await wrapper.events.click(wrapper.getByRole('button'))

    expect(
      await wrapper.findByPlaceholderText('test placeholder'),
    ).toBeInTheDocument()
  })

  it('submits edit on button click and enter', async () => {
    const submitEditCallbackSpy = vi.fn()

    const wrapper = renderInlineEdit({
      onSubmitEdit: (newValue: string) => submitEditCallbackSpy(newValue),
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update')

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    expect(submitEditCallbackSpy).toHaveBeenCalledWith('test value update')

    expect(wrapper.queryByRole('textbox')).not.toBeInTheDocument()
  })

  it('submits edit on enter key', async () => {
    const submitEditCallbackSpy = vi.fn()

    const wrapper = renderInlineEdit({
      onSubmitEdit: (value: string) => submitEditCallbackSpy(value),
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update 2')

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await wrapper.events.keyboard('{enter}')

    expect(submitEditCallbackSpy).toHaveBeenCalledWith('test value update 2')
  })

  it('submits on background click', async () => {
    const submitEditCallbackSpy = vi.fn()

    const wrapper = renderInlineEdit({
      onSubmitEdit: (value: string) => submitEditCallbackSpy(value),
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update 2')

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await fireEvent.click(document.body)

    expect(submitEditCallbackSpy).toHaveBeenCalledWith('test value update 2')
  })

  it('do not stop edit mode when submit promise failed', async () => {
    const wrapper = renderInlineEdit({
      onSubmitEdit: (): Promise<void> => {
        return new Promise((resolve, reject) => {
          reject()
        })
      },
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.type(wrapper.getByRole('textbox'), ' update')

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    expect(wrapper.getByRole('textbox')).toBeInTheDocument()
  })

  it('focuses field on edit', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    expect(wrapper.getByRole('textbox')).toHaveFocus()
  })

  it('cancels on button click', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Cancel' }))

    expect(wrapper.queryByRole('textbox')).not.toBeInTheDocument()

    expect(wrapper.emitted()['cancel-edit']).toBeTruthy()
  })

  it('cancels on escape key', async () => {
    const wrapper = renderInlineEdit()

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await wrapper.events.keyboard('{esc}')

    expect(wrapper.emitted()['cancel-edit']).toBeTruthy()
  })

  it('disables submit if input is incorrect and required is true', async () => {
    const wrapper = renderInlineEdit({ required: true })

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() =>
      expect(wrapper.getByRole('textbox')).toBeInTheDocument(),
    )

    await wrapper.events.clear(wrapper.getByRole('textbox'))

    expect(wrapper.emitted()['submit-edit']).toBeFalsy()

    expect(wrapper.getByRole('button', { name: 'Submit' })).toBeDisabled()

    expect(wrapper.getByRole('textbox')).toBeInTheDocument()
  })

  it('supports adding attributes on label', () => {
    const wrapper = renderInlineEdit({
      labelAttrs: {
        role: 'heading',
        'aria-level': '1',
      },
    })

    expect(wrapper.getByRole('heading', { level: 1 })).toBeInTheDocument()
  })

  it('allows inline edit to be take up full width if set to block', () => {
    const wrapper = renderInlineEdit({
      block: true,
    })
    expect(wrapper.getByRole('button')).toHaveClass('w-full')
  })

  it('disables input if disabled prop is true', async () => {
    const wrapper = renderInlineEdit({ disabled: true })

    expect(wrapper.getByText('test value')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('test value'))

    expect(wrapper.queryByRole('textbox')).not.toBeInTheDocument()
  })

  it('detects links if set to true and renders it as link only in label', async () => {
    const wrapper = renderInlineEdit({
      detectLinks: true,
      value: 'https://zammad.com/en',
    })

    expect(
      wrapper.getByRole('link', { name: 'https://zammad.com/en' }),
    ).toBeInTheDocument()
  })

  it('displays initial edit value if editing got activated', async () => {
    const wrapper = renderInlineEdit({
      initialEditValue: 'initial Value',
      value: 'default Value',
    })

    await wrapper.events.click(wrapper.getByText('default Value'))

    expect(wrapper.getByRole('textbox')).toHaveValue('initial Value')
  })

  it('support loading', async () => {
    const wrapper = renderInlineEdit({
      initialEditValue: 'initial Value',
      value: 'default Value',
      loading: true,
    })

    await wrapper.events.click(wrapper.getByText('default Value'))

    expect(wrapper.getByRole('textbox')).toBeDisabled()
  })

  it('supports adding alternative background color', async () => {
    const wrapper = renderInlineEdit({
      alternativeBackground: true,
    })

    await wrapper.events.click(wrapper.getByText('test value'))

    expect(wrapper.html()).toContain(
      'before:bg-neutral-50 before:dark:bg-gray-500',
    )

    await wrapper.rerender({
      alternativeBackground: false,
    })

    expect(wrapper.html()).toContain(
      'before:bg-blue-200 before:dark:bg-gray-700',
    )

    expect(wrapper.html()).not.toContain(
      'before:bg-neutral-50 before:dark:bg-gray-500',
    )
  })
})
