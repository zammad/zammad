<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { EnumBetaUiFeedbackType } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import CommonDialogActionFooter from '#desktop/components/CommonDialog/CommonDialogActionFooter.vue'
import { closeDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

import { useBetaUiSendFeedbackMutation } from '../graphql/mutations/betaUiSendFeedback.api.ts'

import { EnumFeedbackDialog } from './useFeedbackDialog.ts'

import type { FeedbackFormData } from './types.ts'

interface Props {
  callback?: () => void
}

const props = defineProps<Props>()

const schema = markRaw([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'comment',
        type: 'textarea',
        label: __('Can you tell us what are you missing in the BETA UI?'),
        props: { rows: 4 },
        classes: { outer: 'text-left' },
        help: __('Your answer will be submitted to Zammad GmbH in an anonymized way.'),
        required: true,
      },
    ],
  },
] as FormSchemaNode[])

const appUsage = useAppUsageStore()

const { form, formNodeId } = useForm()

const feedbackMutation = new MutationHandler(useBetaUiSendFeedbackMutation(), {
  errorShowNotification: false, // display of error messages is handled by a form alert
})

const close = () => {
  props.callback?.()

  closeDialog(EnumFeedbackDialog.SwitchBack, true)
}

const submitFeedback = async (data: FeedbackFormData) => {
  const timeSpendInMinutes = Math.round(appUsage.totalAppUsageTime / 60_000) // milliseconds to minutes

  await feedbackMutation.send({
    input: {
      comment: data.comment,
      timeSpent: timeSpendInMinutes,
      type: EnumBetaUiFeedbackType.BackToOldUi,
    },
  })

  close()
}
</script>

<template>
  <CommonDialog
    class="max-w-lg"
    :name="EnumFeedbackDialog.SwitchBack"
    :header-title="__('Reason to switch back')"
    fullscreen
    global
    @close="close"
  >
    <Form ref="form" :schema="schema" @submit="submitFeedback($event as FeedbackFormData)" />
    <CommonLabel class="mt-3 text-start">
      {{
        $t(
          'You can return to the new BETA UI using the switch at the bottom of your taskbar or in your profile settings.',
        )
      }}
    </CommonLabel>
    <template #footer>
      <CommonDialogActionFooter
        :action-label="__('Send feedback & switch back')"
        :cancel-label="__('Just switch back')"
        :form-node-id="formNodeId"
        @cancel="close"
      />
    </template>
  </CommonDialog>
</template>
