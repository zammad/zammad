// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumAuthenticationProvider } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForUserCurrentRemoveLinkedAccountMutationCalls } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentLinkedAccount.mocks.ts'

describe('linked accounts page', () => {
  it('is not accessible if no providers are enabled', async () => {
    const view = await visitView('/personal-setting/linked-accounts')

    await waitFor(() => {
      expect(view, 'correctly redirects to error page').toHaveCurrentUrl('/error-tab')
    })
  })

  describe('with enabled providers', () => {
    beforeEach(() => {
      mockApplicationConfig({
        auth_facebook: true,
        auth_github: true,
      })
      mockUserCurrent({
        lastname: 'Doe',
        firstname: 'John',
        fullname: 'John Doe',
        id: convertToGraphQLId('User', 4),
        authorizations: [
          {
            __typename: 'Authorization',
            id: convertToGraphQLId('Authorization', 1),
            provider: EnumAuthenticationProvider.Github,
            uid: '85683661',
            username: 'foobar',
          },
        ],
      })
    })

    it('renders a list of authorization providers', async () => {
      const view = await visitView('/personal-setting/linked-accounts')

      expect(view.getByText('GitHub')).toBeInTheDocument() // application
      expect(view.getByText('foobar')).toBeInTheDocument() // username for GitHub
      expect(view.getByText('Facebook')).toBeInTheDocument() // application

      expect(view.getAllByIconName('plus-square-fill')).toHaveLength(1)
      expect(view.getAllByIconName('trash3')).toHaveLength(1)
    })

    it('links a new authorization provider', async (context) => {
      context.skipConsole = true
      const view = await visitView('/personal-setting/linked-accounts')

      expect(view.queryByLabelText('Link account on GitHub')).not.toBeInTheDocument()

      expect(view.getByLabelText('Remove account link on GitHub'))

      expect(view.queryByLabelText('Link account on Facebook')).toBeInTheDocument()

      await view.events.click(view.getByLabelText('Link account on Facebook'))
    })

    it('removes an authorization provider', async () => {
      const view = await visitView('/personal-setting/linked-accounts')

      // Removing asks first, so the trigger is not red; the confirm button inside the dialog is.
      const removeButton = view.getByLabelText('Remove account link on GitHub')

      expect(removeButton).toHaveClass('text-muted!')
      expect(removeButton).not.toHaveClass('text-red-500')

      await view.events.click(removeButton)

      expect(await view.findByRole('dialog', { name: 'Delete object' })).toBeInTheDocument()

      expect(view.getByText('Are you sure you want to delete this object?')).toBeInTheDocument()

      const confirmButton = view.getByRole('button', { name: 'Delete object' })

      expect(confirmButton).toHaveClass('bg-pink-100')

      await view.events.click(confirmButton)

      const mockCalls = await waitForUserCurrentRemoveLinkedAccountMutationCalls()

      expect(mockCalls[0].variables).toEqual({
        provider: EnumAuthenticationProvider.Github,
        uid: '85683661',
      })

      mockUserCurrent({
        lastname: 'Doe',
        firstname: 'John',
        fullname: 'John Doe',
        id: convertToGraphQLId('User', 4),
        authorizations: [],
      })

      await waitForNextTick()

      expect(view.queryByIconName('trash3')).not.toBeInTheDocument()
      expect(view.getAllByIconName('plus-square-fill')).toHaveLength(2)
    })
  })
})
