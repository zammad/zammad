// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getAllByRole, getByRole, queryByRole } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockUserAddMutation,
  waitForUserAddMutationCalls,
} from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup manual invite', () => {
  describe('when system is not ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })
    })

    it('redirects to guided setup start', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      const view = await visitView('/guided-setup/manual/invite')

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup start screen',
        ).toHaveCurrentUrl('/guided-setup')
      })
      view.getByText('Set up a new system')
    })
  })

  describe('when system is ready for optional steps', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
      mockPermissions(['admin'])
      mockAuthentication(true)

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            role_ids: {
              initialValue: [2],
              options: [
                {
                  value: 1,
                  label: 'Admin',
                  description: 'To configure your system.',
                },
                {
                  value: 2,
                  label: 'Agent',
                  description: 'To work on Tickets.',
                },
                {
                  value: 3,
                  label: 'Customer',
                  description: 'People who create Tickets ask for help.',
                },
              ],
            },
            group_ids: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'some group1',
                },
              ],
            },
          },
        },
      })
    })

    it('can invite user and rerender the form', async () => {
      const view = await visitView('/guided-setup/manual/invite')

      await flushPromises()

      expect(view.getByText('Invite Colleagues')).toBeInTheDocument()
      expect(view.getByLabelText('First name')).toBeInTheDocument()
      expect(view.getByLabelText('Last name')).toBeInTheDocument()
      expect(view.getByLabelText('Email')).toBeInTheDocument()
      expect(view.getByLabelText('Roles')).toBeInTheDocument()
      expect(view.getByLabelText('Group permissions')).toBeInTheDocument()

      expect(
        view.getByRole('button', { name: 'Finish Setup' }),
      ).toBeInTheDocument()

      await view.events.type(view.getByLabelText('Email'), 'test@example.com')
      await view.events.click(view.getAllByRole('switch')[2])

      const groupPermissions = view.getByLabelText('Group permissions')

      const combobox = getByRole(groupPermissions, 'combobox')

      await view.events.click(combobox)

      const listbox = view.getByRole('listbox')
      const options = getAllByRole(listbox, 'option')

      await view.events.click(options[0])
      await view.events.click(view.getByLabelText('Full'))

      expect(view.getByLabelText('Email')).toHaveValue('test@example.com')

      expect(view.getAllByRole('switch')[2]).toHaveAttribute(
        'aria-checked',
        'true',
      )

      expect(queryByRole(combobox, 'listitem')).toBeInTheDocument()
      expect(view.getByLabelText('Full')).toBeChecked()

      const inviteButton = view.getByRole('button', {
        name: 'Send Invitation',
      })

      await view.events.click(inviteButton)

      const calls = await waitForUserAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          firstname: '',
          lastname: '',
          email: 'test@example.com',
          roleIds: ['gid://zammad/Role/2', 'gid://zammad/Role/3'],
          groupIds: [
            {
              groupInternalId: 1,
              accessType: ['full'],
            },
          ],
          objectAttributeValues: [],
        },
        sendInvite: true,
      })

      expect(await view.findByText('Invitation sent!')).toBeInTheDocument()
      expect(view.getByLabelText('Email')).toHaveValue('')

      expect(view.getAllByRole('switch')[2]).not.toHaveAttribute(
        'aria-checked',
        'true',
      )

      expect(queryByRole(combobox, 'listitem')).not.toBeInTheDocument()
      expect(view.getByLabelText('Full')).not.toBeChecked()

      expect(
        view,
        'stays on the guided setup manual invite step',
      ).toHaveCurrentUrl('/guided-setup/manual/invite')
    })

    it('can display form errors', async () => {
      const view = await visitView('/guided-setup/manual/invite')

      mockUserAddMutation({
        userAdd: {
          user: null,
          errors: [
            {
              message:
                'At least one identifier (firstname, lastname, phone or email) for user is required.',
              field: null,
            },
          ],
        },
      })

      const inviteButton = view.getByRole('button', {
        name: 'Send Invitation',
      })

      await view.events.click(inviteButton)

      expect(
        view.getByText(
          'At least one identifier (firstname, lastname, phone or email) for user is required.',
        ),
      ).toHaveRole('alert')
    })

    it('redirects to guided setup finish screen when continued', async () => {
      const view = await visitView('/guided-setup/manual/invite')

      await view.events.click(
        view.getByRole('button', { name: 'Finish Setup' }),
      )

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup finish screen',
        ).toHaveCurrentUrl('/guided-setup/manual/finish')
      })
    })
  })
})
