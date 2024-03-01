// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  getAllByRole,
  getByRole,
  queryByRole,
  waitFor,
} from '@testing-library/vue'
import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

const renderGroupPermissionsInput = async (
  props: Record<string, unknown> = {},
) => {
  const view = renderComponent(FormKit, {
    props: {
      id: 'groupPermissions',
      type: 'groupPermissions',
      name: 'groupPermissions',
      label: 'Group permissions',
      formId: 'form',
      ...props,
    },
    form: true,
  })

  await waitForNextTick(true)

  return view
}

const commonProps = {
  options: [
    {
      value: 1,
      label: 'Users',
    },
    {
      value: 2,
      label: 'some group1',
      children: [
        {
          value: 3,
          label: 'Nested group',
        },
      ],
    },
  ],
}

describe('Fields - FieldGroupPermissions', () => {
  it('renders group selection and permission checkboxes', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    expect(view.getByLabelText('Group permissions')).toBeInTheDocument()
    expect(view.getByRole('combobox')).toBeInTheDocument()
    expect(view.getByLabelText('Read')).toBeInTheDocument()
    expect(view.getByLabelText('Create')).toBeInTheDocument()
    expect(view.getByLabelText('Change')).toBeInTheDocument()
    expect(view.getByLabelText('Overview')).toBeInTheDocument()
    expect(view.getByLabelText('Full')).toBeInTheDocument()
  })

  it('provides buttons to remove and add rows', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    expect(view.getByRole('button', { name: 'Remove' })).toBeDisabled()
    expect(view.getByRole('button', { name: 'Add' })).toBeDisabled()

    await view.events.click(view.getByRole('combobox'))

    let listbox = view.getByRole('listbox')
    let options = getAllByRole(listbox, 'option')

    await view.events.click(options[0])

    expect(view.getByRole('button', { name: 'Remove' })).toBeDisabled()
    expect(view.getByRole('button', { name: 'Add' })).toBeEnabled()

    await view.events.click(view.getByRole('button', { name: 'Add' }))

    view.getAllByRole('button', { name: 'Remove' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    view.getAllByRole('button', { name: 'Add' }).forEach((button) => {
      expect(button).toBeDisabled()
    })

    await view.events.click(view.getAllByRole('combobox')[1])

    listbox = view.getByRole('listbox')
    options = getAllByRole(listbox, 'option')

    await view.events.click(options[0])

    view.getAllByRole('button', { name: 'Remove' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    view.getAllByRole('button', { name: 'Add' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    await view.events.click(view.getAllByRole('button', { name: 'Add' })[1])

    view.getAllByRole('button', { name: 'Remove' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    view.getAllByRole('button', { name: 'Add' }).forEach((button) => {
      expect(button).toBeDisabled()
    })

    await view.events.click(view.getAllByRole('button', { name: 'Remove' })[2])

    view.getAllByRole('button', { name: 'Remove' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    view.getAllByRole('button', { name: 'Add' }).forEach((button) => {
      expect(button).toBeEnabled()
    })

    await view.events.click(view.getAllByRole('button', { name: 'Remove' })[1])

    expect(view.getByRole('button', { name: 'Remove' })).toBeDisabled()
    expect(view.getByRole('button', { name: 'Add' })).toBeEnabled()
  })

  it('filters out already selected groups', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    await view.events.click(view.getByRole('combobox'))

    let listbox = view.getByRole('listbox')
    let options = getAllByRole(listbox, 'option')

    expect(options).toHaveLength(2)

    expect(
      view.getByRole('button', { name: 'Has submenu' }),
    ).toBeInTheDocument()

    await view.events.click(options[0])
    await view.events.click(view.getByRole('button', { name: 'Add' }))
    await view.events.click(view.getAllByRole('combobox')[1])

    listbox = view.getByRole('listbox')
    options = getAllByRole(listbox, 'option')

    expect(options).toHaveLength(1)

    expect(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    ).toBeInTheDocument()

    await view.events.click(options[0])
    await view.events.click(view.getAllByRole('combobox')[1])

    listbox = view.getByRole('listbox')

    await view.events.click(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    )

    await view.events.click(getByRole(listbox, 'option'))

    await waitFor(() => {
      expect(getNode('groupPermissions')?.value).toEqual([
        expect.objectContaining({
          groups: [1],
          groupAccess: {
            change: false,
            create: false,
            full: false,
            overview: false,
            read: false,
          },
        }),
        expect.objectContaining({
          groups: [2, 3],
          groupAccess: {
            change: false,
            create: false,
            full: false,
            overview: false,
            read: false,
          },
        }),
      ])
    })

    await view.events.click(view.getAllByRole('combobox')[0])

    listbox = view.getByRole('listbox')
    options = getAllByRole(listbox, 'option')

    expect(options).toHaveLength(1)

    expect(
      queryByRole(listbox, 'button', { name: 'Has submenu' }),
    ).not.toBeInTheDocument()

    await view.events.keyboard('{Escape}')

    const combobox = view.getAllByRole('combobox')[1]
    const listitem = getAllByRole(combobox, 'listitem')[1]

    await view.events.click(
      getByRole(listitem, 'button', { name: 'Unselect Option' }),
    )

    await waitFor(async () => {
      expect(getNode('groupPermissions')?.value).toEqual([
        expect.objectContaining({
          groups: [1],
          groupAccess: {
            change: false,
            create: false,
            full: false,
            overview: false,
            read: false,
          },
        }),
        expect.objectContaining({
          groups: [2],
          groupAccess: {
            change: false,
            create: false,
            full: false,
            overview: false,
            read: false,
          },
        }),
      ])
    })

    await view.events.click(view.getAllByRole('combobox')[0])

    listbox = view.getByRole('listbox')
    options = getAllByRole(listbox, 'option')

    expect(options).toHaveLength(2)

    expect(
      queryByRole(listbox, 'button', { name: 'Has submenu' }),
    ).toBeInTheDocument()
  })

  it('ensures either granular or full access is selected', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    await view.events.click(view.getByLabelText('Read'))
    await view.events.click(view.getByLabelText('Full'))

    await waitFor(() => {
      expect(getNode('groupPermissions')?.value).toEqual([
        expect.objectContaining({
          groupAccess: {
            read: false,
            create: false,
            change: false,
            overview: false,
            full: true,
          },
        }),
      ])
    })

    expect(view.getByLabelText('Read')).not.toBeChecked()

    await view.events.click(view.getByLabelText('Read'))
    await view.events.click(view.getByLabelText('Create'))
    await view.events.click(view.getByLabelText('Change'))
    await view.events.click(view.getByLabelText('Overview'))

    await waitFor(() => {
      expect(getNode('groupPermissions')?.value).toEqual([
        expect.objectContaining({
          groupAccess: {
            read: true,
            create: true,
            change: true,
            overview: true,
            full: false,
          },
        }),
      ])
    })

    expect(view.getByLabelText('Full')).not.toBeChecked()

    await view.events.click(view.getByLabelText('Full'))

    await waitFor(() => {
      expect(getNode('groupPermissions')?.value).toEqual([
        expect.objectContaining({
          groupAccess: {
            read: false,
            create: false,
            change: false,
            overview: false,
            full: true,
          },
        }),
      ])
    })

    expect(view.getByLabelText('Read')).not.toBeChecked()
    expect(view.getByLabelText('Create')).not.toBeChecked()
    expect(view.getByLabelText('Change')).not.toBeChecked()
    expect(view.getByLabelText('Overview')).not.toBeChecked()
  })

  it('does not translate group names', async () => {
    const testOptions = [
      {
        value: 1,
        label: 'Group name (%s)',
        labelPlaceholder: ['translated'],
      },
    ]

    const view = await renderGroupPermissionsInput({
      options: testOptions,
    })

    await view.events.click(view.getByRole('combobox'))

    const listbox = view.getByRole('listbox')
    const options = getAllByRole(listbox, 'option')

    expect(options[0]).toHaveTextContent(testOptions[0].label)
  })

  it('preserves state when upper rows are removed', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    await view.events.click(view.getByRole('combobox'))

    let listbox = view.getByRole('listbox')
    let options = getAllByRole(listbox, 'option')

    await view.events.click(options[0])
    await view.events.click(view.getByRole('button', { name: 'Add' }))
    await view.events.click(view.getAllByRole('combobox')[1])

    listbox = view.getByRole('listbox')
    options = getAllByRole(listbox, 'option')

    const secondGroupSelection = options[0].textContent || ''

    await view.events.click(options[0])
    await view.events.click(view.getAllByLabelText('Read')[1])
    await view.events.click(view.getAllByRole('button', { name: 'Remove' })[0])

    expect(view.getByRole('combobox')).toHaveTextContent(secondGroupSelection)
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Fields - FieldGroupPermissions - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderGroupPermissionsInput({
      ...commonProps,
      id: 'test_id',
    })

    expect(view.getByLabelText('Group permissions')).toHaveAttribute(
      'id',
      'test_id',
    )
  })

  it('implements input name', async () => {
    const view = await renderGroupPermissionsInput({
      ...commonProps,
      name: 'test_name',
    })

    expect(view.getByLabelText('Group permissions')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderGroupPermissionsInput({
      ...commonProps,
      onBlur: blurHandler,
    })

    view.getByLabelText('Group permissions').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    await view.events.click(view.getByRole('combobox'))
    await view.events.click(view.getAllByRole('option')[0])

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    await waitFor(() => {
      expect(emittedInput[1][0]).toEqual([
        expect.objectContaining({
          groups: [1],
          groupAccess: {
            change: false,
            create: false,
            full: false,
            overview: false,
            read: false,
          },
        }),
      ])
    })

    await view.events.click(view.getByLabelText('Full'))

    await waitFor(() => {
      expect(emittedInput[2][0]).toEqual([
        expect.objectContaining({
          groups: [1],
          groupAccess: {
            change: false,
            create: false,
            full: true,
            overview: false,
            read: false,
          },
        }),
      ])
    })
  })

  it('implements input value display', async () => {
    const view = await renderGroupPermissionsInput({
      ...commonProps,
      value: [
        {
          groups: [1],
          groupAccess: {
            change: false,
            create: false,
            full: true,
            overview: false,
            read: false,
          },
        },
      ],
    })

    const combobox = view.getByRole('combobox')

    expect(getByRole(combobox, 'listitem')).toHaveTextContent('Users')
    expect(view.getByLabelText('Read')).not.toBeChecked()
    expect(view.getByLabelText('Create')).not.toBeChecked()
    expect(view.getByLabelText('Change')).not.toBeChecked()
    expect(view.getByLabelText('Overview')).not.toBeChecked()
    expect(view.getByLabelText('Full')).toBeChecked()
  })

  it('implements disabled', async () => {
    const view = await renderGroupPermissionsInput({
      ...commonProps,
      disabled: true,
    })

    expect(view.getByLabelText('Group permissions')).toBeDisabled()
    expect(view.getByRole('combobox')).toBeDisabled()
    expect(view.getByLabelText('Read')).toBeDisabled()
    expect(view.getByLabelText('Create')).toBeDisabled()
    expect(view.getByLabelText('Change')).toBeDisabled()
    expect(view.getByLabelText('Overview')).toBeDisabled()
    expect(view.getByLabelText('Full')).toBeDisabled()
  })

  it('implements attribute passthrough', async () => {
    const view = await renderGroupPermissionsInput({
      ...commonProps,
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Group permissions')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderGroupPermissionsInput(commonProps)

    expect(view.getByLabelText('Group permissions')).toHaveClass(
      'formkit-input',
    )
  })
})
