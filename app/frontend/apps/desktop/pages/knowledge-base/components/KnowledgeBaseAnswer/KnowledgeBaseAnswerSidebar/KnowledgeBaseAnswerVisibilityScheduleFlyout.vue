<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { answerSchedulableVisibilityOptions } from '#desktop/entities/knowledge-base/form/answerVisibilityOptions.ts'
import { useKnowledgeBaseAnswerVisibilityScheduleAddMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleAdd.api.ts'

// Must match the name the section registers the flyout under.
const FLYOUT_NAME = 'knowledge-base-answer-visibility-schedule'

interface Props {
  answerId: string
}

const props = defineProps<Props>()

interface VisibilityScheduleFormData {
  visibility: EnumKnowledgeBaseSchedulableVisibility
  scheduledAt: string
}

const { form } = useForm()

const formSchema = [
  {
    // The same states the answer's own visibility field offers, minus `draft`: a state is stored as
    //   the date it is reached at, and `draft` is what no date at all means - there is nothing to
    //   put in the future for it. Which is also what the mutation's enum says.
    name: 'visibility',
    label: __('Visibility'),
    type: 'radioList',
    required: true,
    props: {
      options: answerSchedulableVisibilityOptions,
    },
  },
  {
    // A date that is not ahead is not a schedule: it would change the state at once, which is the
    //   edit form's business. The service refuses one either way, so this is about where the
    //   complaint lands - `futureOnly` only limits what the *picker* offers, and a date typed into
    //   the field's text input sails past it, so the rule is what actually holds. It puts the
    //   message on the field rather than at the top of the flyout, and saves the round trip.
    name: 'scheduledAt',
    label: __('Schedule for'),
    type: 'datetime',
    required: true,
    validation: 'date_after',
    props: {
      futureOnly: true,
      clearable: false,
    },
  },
]

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionButton: { variant: 'submit', type: 'submit' },
  actionLabel: __('Add schedule'),
  cancelLabel: __('Cancel & go back'),
}))

// No `errorNotificationMessage`: what the service refuses is worth reading - that the state has
//   already been reached, or that the changes would not run in the order they take effect - and a
//   generic "could not be added" would bury it.
const addMutation = new MutationHandler(useKnowledgeBaseAnswerVisibilityScheduleAddMutation({}))

const { notify } = useNotifications()

const addSchedule = async (formData: FormSubmitData<VisibilityScheduleFormData>) => {
  const result = await addMutation.send({
    answerId: props.answerId,
    visibility: formData.visibility,
    scheduledAt: formData.scheduledAt,
  })

  if (!result?.knowledgeBaseAnswerVisibilityScheduleAdd?.answer) return

  // Returned rather than run here, so the form is reset before the flyout goes.
  return () => {
    notify({
      type: NotificationTypes.Success,
      id: 'knowledge-base-answer-visibility-schedule-added',
      message: __('Visibility change scheduled successfully.'),
    })

    closeFlyout(FLYOUT_NAME)
  }
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Add visibility schedule')"
    header-icon="file-richtext"
    :name="FLYOUT_NAME"
    size="large"
    no-close-on-action
    :form="form"
    :footer-action-options="footerActionOptions"
  >
    <Form
      ref="form"
      :schema="formSchema"
      should-autofocus
      @submit="addSchedule($event as FormSubmitData<VisibilityScheduleFormData>)"
    />
  </CommonFlyout>
</template>
