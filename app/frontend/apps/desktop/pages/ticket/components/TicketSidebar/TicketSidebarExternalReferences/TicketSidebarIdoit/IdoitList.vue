<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { TicketSidebarPlugin } from '#desktop/pages/ticket/components/TicketSidebar/plugins/types.ts'
import ExternalReferenceContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceContent.vue'
import ExternalReferenceLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceLink.vue'
import { useIdoitCacheHandlers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/useIdoitCacheHandlers.ts'
import { useIdoitFormHelpers } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/useIdoitFormHelpers.ts'
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

const objectListQuery = new QueryHandler(
  useTicketExternalReferencesIdoitObjectListQuery(
    () => ({
      ticketId: props.ticketId,
      idoitObjectIds: props.ticketId ? undefined : props.objectIds,
    }),
    () => ({
      enabled: props.objectIds?.length > 0,
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
        'Error fetching i-doit information. Please contact your administrator.',
      )
    : null,
)

const objectList = computed(() => {
  return result.value?.ticketExternalReferencesIdoitObjectList || []
})

const removeObjectMutation = new MutationHandler(
  useTicketExternalReferencesIdoitObjectRemoveMutation(),
)

const { removeObjectListCacheUpdate } = useIdoitCacheHandlers(
  toRef(props, 'objectIds'),
  toRef(props, 'ticketId'),
)

const { removeObjectFromForm } = useIdoitFormHelpers(toRef(props, 'form'))

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
</script>

<template>
  <CommonLoader v-if="objectIds?.length" :error="error" :loading="isLoading">
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
        <ExternalReferenceContent :label="$t('Type')" :values="[object.type]" />
      </div>
    </div>
  </CommonLoader>
</template>
