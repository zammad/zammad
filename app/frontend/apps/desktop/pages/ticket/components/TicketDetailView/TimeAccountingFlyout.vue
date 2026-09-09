<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import {
  normalizeTimeAccountingUnit,
  useTicketTimeAccountingForm,
} from '#shared/entities/ticket/composables/useTicketTimeAccountingForm.ts'
import type { TicketArticleTimeAccountingFormData } from '#shared/entities/ticket/types.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

const emit = defineEmits<{
  'account-time': [TicketArticleTimeAccountingFormData]
  skip: []
}>()

const { form } = useForm()

const flyoutName = 'ticket-time-accounting'

const submitForm = (formData: FormSubmitData<TicketArticleTimeAccountingFormData>) => {
  if (formData.time_unit) {
    formData.time_unit = normalizeTimeAccountingUnit(formData.time_unit)
  }
  emit('account-time', formData)
  closeFlyout(flyoutName)
}

const onClose = (isCancel?: boolean) => {
  if (!isCancel) return
  emit('skip')
}

const { timeAccountingDisplayUnit, timeAccountingSchemaData, buildTimeAccountingFormSchema } =
  useTicketTimeAccountingForm()

const formSchema = buildTimeAccountingFormSchema(
  timeAccountingDisplayUnit.value
    ? {
        sectionsSchema: {
          suffix: {
            $el: 'span',
            children: i18n.t(timeAccountingDisplayUnit.value),
            attrs: {
              class:
                'py-2.5 px-2.5 outline outline-1 -outline-offset-1 outline-blue-200 dark:outline-gray-700 bg-neutral-50 dark:bg-gray-500 rounded-e-md text-gray-100 dark:text-neutral-400',
            },
          },
        },
      }
    : {},
)

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionLabel: __('Account time'),
  actionButton: { variant: 'submit', type: 'submit' },
  cancelLabel: __('Skip'),
}))
</script>

<template>
  <CommonFlyout
    :header-title="__('Time accounting')"
    :form="form"
    :footer-action-options="footerActionOptions"
    header-icon="stopwatch"
    :name="flyoutName"
    no-close-on-action
    @close="onClose"
  >
    <div class="flex flex-col gap-3">
      <Form
        id="form-ticket-time-accounting"
        ref="form"
        :schema="formSchema"
        :schema-data="timeAccountingSchemaData"
        should-autofocus
        :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketTimeAccounting"
        form-updater-initial-only
        @submit="submitForm($event as FormSubmitData<TicketArticleTimeAccountingFormData>)"
      />
    </div>
  </CommonFlyout>
</template>
