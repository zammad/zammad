<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { merge } from 'lodash-es'
import { computed } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormFieldValue,
  FormSchemaField,
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { flattenObjectAttributeValues } from '#shared/entities/object-attributes/utils.ts'
import type { EnumFormUpdaterId, EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import type { ActionFooterOptions } from '../CommonFlyout/types'

export interface Props {
  name: string
  type: EnumObjectManagerObjects
  errorNotificationMessage?: string
  mutation: OperationMutationFunction
  schema: FormSchemaNode[]
  formChangeFields?: Record<string, Partial<FormSchemaField>>
  formUpdaterId?: EnumFormUpdaterId
  object?: ObjectLike
  title?: string
  icon?: string
  footerActionOptions?: ActionFooterOptions
}

const props = defineProps<Props>()

const emit = defineEmits<{
  success: [data: unknown]
  error: []
  'changed-field': [fieldName: string, newValue: FormFieldValue, oldValue: FormFieldValue]
}>()

const footerOptions = computed(() =>
  merge(props.footerActionOptions || {}, {
    actionButton: {
      type: 'submit',
    },
  }),
)

const updateMutation = new MutationHandler(props.mutation({}), {
  errorNotificationMessage: props.errorNotificationMessage,
})

const { form } = useForm()

// Generate a unique form ID to prevent state sharing between multiple flyout instances
// Formkit relies on it to manage form state internally and not reuse the same form in memory
const formNodeId = computed(() => `${props.name}-${getUuid()}`)

const objectAttributes = flattenObjectAttributeValues(props.object?.objectAttributeValues)

const initialFlatObject = {
  ...props.object,
  ...objectAttributes,
}

const { attributesLookup: objectAttributesLookup } = useObjectAttributes(props.type)

const changedFormField = (
  fieldName: string,
  newValue: FormFieldValue,
  oldValue: FormFieldValue,
) => {
  emit('changed-field', fieldName, newValue, oldValue)
}

const saveObject = async (formData: FormSubmitData) => {
  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(props.type, objectAttributesLookup.value, formData)

  const result = await updateMutation.send({
    ...(props.object?.id && { id: props.object.id }),
    input: {
      ...internalObjectAttributeValues,
      objectAttributeValues: additionalObjectAttributeValues,
    },
  })

  if (result) {
    emit('success', result)
    await closeFlyout(props.name)
  } else {
    emit('error')
  }
}
</script>

<template>
  <CommonFlyout
    :name="name"
    :header-title="title"
    :header-icon="icon"
    :form="form"
    :footer-action-options="footerOptions"
    size="large"
    no-close-on-action
  >
    <Form
      :id="formNodeId"
      ref="form"
      class="pt-4 pb-6"
      should-autofocus
      use-object-attributes
      :schema="schema"
      :initial-entity-object="initialFlatObject"
      :change-fields="formChangeFields"
      :form-updater-id="formUpdaterId"
      @changed="changedFormField"
      @submit="saveObject"
    />
  </CommonFlyout>
</template>
