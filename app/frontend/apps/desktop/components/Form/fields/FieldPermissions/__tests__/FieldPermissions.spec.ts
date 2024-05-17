// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import {
  getAllByRole,
  getAllByTestId,
  getByRole,
  waitFor,
} from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { i18n } from '#shared/i18n.ts'

import type { PermissionsParentOption } from '../types.ts'

const testOptions: PermissionsParentOption[] = [
  {
    value: 'admin',
    label: 'Admin interface',
    description: 'Configure your system.',
    children: [
      {
        value: 'admin.user',
        label: 'Users',
        description: 'Manage all users of your system.',
      },
    ],
  },
  {
    value: 'ticket',
    label: 'Ticket',
    description: 'Access the ticket interface.',
    disabled: true,
    children: [
      {
        value: 'ticket.agent',
        label: 'Agent Tickets',
        description: 'Access the agent tickets based on group access.',
      },
      {
        value: 'ticket.customer',
        label: 'Customer Tickets',
        description: 'Access the customer tickets.',
      },
    ],
  },
  {
    value: 'user_preferences',
    label: 'Profile settings',
    description: 'Access the personal settings.',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
}

const renderPermissions = async (props: Record<string, unknown> = {}) => {
  const view = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      id: 'permissions',
      type: 'permissions',
      name: 'permissions',
      label: 'Permissions',
      options: testOptions,
      value: [],
      ...props,
    },
  })

  await waitForNextTick(true)

  return view
}

describe('Form - Field - Permissions', () => {
  it('renders parent options and their labels', async () => {
    const wrapper = await renderPermissions()

    const permissions = wrapper.getAllByRole('treeitem')

    expect(permissions).toHaveLength(testOptions.length)

    permissions.forEach((permission, index) => {
      expect(getByRole(permission, 'switch')).toBeInTheDocument()

      const labels = getAllByTestId(permission, 'common-label')

      expect(labels[0]).toHaveTextContent(i18n.t(testOptions[index].label))

      expect(labels[1]).toHaveTextContent(testOptions[index].description!)

      const badges = getAllByTestId(permission, 'common-badge')

      expect(badges[0]).toHaveTextContent(testOptions[index].value)
    })
  })

  it('renders child options and their labels', async () => {
    const wrapper = await renderPermissions({
      value: ['ticket.agent', 'ticket.customer'],
    })

    const childGroup = wrapper.getByRole('group')

    const childPermissions = getAllByRole(childGroup, 'treeitem')

    expect(childPermissions).toHaveLength(testOptions[1].children!.length)

    childPermissions.forEach((childPermission, index) => {
      expect(getByRole(childPermission, 'switch')).toBeInTheDocument()

      const labels = getAllByTestId(childPermission, 'common-label')

      expect(labels[0]).toHaveTextContent(
        i18n.t(
          testOptions[1].children![index].label,
          testOptions[1].children![index].value,
        ),
      )

      expect(labels[1]).toHaveTextContent(
        testOptions[1].children![index].description!,
      )
    })
  })

  it('supports toggling collapsible group of child options', async () => {
    const wrapper = await renderPermissions()

    expect(wrapper.queryByRole('group')).not.toBeInTheDocument()

    const permissions = wrapper.getAllByRole('treeitem')

    const toggleButton = getByRole(permissions[1], 'button', {
      name: 'Toggle Group',
    })

    await wrapper.events.click(toggleButton)

    const childGroup = wrapper.getByRole('group')

    const childPermissions = getAllByRole(childGroup, 'treeitem')

    expect(childPermissions).toHaveLength(testOptions[1].children!.length)

    await wrapper.events.click(toggleButton)

    expect(childGroup).not.toBeVisible()
  })

  it('collapses child options when parent is selected', async () => {
    const wrapper = await renderPermissions({
      value: ['admin.user'],
    })

    const permissions = wrapper.getAllByRole('treeitem')

    const childGroup = wrapper.getByRole('group')

    const childPermissions = getAllByRole(childGroup, 'treeitem')

    expect(childPermissions).toHaveLength(testOptions[0].children!.length)

    const toggleSwitch = getByRole(permissions[0], 'switch')

    await wrapper.events.click(toggleSwitch)

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(childGroup).not.toBeVisible()
  })

  it('supports disabled state for parent options', async () => {
    const wrapper = await renderPermissions()

    const permissions = wrapper.getAllByRole('treeitem')

    const toggleSwitch = getByRole(permissions[1], 'switch')

    expect(toggleSwitch).toBeDisabled()
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Form - Field - Permissions - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderPermissions({
      id: 'test_id',
    })

    expect(view.getByLabelText('Permissions')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const view = await renderPermissions({
      name: 'test_name',
    })

    expect(view.getByLabelText('Permissions')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderPermissions({
      onBlur: blurHandler,
    })

    view.getByLabelText('Permissions').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = await renderPermissions()

    for await (const [i, item] of [testOptions[0], testOptions[2]].entries()) {
      wrapper.events.click(
        wrapper.getByLabelText(
          `${i18n.t(item.label)}${item.value}${item.description}`,
        ),
      )

      await waitFor(() => {
        expect(wrapper.emitted().inputRaw[i]).toBeTruthy()
      })
    }

    await waitFor(() => {
      expect(getNode('permissions')?.value).toEqual([
        testOptions[0].value,
        testOptions[2].value,
      ])
    })
  })

  it('implements input value display', async () => {
    const wrapper = await renderPermissions({
      value: [testOptions[2].value],
    })

    const toggleSwitch1 = wrapper.getByLabelText(
      `${i18n.t(testOptions[0].label)}${testOptions[0].value}${testOptions[0].description}`,
    )

    expect(toggleSwitch1).not.toBeChecked()

    const toggleSwitch2 = wrapper.getByLabelText(
      `${i18n.t(testOptions[1].label)}${testOptions[1].value}${testOptions[1].description}`,
    )

    expect(toggleSwitch2).not.toBeChecked()

    const toggleSwitch3 = wrapper.getByLabelText(
      `${i18n.t(testOptions[2].label)}${testOptions[2].value}${testOptions[2].description}`,
    )

    expect(toggleSwitch3).toBeChecked()
  })

  it('implements disabled', async () => {
    const view = await renderPermissions({
      disabled: true,
    })

    expect(view.getByLabelText('Permissions')).toBeDisabled()

    for (const option of testOptions) {
      expect(
        view.getByLabelText(
          `${i18n.t(option.label)}${option.value}${option.description}`,
        ),
      ).toBeDisabled()
    }
  })

  it('implements attribute passthrough', async () => {
    const view = await renderPermissions({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Permissions')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderPermissions()

    expect(view.getByLabelText('Permissions')).toHaveClass('formkit-input')
  })
})
