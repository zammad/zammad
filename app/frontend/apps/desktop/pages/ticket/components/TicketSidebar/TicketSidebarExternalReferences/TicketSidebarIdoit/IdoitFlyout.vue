<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useDebounceFn } from '@vueuse/core'
import { computed, watchEffect } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import UserError from '#shared/errors/UserError.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { TableItem } from '#desktop/components/CommonTable/types'
import IdoitObjectList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/IdoitFlyout/IdoitObjectList.vue'
import type { FormDataRecords } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/types.ts'
import { AutocompleteSearchIdoitObjectTypesDocument } from '#desktop/pages/ticket/graphql/queries/autocompleteSearchIdoitObjectTypes.api.ts'
import { useTicketExternalReferencesIdoitObjectSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectSearch.api.ts'

interface Props {
  objectIds: number[]
  onSubmit: (formData: FormDataRecords) => Promise<unknown>
  icon: string
}

const props = defineProps<Props>()

const { form, values, updateFieldValues, onChangedField, formSetErrors } =
  useForm()

const FETCH_LIMIT = 10
const FETCH_DEBOUNCE = 300

const flyoutName = 'idoit'

const objectSearchQuery = new QueryHandler(
  useTicketExternalReferencesIdoitObjectSearchQuery(
    {
      limit: FETCH_LIMIT,
      idoitTypeId: values.value?.type as string,
      query: values.value?.filter as string,
    },
    {
      fetchPolicy: 'no-cache',
    },
  ),
  {
    errorShowNotification: false,
  },
)

const result = objectSearchQuery.result()

const isLoading = objectSearchQuery.loading()

objectSearchQuery.onError(() => {
  formSetErrors(
    new UserError([
      {
        field: 'type',
        message: __(
          'Error fetching i-doit information. Please contact your administrator.',
        ),
      },
    ]),
  )
})

const { debouncedLoading, loading } = useDebouncedLoading()

watchEffect(() => {
  loading.value = isLoading.value
})

const objectItems = computed(
  () =>
    result.value?.ticketExternalReferencesIdoitObjectSearch.map((object) => ({
      id: object.idoitObjectId,
      idoitObjectId: object.idoitObjectId,
      title: {
        link: object.link,
        label: object.title,
        openInNewTab: true,
        external: true,
      },
      status: object.status,
      disabled: props.objectIds.includes(object.idoitObjectId),
      checked: props.objectIds.includes(object.idoitObjectId),
    })) || [],
)

onChangedField(
  'filter',
  useDebounceFn(
    (query) =>
      objectSearchQuery.refetch({
        limit: FETCH_LIMIT,
        idoitTypeId: values.value?.type as string,
        query: query as string,
      }),
    FETCH_DEBOUNCE,
  ),
)

onChangedField('type', async (type) =>
  objectSearchQuery.refetch({
    limit: FETCH_LIMIT,
    idoitTypeId: type as string,
    query: values.value?.filter as string,
  }),
)

const schema: FormSchemaNode[] = [
  {
    type: 'autocomplete',
    name: 'type',
    label: __('Type'),
    props: {
      gqlQuery: AutocompleteSearchIdoitObjectTypesDocument,
      clearable: true,
      defaultFilter: '*',
      classes: {
        outer: 'mb-3',
      },
    },
  },
  {
    type: 'text',
    name: 'filter',
    label: __('Filter'),
    placeholder: __('Search…'),
    props: {
      prefixIcon: 'search',
      classes: {
        input: 'rtl:pr-2 ltr:pl-1 ltr:pl-2 rtl:pr-1',
        outer: 'mb-4',
      },
    },
  },
  {
    type: 'hidden',
    name: 'objectIds',
  },
]

const handleObjectSelection = (selectedRows: TableItem[]) =>
  updateFieldValues({
    objectIds: selectedRows
      .filter((object) => !object.disabled)
      .map(({ idoitObjectId }) => idoitObjectId) as number[],
  })

const preselectedObjectIds = computed(() =>
  props.objectIds.map((id) => id.toString()),
)

// Only count newly added objects
const isValid = computed(
  () =>
    (
      (values.value?.objectIds as number[])?.filter(
        (id) => !props.objectIds.includes(id),
      ) || []
    ).length > 0,
)

const submitObjects = async (data: FormDataRecords) => {
  await props.onSubmit(data)

  return () => closeFlyout(flyoutName)
}
</script>

<template>
  <CommonFlyout
    :header-icon="icon"
    :header-title="__('i-doit: Link objects')"
    :name="flyoutName"
    no-close-on-action
    :form="form"
    :footer-action-options="{
      actionLabel: $t('Link Objects'),
      actionButton: {
        type: 'submit',
        disabled: !isValid,
      },
    }"
  >
    <Form
      ref="form"
      should-autofocus
      :schema="schema"
      @submit="submitObjects($event as FormDataRecords)"
    />

    <CommonLoader :loading="debouncedLoading">
      <IdoitObjectList
        class="w-full"
        :items="objectItems"
        :disabled-checkbox-ids="preselectedObjectIds"
        @update:checked-rows="handleObjectSelection"
      />
    </CommonLoader>
  </CommonFlyout>
</template>
