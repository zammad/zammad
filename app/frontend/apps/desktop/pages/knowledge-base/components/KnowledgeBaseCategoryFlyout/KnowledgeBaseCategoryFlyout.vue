<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { remapUserErrorFields } from '#shared/errors/utils.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumFormUpdaterId, type KnowledgeBaseCategoryInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useKnowledgeBaseCategoryAddMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryAdd.api.ts'
import { useKnowledgeBaseCategoryUpdateMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryUpdate.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { CategoryFormData } from './types.ts'
import type { EditableKnowledgeBaseCategory } from '../../types.ts'

interface Props {
  name: string
  category?: EditableKnowledgeBaseCategory
  // Category to preselect as the parent when adding. Absent at the knowledge base
  //   root, where the updater falls back to its "top level" entry.
  parentId?: string
}

const props = defineProps<Props>()

// The backend reports its validation errors under the attribute path of the record that carries
//   them: the title lives on the category's autosaved translation, and the parent on the
//   category's own column. Neither is what this form calls the field, so the messages have to be
//   relabeled before the form can put them on the field the user has to correct.
const FORM_FIELD_BY_ERROR_FIELD = {
  'translations.title': 'title',
  parent_id: 'parentId',
}

const { form } = useForm()

// Declared here rather than from object attributes — `KnowledgeBase::Category` is not an
//   object manager object. The names must match the updater's result keys, which are also
//   the payload it reads back as `data`.
const formSchema = defineFormSchema([
  {
    // Only `parentId` changes what the updater resolves (the matrix inherits from it), so
    //   every other field opts out of triggering it.
    // No `iconSet`: the field falls back to the browsed knowledge base's one.
    name: 'categoryIcon',
    label: __('Icon'),
    type: 'kbCategoryIcon',
    required: true,
    triggerFormUpdater: false,
  },
  {
    name: 'title',
    label: __('Title'),
    type: 'text',
    required: true,
    triggerFormUpdater: false,
  },
  {
    // Options come from the updater, which offers only categories the user may create
    //   under. An empty selection means the top level — hence clearable and optional, and
    //   hence no "knowledge base" option. The updater sets `required` for users who may
    //   not create there.
    name: 'parentId',
    label: __('Parent category'),
    type: 'treeselect',
    required: false,
    props: {
      clearable: true,
      // The labels are category titles, i.e. user data, not UI copy.
      noOptionsLabelTranslation: true,
    },
  },
  {
    // Rows arrive as the `permissionRows` prop, the selection as the value — both from the
    //   updater, re-resolved against `parentId`. Hidden until it says otherwise: there is no
    //   matrix without roles that can hold access. It must not trigger the updater itself, or
    //   the answering `value` would overwrite the access the user just picked.
    name: 'permissions',
    label: __('Permissions'),
    type: 'kbPermissions',
    show: false,
    triggerFormUpdater: false,
  },
])

const isEditMode = computed(() => Boolean(props.category))

// Option values are raw record ids, so the preselection cannot be the GraphQL one.
const initialValues = computed(() =>
  props.parentId ? { parentId: getIdFromGraphQLId(props.parentId) } : undefined,
)

// Carries the id, which is how `Form` reaches the updater in edit mode, and prefills the
//   title and icon — the updater resolves neither.
const initialEntityObject = computed(() => props.category)

const formUpdaterId = computed(() =>
  isEditMode.value
    ? EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseCategoryEdit
    : EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseCategoryCreate,
)

const knowledgeBase = toRef(useKnowledgeBaseStore(), 'knowledgeBase')

const router = useRouter()

const { notify } = useNotifications()

const categoryAddMutation = new MutationHandler(useKnowledgeBaseCategoryAddMutation())

const categoryUpdateMutation = new MutationHandler(useKnowledgeBaseCategoryUpdateMutation())

const buildCategoryInput = (data: CategoryFormData): KnowledgeBaseCategoryInput => {
  const permissions = Object.entries(data.permissions ?? {}).map(([roleId, access]) => ({
    roleId: convertToGraphQLId('Role', roleId),
    access,
  }))

  return {
    categoryIcon: data.categoryIcon,
    title: data.title,
    // Always sent, `null` included: an omitted parent means "leave it where it is", so leaving it
    //   out would make a move to the top level do nothing.
    parentId: data.parentId ? convertToGraphQLId('KnowledgeBase::Category', data.parentId) : null,
    // Omitted rather than empty when the matrix had nothing to show: an empty list would drop
    //   whatever the category stores.
    ...(permissions.length ? { permissions } : {}),
  }
}

const submitForm = async (data: FormSubmitData<CategoryFormData>) => {
  const base = knowledgeBase.value
  const locale = base?.currentLocale?.systemLocale.locale

  // Only reachable if the flyout outlived the knowledge base query it was opened over.
  if (!base || !locale) {
    notify({
      id: 'knowledge-base-category-error',
      type: NotificationTypes.Error,
      message: __('The knowledge base could not be loaded.'),
    })
    return
  }

  // Also the navigation target below: the treeselect may have moved the category away from the
  //   parent the flyout was opened with, and this is what the mutation is told to file it under.
  const input = buildCategoryInput(data)

  const variables = {
    input,
    // The locale of the call: the title is written into it, and the response comes back in it —
    //   which matters because it lands in the cache the browsed page reads from.
    locale,
  }

  await (
    props.category
      ? categoryUpdateMutation.send({ categoryId: props.category.id, ...variables })
      : categoryAddMutation.send(variables)
  ).catch((error) => {
    throw remapUserErrorFields(error, FORM_FIELD_BY_ERROR_FIELD)
  })

  closeFlyout(props.name)

  if (isEditMode.value) return

  router.push(knowledgeBaseBrowseRoute(locale, input.parentId ?? undefined))
}
</script>

<template>
  <CommonFlyout
    :name="name"
    :header-icon="isEditMode ? 'folder' : 'folder-plus'"
    :header-title="isEditMode ? __('Edit category') : __('Add category')"
    :form="form"
    no-close-on-action
    :footer-action-options="{
      actionLabel: isEditMode ? __('Update') : __('Create'),
      actionButton: {
        type: 'submit',
      },
    }"
  >
    <Form
      id="form-knowledge-base-category"
      ref="form"
      should-autofocus
      :schema="formSchema"
      :initial-values="initialValues"
      :initial-entity-object="initialEntityObject"
      :form-updater-id="formUpdaterId"
      @submit="submitForm($event as FormSubmitData<CategoryFormData>)"
    />
  </CommonFlyout>
</template>
