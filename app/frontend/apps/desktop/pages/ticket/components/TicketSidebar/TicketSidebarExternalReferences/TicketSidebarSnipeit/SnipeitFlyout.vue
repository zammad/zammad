<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

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
import SnipeitAssetList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/SnipeitFlyout/SnipeitAssetList.vue'
import type { FormDataRecords } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/types.ts'
import { AutocompleteSearchSnipeitCategoriesDocument } from '#desktop/pages/ticket/graphql/queries/autocompleteSearchSnipeitCategories.api.ts'
import { AutocompleteSearchSnipeitModelsDocument } from '#desktop/pages/ticket/graphql/queries/autocompleteSearchSnipeitModels.api.ts'
import { useTicketExternalReferencesSnipeitAssetSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetSearch.api.ts'

interface Props {
  assetIds: number[]
  onSubmit: (formData: FormDataRecords) => Promise<unknown>
  icon: string
}

const props = defineProps<Props>()

const { form, values, updateFieldValues, onChangedField, formSetErrors } = useForm()

const FETCH_LIMIT = 10
const FETCH_DEBOUNCE = 300

const flyoutName = 'snipeit'

const assetSearchQuery = new QueryHandler(
  useTicketExternalReferencesSnipeitAssetSearchQuery(
    {
      limit: FETCH_LIMIT,
      categoryId: values.value?.category as string,
      modelId: values.value?.model as string,
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

const result = assetSearchQuery.result()

const isLoading = assetSearchQuery.loading()

assetSearchQuery.onError(() => {
  formSetErrors(
    new UserError([
      {
        field: 'category',
        message: __('Error fetching Snipe-IT information. Please contact your administrator.'),
      },
    ]),
  )
})

const { debouncedLoading, loading } = useDebouncedLoading()

watchEffect(() => {
  loading.value = isLoading.value
})

const assetItems = computed(
  () =>
    result.value?.ticketExternalReferencesSnipeitAssetSearch.map((asset) => ({
      id: asset.snipeitAssetId,
      snipeitAssetId: asset.snipeitAssetId,
      name: {
        link: asset.link,
        label: asset.name,
        openInNewTab: true,
        external: true,
      },
      status: asset.status,
      assetTag: asset.assetTag,
      disabled: props.assetIds.includes(asset.snipeitAssetId),
      checked: props.assetIds.includes(asset.snipeitAssetId),
    })) || [],
)

const refetchAssets = (overrides: Record<string, unknown> = {}) =>
  assetSearchQuery.refetch({
    limit: FETCH_LIMIT,
    categoryId: values.value?.category as string,
    modelId: values.value?.model as string,
    query: values.value?.filter as string,
    ...overrides,
  })

onChangedField(
  'filter',
  useDebounceFn((query) => refetchAssets({ query: query as string }), FETCH_DEBOUNCE),
)

onChangedField('category', async (category) => refetchAssets({ categoryId: category as string }))

onChangedField('model', async (model) => refetchAssets({ modelId: model as string }))

const schema: FormSchemaNode[] = [
  {
    type: 'autocomplete',
    name: 'category',
    label: __('Category'),
    props: {
      gqlQuery: AutocompleteSearchSnipeitCategoriesDocument,
      clearable: true,
      defaultFilter: '*',
      classes: {
        outer: 'mb-3',
      },
    },
  },
  {
    type: 'autocomplete',
    name: 'model',
    label: __('Model'),
    props: {
      gqlQuery: AutocompleteSearchSnipeitModelsDocument,
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
    name: 'assetIds',
  },
]

const handleAssetSelection = (selectedRows: TableItem[]) =>
  updateFieldValues({
    assetIds: selectedRows
      .filter((asset) => !asset.disabled)
      .map(({ snipeitAssetId }) => snipeitAssetId) as number[],
  })

const preselectedAssetIds = computed(() => props.assetIds.map((id) => id.toString()))

// Only count newly added assets
const isValid = computed(
  () =>
    ((values.value?.assetIds as number[])?.filter((id) => !props.assetIds.includes(id)) || [])
      .length > 0,
)

const submitAssets = async (data: FormDataRecords) => {
  await props.onSubmit(data)

  return () => closeFlyout(flyoutName)
}
</script>

<template>
  <CommonFlyout
    :header-icon="icon"
    :header-title="__('Snipe-IT: Link assets')"
    :name="flyoutName"
    no-close-on-action
    :form="form"
    :footer-action-options="{
      actionLabel: $t('Link assets'),
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
      @submit="submitAssets($event as FormDataRecords)"
    />

    <CommonLoader :loading="debouncedLoading">
      <SnipeitAssetList
        class="w-full"
        :items="assetItems"
        :disabled-checkbox-ids="preselectedAssetIds"
        @update:checked-rows="handleAssetSelection"
      />
    </CommonLoader>
  </CommonFlyout>
</template>
