<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { reactive, computed, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaField,
  FormFieldValue,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import type { OutOfOfficeInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentOutOfOfficeMutation } from '../graphql/mutations/userCurrentOutOfOffice.api.ts'

import type { OutOfOfficeFormData } from '../types/out-of-office.ts'

const { user } = storeToRefs(useSessionStore())

const { form, isDisabled, onChangedField, formReset, values, isDirty } =
  useForm()

const schema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'text',
        name: 'text',
        label: __('Reason for absence'),
        placeholder: __('e.g. Easter holiday'),
      },
      {
        type: 'date',
        name: 'date_range',
        label: __('Start and end date'),
        props: {
          clearable: true,
          range: true,
        },
      },
      {
        type: 'agent',
        name: 'replacement_id',
        label: __('Replacement agent'),
        props: {
          clearable: true,
          belongsToObjectField: 'outOfOfficeReplacement',
          exceptUserInternalId: user.value?.internalId,
        },
      },
      {
        type: 'toggle',
        name: 'enabled',
        label: __('Active'),
        props: {
          variants: {
            true: __('Active'),
            false: __('Inactive'),
          },
        },
      },
    ],
  },
])

const initialFormValues = computed<OutOfOfficeFormData>((oldValues) => {
  const values: OutOfOfficeFormData = {
    text: user.value?.preferences?.out_of_office_text,
    replacement_id: user.value?.outOfOfficeReplacement?.internalId,
    enabled: !!user.value?.outOfOffice,
  }

  if (user.value?.outOfOfficeStartAt && user.value?.outOfOfficeEndAt) {
    values.date_range = [
      user.value?.outOfOfficeStartAt,
      user.value?.outOfOfficeEndAt,
    ]
  }

  if (oldValues && isEqual(values, oldValues)) {
    return oldValues
  }

  return values
})

watch(initialFormValues, (newValues) => {
  // No reset needed when the form has already the correct state.
  if (isEqual(values.value, newValues) && !isDirty.value) return

  formReset(newValues, user.value!)
})

const buildFormChangesHash = (enabled: boolean) => {
  return {
    replacement_id: { required: enabled },
    date_range: { required: enabled },
  }
}

const formChangeFields = reactive<Record<string, Partial<FormSchemaField>>>(
  buildFormChangesHash(initialFormValues.value.enabled),
)

onChangedField('enabled', (newValue: FormFieldValue) => {
  Object.assign(formChangeFields, buildFormChangesHash(!!newValue))
})

const { breadcrumbItems } = useBreadcrumb(__('Out of Office'))

const formDataToInput = (
  formData: FormSubmitData<OutOfOfficeFormData>,
): OutOfOfficeInput => {
  const replacementId = formData.replacement_id
    ? convertToGraphQLId('User', formData.replacement_id)
    : undefined

  return {
    enabled: formData.enabled,
    text: formData.text,
    startAt: formData.date_range?.at(0),
    endAt: formData.date_range?.at(1),
    replacementId,
  }
}

const { notify } = useNotifications()

const showSuccessNotification = () => {
  notify({
    id: 'out-of-office-saved',
    type: NotificationTypes.Success,
    message: __('Out of Office settings have been saved successfully'),
  })
}

const outOfOfficeMutation = new MutationHandler(
  useUserCurrentOutOfOfficeMutation(),
  {
    errorNotificationMessage: __('Out of Office settings could not be saved.'),
  },
)

const submitForm = async (formData: FormSubmitData<OutOfOfficeFormData>) => {
  return outOfOfficeMutation
    .send({ input: formDataToInput(formData) })
    .then(() => showSuccessNotification)
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <div class="mb-4">
      <Form
        ref="form"
        :initial-values="initialFormValues"
        :initial-entity-object="user!"
        :schema="schema"
        :change-fields="formChangeFields"
        @submit="submitForm($event as FormSubmitData<OutOfOfficeFormData>)"
      >
        <template #after-fields>
          <div class="mt-5 flex items-center justify-end gap-2">
            <CommonButton
              variant="submit"
              type="submit"
              size="medium"
              :disabled="isDisabled"
            >
              {{ $t('Save Out of Office') }}
            </CommonButton>
          </div>
        </template>
      </Form>
    </div>
  </LayoutContent>
</template>
