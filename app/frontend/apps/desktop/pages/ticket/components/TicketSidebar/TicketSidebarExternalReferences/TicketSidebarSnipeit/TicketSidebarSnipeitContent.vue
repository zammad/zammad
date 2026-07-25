<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, ref, toRef, watch } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { TicketSidebarPlugin } from '#desktop/pages/ticket/components/TicketSidebar/plugins/types.ts'
import TicketSidebarContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarContent.vue'
import ExternalReferenceContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceContent.vue'
import ExternalReferenceLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceLink.vue'
import type { FormDataRecords } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/types.ts'
import { useSnipeitCacheHandlers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/useSnipeitCacheHandlers.ts'
import { useSnipeitFormHelpers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/useSnipeitFormHelpers.ts'
import { useTicketExternalReferencesSnipeitAssetAddMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesSnipeitAssetAdd.api.ts'
import { useTicketExternalReferencesSnipeitAssetRemoveMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesSnipeitAssetRemove.api.ts'
import { useTicketExternalReferencesSnipeitAssetListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

interface Props {
  sidebarPlugin: TicketSidebarPlugin
  assetIds: number[]
  screenType: TicketSidebarScreenType
  isTicketEditable: boolean
  ticketId?: string
  form?: FormRef
}
const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

const skipNextAssetUpdate = ref(false)

const { open } = useFlyout({
  name: 'snipeit',
  component: () => import('./SnipeitFlyout.vue'),
})

const assetListQuery = new QueryHandler(
  useTicketExternalReferencesSnipeitAssetListQuery(
    () => ({
      ticketId: props.ticketId,
      snipeitAssetIds: props.ticketId ? undefined : props.assetIds,
    }),
    () => ({
      enabled:
        props.screenType === TicketSidebarScreenType.TicketCreate
          ? props.assetIds?.length > 0
          : !!props.ticketId,
      fetchPolicy:
        props.screenType === TicketSidebarScreenType.TicketCreate
          ? 'cache-first'
          : 'cache-and-network',
    }),
  ),
  {
    errorShowNotification: false,
  },
)

const result = assetListQuery.result()

const isLoading = assetListQuery.loading()

const queryError = assetListQuery.operationError()

const error = computed(() =>
  queryError.value
    ? __(`Error fetching information from Snipe-IT. Please contact your administrator.`)
    : null,
)

const assetList = computed(() => {
  return result.value?.ticketExternalReferencesSnipeitAssetList || []
})

const { removeAssetListCacheUpdate, modifyAssetItemAddCache } = useSnipeitCacheHandlers(
  toRef(props, 'assetIds'),
  toRef(props, 'ticketId'),
)

const { addAssetIdsToForm, removeAssetFromForm } = useSnipeitFormHelpers(toRef(props, 'form'))

const removeAssetMutation = new MutationHandler(
  useTicketExternalReferencesSnipeitAssetRemoveMutation(),
)

const removeAsset = async ({ id }: { id: number }) => {
  const revertCacheUpdate = removeAssetListCacheUpdate(id)

  if (props.screenType === TicketSidebarScreenType.TicketCreate) return removeAssetFromForm(id)

  return removeAssetMutation
    .send({
      snipeitAssetId: id,
      ticketId: props.ticketId!,
    })
    .catch(() => revertCacheUpdate)
}

const addAssetMutation = new MutationHandler(
  useTicketExternalReferencesSnipeitAssetAddMutation({
    update: modifyAssetItemAddCache,
  }),
)

const addAssets = async (formData: FormDataRecords) => {
  skipNextAssetUpdate.value = true

  return addAssetMutation
    .send({
      snipeitAssetIds: formData.assetIds,
      ticketId: props.ticketId,
    })
    .then((result) => {
      if (props.screenType === TicketSidebarScreenType.TicketCreate)
        addAssetIdsToForm(result?.ticketExternalReferencesSnipeitAssetAdd?.snipeitAssets)
    })
    .finally(() => {
      skipNextAssetUpdate.value = false
    })
}

const openFlyout = () =>
  open({
    assetIds: props.assetIds,
    ticketId: props.ticketId,
    onSubmit: addAssets,
    icon: props.sidebarPlugin.icon,
  })

const actions = computed((): MenuItem[] =>
  props.assetIds?.length && !error.value
    ? [
        {
          key: 'link-snipeit-asset',
          label: __('Link assets'),
          show: () => props.isTicketEditable,
          onClick: openFlyout,
          icon: 'link-45deg',
        },
      ]
    : [],
)

if (props.ticketId) {
  watch(
    () => props.assetIds,
    (newValue) => {
      if (
        isEqual(
          newValue,
          assetList.value.map((asset) => asset.snipeitAssetId),
        ) ||
        skipNextAssetUpdate.value
      ) {
        skipNextAssetUpdate.value = false
        return
      }

      assetListQuery.refetch()
    },
  )
}
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :actions="actions"
  >
    <CommonButton
      v-if="!assetIds?.length"
      size="medium"
      variant="primary"
      class="block ltr:w-full rtl:w-full"
      @click="openFlyout"
    >
      {{ $t('Link assets') }}
    </CommonButton>

    <CommonLoader v-if="assetIds?.length" :loading="isLoading" :error="error">
      <div class="space-y-6" tabindex="-1">
        <div
          v-for="asset in assetList"
          :key="asset.snipeitAssetId"
          class="group space-y-2"
          role="group"
        >
          <ExternalReferenceLink
            :id="asset.snipeitAssetId"
            :title="asset.name"
            :link="asset.link!"
            :is-editable="isTicketEditable"
            :tooltip="$t('Unlink asset')"
            @remove="removeAsset"
          />

          <ExternalReferenceContent :label="$t('ID')" :values="[asset.snipeitAssetId.toString()]" />

          <ExternalReferenceContent
            v-if="asset.assetTag"
            :label="$t('Asset Tag')"
            :values="[asset.assetTag]"
          />
          <ExternalReferenceContent
            v-if="asset.status"
            :label="$t('Status')"
            :values="[asset.status]"
          />
          <ExternalReferenceContent
            v-if="asset.model"
            :label="$t('Model')"
            :values="[asset.model]"
          />
          <ExternalReferenceContent
            v-if="asset.category"
            :label="$t('Category')"
            :values="[asset.category]"
          />
          <ExternalReferenceContent
            v-if="asset.location"
            :label="$t('Location')"
            :values="[asset.location]"
          />
        </div>
      </div>
    </CommonLoader>
  </TicketSidebarContent>
</template>
