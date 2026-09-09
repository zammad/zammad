<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
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

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#mobile/composables/useDialog.ts'

interface Props {
  name: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'account-time': [TicketArticleTimeAccountingFormData]
  skip: []
  cancel: []
}>()

const { form, canSubmit } = useForm()

const { timeAccountingDisplayUnit, timeAccountingSchemaData, buildTimeAccountingFormSchema } =
  useTicketTimeAccountingForm()

// The configured unit is not part of the value, it only tells the agent what to enter.
const formSchema = buildTimeAccountingFormSchema(
  timeAccountingDisplayUnit.value
    ? {
        sectionsSchema: {
          suffix: {
            $el: 'span',
            children: i18n.t(timeAccountingDisplayUnit.value),
            attrs: {
              class: 'flex items-center text-base text-gray-100',
            },
          },
        },
      }
    : {},
)

const submitForm = (formData: FormSubmitData<TicketArticleTimeAccountingFormData>) => {
  if (formData.time_unit) {
    formData.time_unit = normalizeTimeAccountingUnit(formData.time_unit)
  }

  emit('account-time', formData)

  closeDialog(props.name)
}

const skipTimeAccounting = () => {
  emit('skip')

  closeDialog(props.name)
}

const cancelTimeAccounting = () => {
  emit('cancel')

  closeDialog(props.name)
}
</script>

<template>
  <CommonDialog
    class="w-full"
    no-autofocus
    :name="name"
    :label="__('Time accounting')"
    @close="emit('cancel')"
  >
    <template #before-label>
      <CommonButton transparent-background @click="cancelTimeAccounting">
        {{ $t('Cancel') }}
      </CommonButton>
    </template>
    <template #after-label>
      <CommonButton variant="primary" transparent-background @click="skipTimeAccounting">
        {{ $t('Skip') }}
      </CommonButton>
    </template>
    <Form
      :id="name"
      ref="form"
      class="w-full p-4"
      should-autofocus
      :schema="formSchema"
      :schema-data="timeAccountingSchemaData"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketTimeAccounting"
      form-updater-initial-only
      @submit="submitForm($event as FormSubmitData<TicketArticleTimeAccountingFormData>)"
    />
    <div class="mt-auto w-full bg-gray-600/90 pb-safe">
      <div class="flex justify-end p-3">
        <CommonButton
          class="rounded-md! px-3 py-1"
          :form="name"
          :disabled="!canSubmit"
          variant="submit"
          type="submit"
        >
          {{ $t('Account time') }}
        </CommonButton>
      </div>
    </div>
  </CommonDialog>
</template>
