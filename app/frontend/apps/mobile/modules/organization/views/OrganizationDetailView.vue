<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable zammad/zammad-detect-translatable-string */
import { useRouter } from 'vue-router'
import { computed } from 'vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useHeader } from '@mobile/composables/useHeader'
import { useDialog } from '@shared/composables/useDialog'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import CommonObjectAttributes from '@mobile/components/CommonObjectAttributes/CommonObjectAttributes.vue'
import { redirectToError } from '@mobile/router/error'
import CommonUsersList from '@mobile/components/CommonUsersList/CommonUsersList.vue'
import { ErrorStatusCodes } from '@shared/types/error'
import { useOrganizationObjectManagerAttributesStore } from '@mobile/entities/organization/stores/objectManagerAttributes'
import { useOrganizationQuery } from '../graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '../graphql/subscriptions/organizationUpdates.api'

interface Props {
  id: string
}

const props = defineProps<Props>()

const organizationQuery = new QueryHandler(
  useOrganizationQuery({
    organizationId: props.id,
    membersCount: 3,
  }),
)

organizationQuery.subscribeToMore({
  document: OrganizationUpdatesDocument,
  variables: {
    organizationId: props.id,
  },
})

const router = useRouter()

organizationQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const organizationResult = organizationQuery.result()
const loading = organizationQuery.loading()

const organization = computed(() => organizationResult.value?.organization)

const objectAttributesManager = useOrganizationObjectManagerAttributesStore()

const objectAttributes = computed(
  () => objectAttributesManager.attributes || [],
)

const editDialog = useDialog({
  name: 'organization-edit',
  component: () => import('../components/OrganizationEditDialog.vue'),
})

useHeader({
  title: __('Organization'),
  backUrl: '/',
  actionTitle: __('Edit'),
  onAction() {
    editDialog.open({
      organization,
      name: editDialog.name,
    })
  },
})

const members = computed(() => {
  return organization.value?.members.edges.map(({ node }) => node) || []
})

const loadAllMembers = () => {
  organizationQuery.refetch({
    organizationId: props.id,
    membersCount: null,
  })
}

const ticketsLinkQuery = computed(() => {
  return `organization.name: "${organization.value?.name}"`
})
</script>

<template>
  <div v-if="organization" class="px-4">
    <div class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonOrganizationAvatar :entity="organization" size="xl" personal />
      </div>
      <div class="mt-2 text-xl font-bold">
        {{ organization.name }}
      </div>
    </div>

    <CommonObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
    />

    <CommonUsersList
      :label="__('Members')"
      :users="members"
      :total-count="organization.members.totalCount || 0"
      :disable-show-more="loading"
      @show-more="loadAllMembers()"
    />

    <CommonTicketStateList
      v-if="organization.ticketsCount"
      :create-link="`/tickets/create?organization_id=${organization.id}`"
      :create-label="__('Create new ticket for this organization')"
      :counts="organization.ticketsCount"
      :tickets-link-query="ticketsLinkQuery"
    />
  </div>
  <CommonLoader
    v-else-if="loading"
    class="w-full p-4"
    center
    :loading="loading"
  />
</template>
