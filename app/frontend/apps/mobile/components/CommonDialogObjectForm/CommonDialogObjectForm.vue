<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectLike } from '#shared/types/utils.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { closeDialog } from '#shared/composables/useDialog.ts'
import type {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  ObjectAttributeValue,
} from '#shared/graphql/types.ts'
import type {
  FormFieldValue,
  FormSchemaField,
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import Form from '#shared/components/Form/Form.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'

export interface Props {
  name: string
  object?: ObjectLike
  title?: string
  type: EnumObjectManagerObjects
  formUpdaterId?: EnumFormUpdaterId
  formChangeFields?: Record<string, Partial<FormSchemaField>>
  errorNotificationMessage?: string
  mutation: OperationMutationFunction
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

const updateMutation = new MutationHandler(props.mutation({}), {
  errorNotificationMessage: props.errorNotificationMessage,
})
const { form, isDirty, canSubmit } = useForm()

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
const cancelDialog = async () => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have unsaved changes that will get lost.'),
      {
        buttonTitle: __('Discard changes'),
        buttonVariant: 'danger',
      },
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

const saveObject = async (formData: FormSubmitData) => {
  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(objectAttributesLookup.value, formData)

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
      <CommonButton transparent-background @click="cancelDialog">
        {{ $t('Cancel') }}
      </CommonButton>
    </template>
    <template #after-label>
      <CommonButton
        :form="name"
        :disabled="!canSubmit"
        variant="primary"
        type="submit"
        transparent-background
      >
        {{ $t('Save') }}
      </CommonButton>
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
