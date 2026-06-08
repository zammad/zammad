<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { EnumBetaUiFeedbackType } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import CommonDialogActionFooter from '#desktop/components/CommonDialog/CommonDialogActionFooter.vue'
import { closeDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import { useAppUsageStore } from '#desktop/stores/appUsage.ts'
import type { MilestoneKey } from '#desktop/types/appUsage.ts'

import { useBetaUiSendFeedbackMutation } from '../graphql/mutations/betaUiSendFeedback.api.ts'

import { EnumFeedbackDialog } from './useFeedbackDialog.ts'

import type { FeedbackFormData } from './types.ts'

interface Props {
  milestone?: MilestoneKey
}

const props = defineProps<Props>()

const translatedMilestones: Record<MilestoneKey, string> = {
  '1h': __('1 hour'),
  '5h': __('5 hours'),
  '20h': __('20 hours'),
}

const schema = markRaw([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'rating',
        type: 'rating',
        label: props.milestone
          ? i18n.t(
              'You were using the new BETA UI for %s. Considering that, how would you rate your experience so far?',
              translatedMilestones[props.milestone],
            )
          : __('Your rating of the new BETA UI'),
        classes: { outer: 'flex flex-col justify-center text-balance max-w-lg' },
        required: true,
      },
      {
        name: 'comment',
        type: 'textarea',
        label: __('Comment'),
        props: { rows: 4 },
        classes: { outer: 'text-left' },
        help: __('Your answer will be submitted to Zammad GmbH in an anonymized way.'),
        required: true,
      },
      {
        name: 'neverAskAgain',
        type: 'checkbox',
        label: __('Never ask me again'),
        classes: { outer: 'text-left flex flex-col gap-1', help: 'max-w-md' },
        hidden: !props.milestone,
        help: __('You can send feedback from the BETA button or profile settings.'),
        sectionsSchema: {
          help: {
            if: 'true',
            children: {
              if: '$value',
              then: '$help',
              else: '\u00A0', // Non-breaking space to keep the layout and prevent jumping
            },
          },
        },
        value: false,
      },
    ],
  },
] as FormSchemaNode[])

const appUsage = useAppUsageStore()

const { form, formNodeId, values } = useForm()

const feedbackMutation = new MutationHandler(useBetaUiSendFeedbackMutation(), {
  errorShowNotification: false, // display of error messages is handled by a form alert
})

const close = () => closeDialog(EnumFeedbackDialog.Generic, true)

const closeAndVerifyIfAskAgain = () => {
  if (values.value.neverAskAgain) appUsage.setNeverAskAgainForTimedFeedback()

  close()
}

const submitFeedback = async (data: FeedbackFormData) => {
  const timeSpendInMinutes = Math.round(appUsage.totalAppUsageTime / 60_000) // milliseconds to minutes

  await feedbackMutation.send({
    input: {
      comment: data.comment,
      rating: Number(data.rating),
      timeSpent: timeSpendInMinutes,
      type: props.milestone
        ? EnumBetaUiFeedbackType.MilestoneQuestion
        : EnumBetaUiFeedbackType.ManualFeedback,
    },
  })

  closeAndVerifyIfAskAgain()
}
</script>

<template>
  <CommonDialog
    :name="EnumFeedbackDialog.Generic"
    :header-title="__('Send feedback on the BETA UI')"
    fullscreen
    global
    @close="close"
  >
    <Form ref="form" :schema="schema" @submit="submitFeedback($event as FeedbackFormData)" />

    <template #footer>
      <CommonDialogActionFooter
        :action-label="__('Send feedback')"
        :cancel-label="__('Skip')"
        :form-node-id="formNodeId"
        @cancel="closeAndVerifyIfAskAgain"
      />
    </template>
  </CommonDialog>
</template>
