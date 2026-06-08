// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumBetaUiFeedbackType } from '#shared/graphql/types.ts'

import { waitForBetaUiSendFeedbackMutationCalls } from '../../graphql/mutations/betaUiSendFeedback.mocks.ts'
import SwitchBackFeedbackDialog from '../SwitchBackFeedbackDialog.vue'
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

const callbackMock = vi.fn()

const renderSwitchBackFeedbackDialog = (props = {}) =>
  renderComponent(SwitchBackFeedbackDialog, {
    dialog: true,
    form: true,
    router: true,
    props: {
      callback: callbackMock,
      ...props,
    },
  })

describe('SwitchBackFeedbackDialog.vue', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  describe('dialog actions', () => {
    it('executes callback and closes the dialog when clicking just switch back', async () => {
      const wrapper = renderSwitchBackFeedbackDialog()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Just switch back' }))

      expect(callbackMock).toHaveBeenCalled()
      expect(closeDialogMock).toHaveBeenCalledWith(EnumFeedbackDialog.SwitchBack, true)
    })
  })

  describe('form submission', () => {
    it('submits switch back feedback with correct data', async () => {
      const timeSpent = 5 * 60 * 60 * 1000 // 5 hours
      localStorage.setItem('app-usage-total-time', timeSpent.toString())

      const wrapper = renderSwitchBackFeedbackDialog()

      const comment = await wrapper.findByRole('textbox', {
        name: 'Can you tell us what are you missing in the BETA UI?',
      })
      await wrapper.events.type(comment, 'nothing in particular, just testing!')

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Send feedback & switch back' }),
      )

      const calls = await waitForBetaUiSendFeedbackMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          comment: 'nothing in particular, just testing!',
          timeSpent: Math.round(timeSpent / 60_000), // in minutes
          type: EnumBetaUiFeedbackType.BackToOldUi,
        },
      })

      expect(callbackMock).toHaveBeenCalled()
      expect(closeDialogMock).toHaveBeenCalledWith(EnumFeedbackDialog.SwitchBack, true)
    })
  })
})
