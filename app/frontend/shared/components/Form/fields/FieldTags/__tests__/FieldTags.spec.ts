// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { getByText, queryByRole } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import { getByIconName } from '@tests/support/components/iconQueries'
import type { FieldTagsProps } from '../types'

const defaultTags = [
  { label: 'test', value: 'test' },
  { label: 'support', value: 'support' },
  { label: 'paid', value: 'paid' },
]

const renderFieldTags = (props: Partial<FieldTagsProps> = {}) =>
  renderComponent(FormKit, {
    form: true,
    formField: true,
    dialog: true,
    props: {
      type: 'tags',
      name: 'tags',
      label: 'Tags',
      options: defaultTags,
      ...props,
    },
  })

beforeAll(async () => {
  await import('../FieldTagsDialog.vue')
})

describe('Form - Field - Tags', () => {
  it('renders field', async () => {
    const view = renderFieldTags()

    const node = view.getByLabelText('Tags')

    expect(queryByRole(node, 'list')).not.toBeInTheDocument()

    await view.events.click(node)

    expect(view.getByPlaceholderText('Tag name…')).toBeInTheDocument()

    const options = view.getAllByRole('button', { name: /^(?!Done)/ })

    expect(options).toHaveLength(3)
    expect(options[0]).toHaveTextContent('paid')
    expect(options[1]).toHaveTextContent('support')
    expect(options[2]).toHaveTextContent('test')

    await view.events.click(options[0])
    await view.events.click(options[1])

    expect(
      getByIconName(options[0], 'mobile-check-box-yes'),
    ).toBeInTheDocument()

    expect(
      getByIconName(options[1], 'mobile-check-box-yes'),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Done' }))

    expect(getByText(node, 'paid')).toBeInTheDocument()
    expect(getByText(node, 'support')).toBeInTheDocument()
  })

  it('can deselect tags', async () => {
    const view = renderFieldTags()

    const node = view.getByLabelText('Tags')
    await view.events.click(node)

    const options = view.getAllByRole('button', { name: /^(?!Done)/ })

    await view.events.click(options[0])

    await view.events.click(view.getByRole('button', { name: 'Done' }))

    expect(node, 'has selected tags').toHaveTextContent('paid')

    await view.events.click(node)

    const newOptions = view.getAllByRole('button', { name: /^(?!Done)/ })

    await view.events.click(newOptions[0])
    await view.events.click(view.getByRole('button', { name: 'Done' }))

    expect(queryByRole(node, 'list')).not.toBeInTheDocument()
  })

  it('filters options', async () => {
    const view = renderFieldTags()

    const node = view.getByLabelText('Tags')
    await view.events.click(node)

    const filterInput = view.getByPlaceholderText('Tag name…')

    await view.events.type(filterInput, 'paid')

    const options = view.getAllByRole('button', { name: /^(?!Done)/ })

    expect(options).toHaveLength(1)
    expect(options[0]).toHaveTextContent('paid')

    expect(
      view.queryByTitle('Create tag'),
      "can't create, because prop is false",
    ).not.toBeInTheDocument()
  })

  it("can't add existing tag", async () => {
    const view = renderFieldTags({ canCreate: true })

    const node = view.getByLabelText('Tags')
    await view.events.click(node)

    const filterInput = view.getByPlaceholderText('Tag name…')

    await view.events.type(filterInput, 'paid')

    const createButton = view.getByTitle('Create tag')

    expect(createButton).toBeDisabled()
    await view.events.click(createButton)

    // TODO api not called
  })

  it('can add new tag', async () => {
    const view = renderFieldTags({ canCreate: true })

    const node = view.getByLabelText('Tags')
    await view.events.click(node)

    const filterInput = view.getByPlaceholderText('Tag name…')

    await view.events.type(filterInput, 'pay')

    const createButton = view.getByTitle('Create tag')

    expect(createButton).toBeEnabled()
    await view.events.click(createButton)

    expect(view.getByRole('button', { name: 'pay' })).toBeInTheDocument()
  })

  it("clicking disabled field doesn't select dialog", async () => {
    const wrapper = renderFieldTags({ disabled: true })

    await wrapper.events.click(wrapper.getByLabelText('Tags'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('clicking select without options opens select dialog', async () => {
    const wrapper = renderFieldTags({ options: [] })

    await wrapper.events.click(wrapper.getByLabelText('Tags'))

    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
  })
})
