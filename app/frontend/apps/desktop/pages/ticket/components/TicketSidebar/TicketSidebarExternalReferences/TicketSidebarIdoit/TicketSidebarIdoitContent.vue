<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, ref, toRef, watch } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { TicketSidebarPlugin } from '#desktop/pages/ticket/components/TicketSidebar/plugins/types.ts'
import TicketSidebarContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarContent.vue'
import ExternalReferenceContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceContent.vue'
import ExternalReferenceLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceLink.vue'
import type { FormDataRecords } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/types.ts'
import { useIdoitCacheHandlers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/useIdoitCacheHandlers.ts'
import { useIdoitFormHelpers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/useIdoitFormHelpers.ts'
import { useTicketExternalReferencesIdoitObjectAddMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIdoitObjectAdd.api.ts'
import { useTicketExternalReferencesIdoitObjectRemoveMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIdoitObjectRemove.api.ts'
import { useTicketExternalReferencesIdoitObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

interface Props {
  sidebarPlugin: TicketSidebarPlugin
  objectIds: number[]
  screenType: TicketSidebarScreenType
  isTicketEditable: boolean
  ticketId?: string
  form?: FormRef
}
const props = defineProps<Props>()

const skipNextObjectUpdate = ref(false)

const { open, name: FLYOUT_NAME } = useFlyout({
  component: () => import('./IdoitFlyout.vue'),
  name: 'add-idoit-objects',
})

const objectListQuery = new QueryHandler(
  useTicketExternalReferencesIdoitObjectListQuery(
    () => ({
      ticketId: props.ticketId,
      idoitObjectIds: props.ticketId ? undefined : props.objectIds,
    }),
    () => ({
      enabled:
        props.screenType === TicketSidebarScreenType.TicketCreate
          ? props.objectIds?.length > 0
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

const result = objectListQuery.result()

const isLoading = objectListQuery.loading()

const queryError = objectListQuery.operationError()

const error = computed(() =>
  queryError.value
    ? __(
        `Error fetching information from i-doit. Please contact your administrator.`,
      )
    : null,
)

const objectList = computed(() => {
  return result.value?.ticketExternalReferencesIdoitObjectList || []
})

const { removeObjectListCacheUpdate, modifyObjectItemAddCache } =
  useIdoitCacheHandlers(toRef(props, 'objectIds'), toRef(props, 'ticketId'))

const { addObjectIdsToForm, removeObjectFromForm } = useIdoitFormHelpers(
  toRef(props, 'form'),
)

const removeObjectMutation = new MutationHandler(
  useTicketExternalReferencesIdoitObjectRemoveMutation(),
)

const removeObject = async ({ id }: { id: number }) => {
  const revertCacheUpdate = removeObjectListCacheUpdate(id)

  if (props.screenType === TicketSidebarScreenType.TicketCreate)
    return removeObjectFromForm(id)

  return removeObjectMutation
    .send({
      idoitObjectId: id,
      ticketId: props.ticketId!,
    })
    .catch(() => revertCacheUpdate)
}

const addObjectMutation = new MutationHandler(
  useTicketExternalReferencesIdoitObjectAddMutation({
    update: modifyObjectItemAddCache,
  }),
)

const addObjects = async (formData: FormDataRecords) => {
  skipNextObjectUpdate.value = true

  return addObjectMutation
    .send({
      idoitObjectIds: formData.objectIds,
      ticketId: props.ticketId,
    })
    .then((result) => {
      if (props.screenType === TicketSidebarScreenType.TicketCreate)
        addObjectIdsToForm(
          result?.ticketExternalReferencesIdoitObjectAdd?.idoitObjects,
        )
    })
    .finally(() => {
      skipNextObjectUpdate.value = false
    })
}

const openFlyout = () =>
  open({
    name: FLYOUT_NAME,
    objectIds: props.objectIds,
    ticketId: props.ticketId,
    onSubmit: addObjects,
    icon: props.sidebarPlugin.icon,
  })

const actions = computed((): MenuItem[] =>
  props.objectIds?.length && !error.value
    ? [
        {
          key: 'link-idoit-object',
          label: __('Link objects'),
          show: () => props.isTicketEditable,
          onClick: openFlyout,
          icon: 'link-45deg',
        },
      ]
    : [],
)

if (props.ticketId) {
  watch(
    () => props.objectIds,
    (newValue) => {
      if (
        isEqual(
          newValue,
          objectList.value.map((obj) => obj.idoitObjectId),
        ) ||
        skipNextObjectUpdate.value
      ) {
        skipNextObjectUpdate.value = false
        return
      }

      objectListQuery.refetch()
    },
  )
}
</script>

<template>
  <TicketSidebarContent
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :actions="actions"
  >
    <CommonButton
      v-if="!objectIds?.length"
      size="medium"
      variant="primary"
      class="block ltr:w-full rtl:w-full"
      @click="openFlyout"
    >
      {{ $t('Link Objects') }}
    </CommonButton>

    <CommonLoader v-if="objectIds?.length" :loading="isLoading" :error="error">
      <div class="space-y-6" tabindex="-1">
        <div
          v-for="object in objectList"
          :key="object.idoitObjectId"
          class="group space-y-2"
          role="group"
        >
          <ExternalReferenceLink
            :id="object.idoitObjectId"
            :title="object.title"
            :link="object.link!"
            :is-editable="isTicketEditable"
            :tooltip="$t('Unlink object')"
            @remove="removeObject"
          />

          <ExternalReferenceContent
            :label="$t('ID')"
            :values="[object.idoitObjectId.toString()]"
          />

          <ExternalReferenceContent
            :label="$t('Status')"
            :values="[object.status]"
          />
          <ExternalReferenceContent
            :label="$t('Type')"
            :values="[object.type]"
          />
        </div>
      </div>
    </CommonLoader>
  </TicketSidebarContent>
</template>
