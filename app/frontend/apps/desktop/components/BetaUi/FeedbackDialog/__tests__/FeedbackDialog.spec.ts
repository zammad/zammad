// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumBetaUiFeedbackType } from '#shared/graphql/types.ts'

import { waitForBetaUiSendFeedbackMutationCalls } from '../../graphql/mutations/betaUiSendFeedback.mocks.ts'
import FeedbackDialog from '../FeedbackDialog.vue'
import { EnumFeedbackDialog } from '../useFeedbackDialog.ts'

const closeDialogMock = vi.hoisted(() => vi.fn())

vi.mock('#desktop/components/CommonDialog/useDialog.ts', async (originalModule) => {
  const module =
    await originalModule<typeof import('#desktop/components/CommonDialog/useDialog.ts')>()

  return {
    ...module,
    closeDialog: closeDialogMock,
  }
})

const renderFeedbackDialog = (props = {}) =>
  renderComponent(FeedbackDialog, {
    dialog: true,
    form: true,
    router: true,
    props,
  })

describe('FeedbackDialog', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  describe('never ask again functionality', () => {
    it('sets never ask again when checkbox is checked and form is submitted', async () => {
      const timeSpent = 5 * 60 * 60 * 1000 // 5 hours
      localStorage.setItem('app-usage-total-time', timeSpent.toString())

      const wrapper = renderFeedbackDialog({ milestone: '5h' })

      await wrapper.events.click(
        await wrapper.findByRole('checkbox', { name: 'Never ask me again' }),
      )

      const comment = wrapper.getByRole('textbox', { name: 'Comment' })
      await wrapper.events.type(comment, 'Test feedback')

      await wrapper.events.click(wrapper.getByTestId('field-rating-star-5'))
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Send feedback' }))

      await waitForBetaUiSendFeedbackMutationCalls()

      expect(localStorage.getItem('beta-ui-feedback-never-ask-again-timed')).toBe('true')
    })

    it('sets never ask again when checkbox is checked and dialog is skipped', async () => {
      const wrapper = renderFeedbackDialog({ milestone: '5h' })

      await wrapper.events.click(
        await wrapper.findByRole('checkbox', { name: 'Never ask me again' }),
      )
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Skip' }))

      expect(localStorage.getItem('beta-ui-feedback-never-ask-again-timed')).toBe('true')
    })

    it('does not set never ask again when checkbox is not checked', async () => {
      const timeSpent = 5 * 60 * 60 * 1000 // 5 hours
      localStorage.setItem('app-usage-total-time', timeSpent.toString())

      const wrapper = renderFeedbackDialog({ milestone: '5h' })

      const comment = await wrapper.findByRole('textbox', { name: 'Comment' })
      await wrapper.events.type(comment, 'Test feedback')

      await wrapper.events.click(wrapper.getByTestId('field-rating-star-5'))
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Send feedback' }))

      await waitForBetaUiSendFeedbackMutationCalls()

      expect(localStorage.getItem('beta-ui-feedback-never-ask-again-timed')).toBe('false')
    })
  })

  describe('dialog actions', () => {
    it('closes the dialog when clicking skip', async () => {
      const wrapper = renderFeedbackDialog()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Skip' }))

      expect(closeDialogMock).toHaveBeenCalledWith(EnumFeedbackDialog.Generic, true)
    })
  })

  describe('form submission', () => {
    it('submits timed feedback with correct data', async () => {
      const timeSpent = 5 * 60 * 60 * 1000 // 5 hours
      localStorage.setItem('app-usage-total-time', timeSpent.toString())

      const wrapper = renderFeedbackDialog({ milestone: '5h' })

      const comment = await wrapper.findByRole('textbox', { name: 'Comment' })
      await wrapper.events.type(comment, 'Great app you guys rock!')

      await wrapper.events.click(wrapper.getByTestId('field-rating-star-5'))
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Send feedback' }))

      const calls = await waitForBetaUiSendFeedbackMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          comment: 'Great app you guys rock!',
          rating: 5,
          timeSpent: timeSpent / 60_000, // in minutes
          type: EnumBetaUiFeedbackType.MilestoneQuestion,
        },
      })
    })

    it('submits manual feedback with correct data', async () => {
      const timeSpent = 5 * 60 * 60 * 1000 // 5 hours
      localStorage.setItem('app-usage-total-time', timeSpent.toString())

      const wrapper = renderFeedbackDialog()

      const comment = await wrapper.findByRole('textbox', { name: 'Comment' })
      await wrapper.events.type(comment, 'Great app you guys rock!')

      await wrapper.events.click(wrapper.getByTestId('field-rating-star-5'))
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Send feedback' }))

      const calls = await waitForBetaUiSendFeedbackMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          comment: 'Great app you guys rock!',
          rating: 5,
          timeSpent: timeSpent / 60_000, // in minutes
          type: EnumBetaUiFeedbackType.ManualFeedback,
        },
      })
    })
  })
})
