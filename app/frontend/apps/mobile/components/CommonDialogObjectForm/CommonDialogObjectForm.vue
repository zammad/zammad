<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { UseMutationReturn } from '@vue/apollo-composable'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import {
  type FormSchemaNode,
  type FormData,
  useForm,
} from '@shared/components/Form'
import { closeDialog } from '@shared/composables/useDialog'
import type {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  ObjectAttributeValue,
} from '@shared/graphql/types'
import type {
  FormFieldValue,
  FormSchemaField,
} from '@shared/components/Form/types'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { ObjectLike } from '@shared/types/utils'
import Form from '@shared/components/Form/Form.vue'
import { camelize } from '@shared/utils/formatter'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import useConfirmation from '../CommonConfirmation/composable'

export interface Props {
  name: string
  object?: ObjectLike
  type: EnumObjectManagerObjects
  formUpdaterId?: EnumFormUpdaterId
  formChangeFields?: Record<string, Partial<FormSchemaField>>
  errorNotificationMessage?: string
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  mutation: UseMutationReturn<any, any>
  schema: FormSchemaNode[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'success', data: unknown): void
  (e: 'error'): void
  (
    e: 'changedField',
    fieldName: string,
    newValue: FormFieldValue,
    oldValue: FormFieldValue,
  ): void
}>()

const updateQuery = new MutationHandler(props.mutation, {
  errorNotificationMessage: props.errorNotificationMessage,
})
const { form, isDirty, isDisabled, formSubmit } = useForm()

const objectAtrributes: Record<string, string> =
  props.object?.objectAttributeValues?.reduce(
    (acc: Record<string, string>, cur: ObjectAttributeValue) => {
      acc[cur.attribute.name] = cur.value
      return acc
    },
    {},
  ) || {}

const initialFlatObject = {
  ...props.object,
  ...objectAtrributes,
}

const { attributes: objectAttributes } = useObjectAttributes(props.type)
const { waitForConfirmation } = useConfirmation()

const cancelDialog = async () => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have unsaved changes that will get lost.'),
    )

    if (!confirmed) return
  }

  closeDialog(props.name)
}

const changedFormField = (
  fieldName: string,
  newValue: FormFieldValue,
  oldValue: FormFieldValue,
) => {
  emit('changedField', fieldName, newValue, oldValue)
}

const saveObject = async (formData: FormData) => {
  const objectAttributeValues = objectAttributes.value
    .filter(({ isInternal }) => !isInternal)
    .map(({ name }) => {
      return {
        name,
        value: formData[name],
      }
    })

  const skip = new Set(['id', 'formId', ...Object.keys(objectAtrributes)])
  const input: Record<string, unknown> = {}

  // eslint-disable-next-line no-restricted-syntax
  for (const key in formData) {
    if (!skip.has(key)) {
      input[camelize(key)] = formData[key]
    }
  }

  const result = await updateQuery.send({
    id: props.object?.id,
    input: {
      ...input,
      objectAttributeValues,
    },
  })

  if (result) {
    emit('success', result)
    closeDialog(props.name)
  } else {
    emit('error')
  }
}
</script>

<template>
  <CommonDialog :name="name">
    <template #before-label>
      <button
        class="text-blue"
        :disabled="isDisabled"
        :class="{ 'opacity-50': isDisabled }"
        @click="cancelDialog"
      >
        {{ $t('Cancel') }}
      </button>
    </template>
    <template #after-label>
      <button
        class="text-blue"
        :disabled="isDisabled"
        :class="{ 'opacity-50': isDisabled }"
        @click="formSubmit"
      >
        {{ $t('Save') }}
      </button>
    </template>
    <Form
      :id="name"
      ref="form"
      class="w-full p-4"
      :schema="schema"
      :initial-entity-object="initialFlatObject"
      :change-fields="formChangeFields"
      use-object-attributes
      :form-updater-id="formUpdaterId"
      @changed="changedFormField"
      @submit="saveObject"
    />
  </CommonDialog>
</template>
