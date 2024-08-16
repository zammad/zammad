// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ApolloError } from '@apollo/client/errors'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import UserError from '#shared/errors/UserError.ts'
import { handleUserErrors } from '#shared/errors/utils.ts'

describe('errpr utils', () => {
  describe('handleUserErrors', () => {
    beforeEach(() => {
      useNotifications().clearAllNotifications()
    })

    it('displays a error toast for a UserError', () => {
      const userErrors = [
        {
          field: null,
          message: 'Example error message',
        },
        {
          field: 'id',
          message: 'Id field is wrong',
        },
      ]
      const userErrorObject = new UserError(userErrors)

      handleUserErrors(userErrorObject)

      const { notifications } = useNotifications()

      expect(notifications.value.length).toBe(1)
      expect(notifications.value[0].message).toBe('Example error message')
    })

    it('ignore npne UserErrors', () => {
      handleUserErrors(new ApolloError({ errorMessage: 'Some error' }))

      const { notifications } = useNotifications()

      expect(notifications.value.length).toBe(0)
    })
  })
})
