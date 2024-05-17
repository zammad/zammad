<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type {
  FormFieldValue,
  FormSchemaField,
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  ObjectAttributeValue,
} from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#mobile/composables/useDialog.ts'

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
  success: [data: unknown]
  error: []
  changedField: [
    fieldName: string,
    newValue: FormFieldValue,
    oldValue: FormFieldValue,
  ]
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

const { waitForConfirmation } = useConfirmation()

const cancelDialog = async () => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have unsaved changes that will get lost.'),
      {
        buttonLabel: __('Discard changes'),
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
      should-autofocus
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
