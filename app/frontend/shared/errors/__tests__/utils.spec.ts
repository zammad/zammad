// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloError } from '@apollo/client/errors'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import UserError from '#shared/errors/UserError.ts'
import { handleUserErrors, remapUserErrorFields } from '#shared/errors/utils.ts'

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

  describe('remapUserErrorFields', () => {
    it('relabels the listed fields and leaves the others alone', () => {
      const remapped = remapUserErrorFields(
        new UserError([
          { field: 'translations.title', message: 'has to be unique' },
          { field: 'category_icon', message: 'is required' },
          { field: null, message: 'Something went wrong.' },
        ]),
        { 'translations.title': 'title' },
      )

      expect(remapped.errors).toEqual([
        { field: 'title', message: 'has to be unique' },
        { field: 'category_icon', message: 'is required' },
        { field: null, message: 'Something went wrong.' },
      ])
    })

    // The notification the error may also raise is keyed by this id, so relabeling must not
    //   turn one failed submit into a second toast.
    it('keeps the user error id', () => {
      const userError = new UserError([
        { field: 'translations.title', message: 'has to be unique' },
      ])

      expect(remapUserErrorFields(userError, { 'translations.title': 'title' }).userErrorId).toBe(
        userError.userErrorId,
      )
    })

    it('passes anything that is not a user error through unchanged', () => {
      const error = new ApolloError({ errorMessage: 'Some error' })

      expect(remapUserErrorFields(error, { 'translations.title': 'title' })).toBe(error)
    })
  })
})
