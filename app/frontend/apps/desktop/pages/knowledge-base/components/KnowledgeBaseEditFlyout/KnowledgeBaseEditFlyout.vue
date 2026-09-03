<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { remapUserErrorFields } from '#shared/errors/utils.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumFormUpdaterId, type KnowledgeBaseInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useKnowledgeBaseUpdateMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseUpdate.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import type { KnowledgeBaseFormData } from './types.ts'

interface Props {
  name: string
}

const props = defineProps<Props>()

// The title lives on the knowledge base's translation, so the backend reports its errors under
//   that record's attribute path — which matches no field of this form and would leave the
//   message on the form rather than on the field the user has to correct. The footer note has no
//   such model-level validation to remap: it is only rejected as a schema-level NonEmptyString
//   error, which the form already reports on the field itself.
const FORM_FIELD_BY_ERROR_FIELD = {
  'translations.title': 'title',
}

const { form } = useForm()

const formSchema = defineFormSchema([
  {
    name: 'title',
    label: __('Title'),
    type: 'text',
    required: true,
  },
  {
    name: 'footerNote',
    label: __('Footer note'),
    type: 'text',
    required: true,
  },
  {
    name: 'permissions',
    label: __('Permissions'),
    type: 'kbPermissions',
    show: false,
    triggerFormUpdater: false,
  },
])

const knowledgeBase = toRef(useKnowledgeBaseStore(), 'knowledgeBase')

// The form edits the texts of one locale, which the translation owns - flattened onto the fields
//   that carry them, `title` and `footerNote`.
const initialEntityObject = computed(() => {
  const base = knowledgeBase.value
  if (!base) return undefined

  return { ...base, title: base.translation?.title, footerNote: base.translation?.footerNote }
})

const { notify } = useNotifications()

const knowledgeBaseUpdateMutation = new MutationHandler(useKnowledgeBaseUpdateMutation())

const buildInput = (data: KnowledgeBaseFormData): KnowledgeBaseInput => {
  const permissions = Object.entries(data.permissions ?? {}).map(([roleId, access]) => ({
    roleId: convertToGraphQLId('Role', roleId),
    access,
  }))

  return {
    title: data.title,
    footerNote: data.footerNote ?? '',
    // Omitted rather than empty when the matrix had nothing to show: an empty list would drop
    //   whatever the knowledge base stores.
    ...(permissions.length ? { permissions } : {}),
  }
}

const submitForm = async (data: FormSubmitData<KnowledgeBaseFormData>) => {
  const base = knowledgeBase.value
  const locale = base?.currentLocale?.systemLocale.locale

  // Only reachable if the flyout outlived the knowledge base query it was opened over; without a
  //   locale there is none to write the texts into.
  if (!base || !locale) {
    notify({
      id: 'knowledge-base-error',
      type: NotificationTypes.Error,
      message: __('The knowledge base could not be loaded.'),
    })
    return
  }

  await knowledgeBaseUpdateMutation
    .send({
      input: buildInput(data),
      // The locale of the call: the texts are written into it, and the response comes back in it —
      //   which matters because it lands in the cache the browsed page reads from.
      locale,
    })
    .catch((error) => {
      throw remapUserErrorFields(error, FORM_FIELD_BY_ERROR_FIELD)
    })

  closeFlyout(props.name)
}
</script>

<template>
  <CommonFlyout
    :name="name"
    header-icon="book"
    :header-title="__('Edit knowledge base')"
    :form="form"
    no-close-on-action
    :footer-action-options="{
      actionLabel: __('Update'),
      actionButton: {
        type: 'submit',
      },
    }"
  >
    <Form
      v-if="initialEntityObject"
      id="form-knowledge-base"
      ref="form"
      should-autofocus
      :schema="formSchema"
      :initial-entity-object="initialEntityObject"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseEdit"
      @submit="submitForm($event as FormSubmitData<KnowledgeBaseFormData>)"
    />
  </CommonFlyout>
</template>
