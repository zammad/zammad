// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor, within } from '@testing-library/vue'

import { checkSimpleTableHeader } from '#tests/support/components/checkSimpleTableContent.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { KnowledgeBaseAccess, type KnowledgeBasePermissionRow } from '../types.ts'

const tableHeaders = ['Role', 'Editor', 'Reader', 'None']

const permissionRows: KnowledgeBasePermissionRow[] = [
  {
    roleId: '1',
    roleName: 'Admin',
    inheritedAccess: null,
    allowedAccesses: [
      KnowledgeBaseAccess.Editor,
      KnowledgeBaseAccess.Reader,
      KnowledgeBaseAccess.None,
    ],
  },
  {
    roleId: '2',
    roleName: 'Agent',
    inheritedAccess: null,
    allowedAccesses: [
      KnowledgeBaseAccess.Editor,
      KnowledgeBaseAccess.Reader,
      KnowledgeBaseAccess.None,
    ],
  },
]

const testValue = {
  '1': KnowledgeBaseAccess.Editor,
  '2': KnowledgeBaseAccess.Reader,
}

const wrapperParameters = {
  form: true,
}

const renderPermissionsInput = async (props: Record<string, unknown> = {}) => {
  const view = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      id: 'kbPermissions',
      type: 'kbPermissions',
      name: 'kbPermissions',
      label: 'Knowledge base permissions',
      labelSrOnly: true,
      formId: 'form',
      permissionRows,
      ...props,
    },
    form: true,
  })

  await waitForNextTick(true)

  return view
}

describe('Form - Field - Knowledge Base Permissions', () => {
  it('renders one row per role with three radios each', async () => {
    const view = await renderPermissionsInput()

    checkSimpleTableHeader(view, tableHeaders)

    const table = within(view.getByRole('table'))

    // One header row plus one row per role, in the given order.
    const rows = table.getAllByRole('row').slice(1)

    expect(rows).toHaveLength(permissionRows.length)

    rows.forEach((row, index) => {
      const { roleName } = permissionRows[index]

      expect(within(row).getAllByRole('cell')[0]).toHaveTextContent(roleName)
      expect(within(row).getAllByRole('radio')).toHaveLength(3)

      expect(view.getByLabelText(`${roleName} - Editor`)).toBeInTheDocument()
      expect(view.getByLabelText(`${roleName} - Reader`)).toBeInTheDocument()
      expect(view.getByLabelText(`${roleName} - None`)).toBeInTheDocument()
    })
  })

  it('groups the radios of one role, but not across roles', async () => {
    const view = await renderPermissionsInput()

    const adminGroup = 'kb_permissions_radio_kbPermissions_1'

    expect(view.getByLabelText('Admin - Editor')).toHaveAttribute('name', adminGroup)
    expect(view.getByLabelText('Admin - Reader')).toHaveAttribute('name', adminGroup)
    expect(view.getByLabelText('Admin - None')).toHaveAttribute('name', adminGroup)

    expect(view.getByLabelText('Agent - Editor')).toHaveAttribute(
      'name',
      'kb_permissions_radio_kbPermissions_2',
    )
  })

  it('mutates passed value via input events', async () => {
    const view = await renderPermissionsInput({
      value: testValue,
    })

    await view.events.click(view.getByLabelText('Admin - Reader'))

    await waitFor(() => {
      expect(view.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    // The other roles are kept.
    expect(emittedInput[0][0]).toStrictEqual({
      ...testValue,
      '1': KnowledgeBaseAccess.Reader,
    })
  })

  it('renders a skeleton until the form updater provides the rows', async () => {
    const view = await renderPermissionsInput({
      permissionRows: undefined,
    })

    expect(view.getByTestId('knowledge-base-permissions-skeleton')).toBeInTheDocument()
    expect(view.queryByRole('table')).not.toBeInTheDocument()

    await view.rerender({ permissionRows })

    await waitFor(() =>
      expect(view.queryByTestId('knowledge-base-permissions-skeleton')).not.toBeInTheDocument(),
    )
    expect(view.getByRole('table')).toBeInTheDocument()
  })

  // Offering a level a role may not hold is not merely useless: the form updater clamps an
  //   illegal access to the most restrictive allowed one, so the selection would visibly jump
  //   to something the user did not ask for.
  describe('locked accesses', () => {
    const lockedRows: KnowledgeBasePermissionRow[] = [
      // Inherits editor from the parent, which cannot be overridden at all.
      {
        roleId: '1',
        roleName: 'Admin',
        inheritedAccess: KnowledgeBaseAccess.Editor,
        allowedAccesses: [KnowledgeBaseAccess.Editor],
      },
      // No editor permission of its own, so it can only be a reader or nothing.
      {
        roleId: '2',
        roleName: 'Agent',
        inheritedAccess: null,
        allowedAccesses: [KnowledgeBaseAccess.Reader, KnowledgeBaseAccess.None],
      },
      // The parent denies access, so nothing below it can grant any.
      {
        roleId: '3',
        roleName: 'Customer',
        inheritedAccess: KnowledgeBaseAccess.None,
        allowedAccesses: [KnowledgeBaseAccess.None],
      },
    ]

    it('disables every access a role may not be given', async () => {
      const view = await renderPermissionsInput({ permissionRows: lockedRows })

      expect(view.getByLabelText('Admin - Editor')).toBeEnabled()
      expect(view.getByLabelText('Admin - Reader')).toBeDisabled()
      expect(view.getByLabelText('Admin - None')).toBeDisabled()

      expect(view.getByLabelText('Agent - Editor')).toBeDisabled()
      expect(view.getByLabelText('Agent - Reader')).toBeEnabled()
      expect(view.getByLabelText('Agent - None')).toBeEnabled()

      expect(view.getByLabelText('Customer - None')).toBeEnabled()
      expect(view.getByLabelText('Customer - Editor')).toBeDisabled()
    })

    it('does not change the value when a locked access is clicked', async () => {
      const view = await renderPermissionsInput({
        permissionRows: lockedRows,
        value: { '2': KnowledgeBaseAccess.Reader },
      })

      await view.events.click(view.getByLabelText('Agent - Editor'))

      expect(view.getByLabelText('Agent - Reader')).toBeChecked()
      expect(view.emitted().inputRaw).toBeFalsy()
    })

    // A disabled control with no explanation leaves the user guessing why. The reason rides in
    //   `aria-description` rather than `aria-label`, which the cell label already owns.
    it('says why an access is locked', async () => {
      const view = await renderPermissionsInput({ permissionRows: lockedRows })

      const reasonOf = (label: string) =>
        view.getByLabelText(label).closest('label')?.getAttribute('aria-description')

      expect(reasonOf('Admin - Reader')).toBe('The parent already grants this role editor access.')
      expect(reasonOf('Customer - Editor')).toBe('The parent denies this role access.')
      expect(reasonOf('Agent - Editor')).toBe('This role has no knowledge base editor permission.')

      // An access that may be picked is not explained away.
      expect(reasonOf('Agent - Reader')).toBeNull()
    })
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Fields - Knowledge Base Permissions - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderPermissionsInput({
      id: 'test_id',
    })

    expect(view.getByLabelText('Knowledge base permissions')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const view = await renderPermissionsInput({
      name: 'test_name',
    })

    expect(view.getByLabelText('Knowledge base permissions')).toHaveAttribute('name', 'test_name')
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderPermissionsInput({
      onBlur: blurHandler,
    })

    view.getByLabelText('Admin - Editor').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const view = await renderPermissionsInput()

    const radio = view.getByLabelText('Admin - Reader')

    await view.events.click(radio)

    expect(radio).toBeChecked()

    await waitFor(() => {
      expect(view.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual({ '1': KnowledgeBaseAccess.Reader })

    await waitFor(() => {
      expect(getNode('kbPermissions')?.value).toEqual({ '1': KnowledgeBaseAccess.Reader })
    })
  })

  it('implements input value display', async () => {
    const view = await renderPermissionsInput({
      value: testValue,
    })

    expect(view.getByLabelText('Admin - Editor')).toBeChecked()
    expect(view.getByLabelText('Admin - Reader')).not.toBeChecked()
    expect(view.getByLabelText('Admin - None')).not.toBeChecked()

    expect(view.getByLabelText('Agent - Reader')).toBeChecked()
    expect(view.getByLabelText('Agent - None')).not.toBeChecked()
  })

  it('implements disabled', async () => {
    const view = await renderPermissionsInput({
      disabled: true,
    })

    expect(view.getByLabelText('Knowledge base permissions')).toBeDisabled()

    view.getAllByRole('radio').forEach((radio) => {
      expect(radio).toBeDisabled()
    })
  })

  it('implements attribute passthrough', async () => {
    const view = await renderPermissionsInput({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Knowledge base permissions')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderPermissionsInput()

    expect(view.getByLabelText('Knowledge base permissions')).toHaveClass('formkit-input')
  })
})
