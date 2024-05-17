// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByRole } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchAgentQuery,
  waitForAutocompleteSearchAgentQueryCalls,
} from '#shared/components/Form/fields/FieldAgent/graphql/queries/autocompleteSearch/agent.mocks.ts'
import type { AutocompleteSearchUserEntry } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForUserCurrentOutOfOfficeMutationCalls } from '../graphql/mutations/userCurrentOutOfOffice.mocks.ts'

const agentAutocompleteOptions = [
  {
    __typename: 'AutocompleteSearchUserEntry',
    value: 1,
    label: 'foo',
    disabled: false,
    user: nullableMock({
      id: convertToGraphQLId('User', 1),
      internalId: 1,
      fullname: 'sample 1',
    }),
  },
  {
    __typename: 'AutocompleteSearchUserEntry',
    value: 2,
    label: 'bar',
    disabled: false,
    user: nullableMock({
      id: convertToGraphQLId('User', 2),
      internalId: 2,
      fullname: 'sample 1',
    }),
  },
] as AutocompleteSearchUserEntry[]

describe('Out of Office page', () => {
  describe('when enabled', () => {
    beforeEach(() => {
      mockUserCurrent({
        id: '123',
        internalId: 1,
        firstname: 'John',
        lastname: 'Doe',
        outOfOffice: true,
        preferences: { out_of_office_text: 'OOF holiday' },
        outOfOfficeStartAt: '2024-03-01',
        outOfOfficeEndAt: '2024-04-01',
        outOfOfficeReplacement: {
          id: convertToGraphQLId('User', 256),
          internalId: 256,
          fullname: 'Example Agent',
        },
      })
    })

    it('loads current Out of Office settings', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      expect(view.getByLabelText('Reason for absence')).toHaveValue(
        'OOF holiday',
      )
      expect(view.getByLabelText('Start and end date')).toHaveValue(
        '2024-03-01 - 2024-04-01',
      )
      expect(view.getByLabelText('Replacement agent')).toHaveValue(
        'Example Agent',
      )
      expect(view.getByLabelText('Active')).toBeChecked()
    })

    it('loads data updated elsewhere', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      expect(view.getByLabelText('Reason for absence')).toHaveValue(
        'OOF holiday',
      )

      mockUserCurrent({
        firstname: 'John',
        lastname: 'Doe',
        outOfOffice: true,
        preferences: { out_of_office_text: '' },
        outOfOfficeStartAt: '2024-03-01',
        outOfOfficeEndAt: '2024-04-01',
        outOfOfficeReplacement: {
          id: convertToGraphQLId('User', 256),
          internalId: 256,
          fullname: 'Example Agent',
        },
      })

      await waitForNextTick()

      expect(view.getByLabelText('Reason for absence')).toHaveValue('')
    })

    it('does not reset form if unrelated data was updated', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      expect(view.getByLabelText('Reason for absence')).toHaveValue(
        'OOF holiday',
      )

      const input = view.getByLabelText('Reason for absence')
      await view.events.clear(input)
      await view.events.type(input, 'new label')

      mockUserCurrent({
        firstname: 'John II',
        lastname: 'Doe',
        outOfOffice: true,
        preferences: { out_of_office_text: 'OOF holiday' },
        outOfOfficeStartAt: '2024-03-01',
        outOfOfficeEndAt: '2024-04-01',
        outOfOfficeReplacement: {
          id: convertToGraphQLId('User', 256),
          internalId: 256,
          fullname: 'Example Agent',
        },
      })

      await waitForNextTick()

      expect(view.getByLabelText('Reason for absence')).toHaveValue('new label')
    })

    it('shows success notification', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      await view.events.click(view.getByText('Save Out of Office'))

      expect(
        view.getByText('Out of Office settings have been saved successfully'),
      ).toBeInTheDocument()
    })

    it('can clear label', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Reason for absence')
      await view.events.clear(input)

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            text: '',
          }),
        }),
      )
    })

    it('cannot set date range to blank', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Start and end date')
      const button = getByRole(input.parentElement!, 'button')
      await view.events.click(button)

      await view.events.click(view.getByText('Save Out of Office'))

      expect(input).toBeDescribedBy('This field is required.')
    })

    it('cannot set replacement agent to blank', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Replacement agent')
      const button = getByRole(input, 'button')
      await view.events.click(button)

      await view.events.click(view.getByText('Save Out of Office'))

      expect(input).toBeDescribedBy('This field is required.')
    })

    it('cannot set replacement agent to themselves', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const inputAgent = view.getByLabelText('Replacement agent')

      await view.events.click(inputAgent)

      const filterElement = getByRole(inputAgent, 'searchbox')

      mockAutocompleteSearchAgentQuery({
        autocompleteSearchAgent: agentAutocompleteOptions,
      })

      await view.events.type(filterElement, '*')

      const calls = await waitForAutocompleteSearchAgentQueryCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: expect.objectContaining({
          exceptInternalId: 1,
        }),
      })
    })

    it('can disable Out of Office', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Active')
      await view.events.click(input)

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            enabled: false,
          }),
        }),
      )
    })

    it('can disable Out of Office and unset settings', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const inputActivated = view.getByLabelText('Active')
      await view.events.click(inputActivated)

      const inputDate = view.getByLabelText('Start and end date')
      const buttonDate = getByRole(inputDate.parentElement!, 'button')
      await view.events.click(buttonDate)

      const inputLabel = view.getByLabelText('Reason for absence')
      await view.events.clear(inputLabel)

      const inputAgent = view.getByLabelText('Replacement agent')
      const buttonAgent = getByRole(inputAgent, 'button')
      await view.events.click(buttonAgent)

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            enabled: false,
            text: '',
            startAt: undefined,
            endAt: undefined,
            replacementId: undefined,
          }),
        }),
      )
    })
  })

  describe('when disabled', () => {
    beforeEach(() => {
      mockUserCurrent({
        firstname: 'John',
        lastname: 'Doe',
        outOfOffice: false,
        outOfOfficeStartAt: '',
        outOfOfficeEndAt: '',
        outOfOfficeReplacement: null,
      })
    })

    it('loads current Out of Office settings', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      expect(view.getByLabelText('Reason for absence')).toHaveValue('')
      expect(view.getByLabelText('Start and end date')).toHaveValue('')
      expect(view.getByLabelText('Replacement agent')).toHaveValue('')
      expect(view.getByLabelText('Active')).not.toBeChecked()
    })

    it('can set date range', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Start and end date')
      await view.events.type(input, '2024-01-02 - 2024-02-02')
      await view.events.keyboard('{Enter}')

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            startAt: '2024-01-02',
            endAt: '2024-02-02',
          }),
        }),
      )
    })

    it('can set replacement agent', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const inputAgent = view.getByLabelText('Replacement agent')

      await view.events.click(inputAgent)

      const filterElement = getByRole(inputAgent, 'searchbox')

      mockAutocompleteSearchAgentQuery({
        autocompleteSearchAgent: [agentAutocompleteOptions[0]],
      })

      await view.events.type(filterElement, agentAutocompleteOptions[0].label)

      await waitForAutocompleteSearchAgentQueryCalls()

      await view.events.click(view.getAllByRole('option')[0])

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            replacementId: convertToGraphQLId(
              'User',
              agentAutocompleteOptions[0].value,
            ),
          }),
        }),
      )
    })

    it('can enable Out of Office with settings', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const inputLabel = view.getByLabelText('Active')
      await view.events.click(inputLabel)

      const inputDate = view.getByLabelText('Start and end date')
      await view.events.type(inputDate, '2024-01-02 - 2024-02-02')
      await view.events.keyboard('{Enter}')

      const inputAgent = view.getByLabelText('Replacement agent')

      await view.events.click(inputAgent)

      const filterElement = getByRole(inputAgent, 'searchbox')

      mockAutocompleteSearchAgentQuery({
        autocompleteSearchAgent: [agentAutocompleteOptions[0]],
      })

      await view.events.type(filterElement, agentAutocompleteOptions[0].label)

      await waitForAutocompleteSearchAgentQueryCalls()

      await view.events.click(view.getAllByRole('option')[0])

      await view.events.click(view.getByText('Save Out of Office'))

      const calls = await waitForUserCurrentOutOfOfficeMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            startAt: '2024-01-02',
            endAt: '2024-02-02',
            replacementId: convertToGraphQLId(
              'User',
              agentAutocompleteOptions[0].value,
            ),
            enabled: true,
          }),
        }),
      )
    })

    it('cannot enable Out of Office without date range and replacement agent', async () => {
      const view = await visitView('/personal-setting/out-of-office')

      const input = view.getByLabelText('Active')
      await view.events.click(input)

      await view.events.click(view.getByText('Save Out of Office'))

      const inputDate = view.getByLabelText('Start and end date')
      expect(inputDate).toBeDescribedBy('This field is required.')
    })
  })
})
