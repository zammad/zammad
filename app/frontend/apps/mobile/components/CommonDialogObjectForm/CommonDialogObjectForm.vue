<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectLike } from '@shared/types/utils'
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
import type { OperationMutationFunction } from '@shared/types/server/apollo/handler'
import { MutationHandler } from '@shared/server/apollo/handler'
import Form from '@shared/components/Form/Form.vue'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { useConfirmationDialog } from '../CommonConfirmation'

export interface Props {
  name: string
  object?: ObjectLike
  type: EnumObjectManagerObjects
  formUpdaterId?: EnumFormUpdaterId
  formChangeFields?: Record<string, Partial<FormSchemaField>>
  errorNotificationMessage?: string
  mutation: OperationMutationFunction
  schema: FormSchemaNode[]
  keyMap?: Record<string, string | false>
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

const updateMutation = new MutationHandler(props.mutation({}), {
  errorNotificationMessage: props.errorNotificationMessage,
})
const { form, isDirty, isDisabled, canSubmit } = useForm()

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

const { attributesLookup: objectAttributesLookup } = useObjectAttributes(
  props.type,
)
const { waitForConfirmation } = useConfirmationDialog()

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
  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(
      objectAttributesLookup.value,
      formData,
      props.keyMap,
    )

  const result = await updateMutation.send({
    id: props.object?.id,
    input: {
      ...internalObjectAttributeValues,
      objectAttributeValues: additionalObjectAttributeValues,
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
  <CommonDialog class="w-full" no-autofocus :name="name">
    <template #before-label>
      <button
        class="text-white"
        :disabled="isDisabled"
        :class="{ 'opacity-50': isDisabled }"
        @click="cancelDialog"
      >
        {{ $t('Cancel') }}
      </button>
    </template>
    <template #after-label>
      <button
        :form="name"
        class="text-blue"
        :disabled="!canSubmit"
        :class="{ 'opacity-50': !canSubmit }"
      >
        {{ $t('Save') }}
      </button>
    </template>
    <Form
      :id="name"
      ref="form"
      class="w-full p-4"
      autofocus
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
