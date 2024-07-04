<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/index.ts'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotificationSeen.ts'
import { useOrganizationDetail } from '#shared/entities/organization/composables/useOrganizationDetail.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import CommonTicketStateList from '#mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import OrganizationMembersList from '#mobile/components/Organization/OrganizationMembersList.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'
import { useOrganizationEdit } from '#mobile/entities/organization/composables/useOrganizationEdit.ts'
import { useOrganizationTicketsCount } from '#mobile/entities/organization/composables/useOrganizationTicketsCount.ts'

interface Props {
  internalId: number
}

const props = defineProps<Props>()

const { createQueryErrorHandler } = useErrorHandler()

const errorCallback = createQueryErrorHandler({
  notFound: __(
    'Organization with specified ID was not found. Try checking the URL for errors.',
  ),
  forbidden: __('You have insufficient rights to view this organization.'),
})

const {
  organization,
  loading,
  objectAttributes,
  organizationQuery,
  loadAllMembers,
  // loadOrganization,
} = useOrganizationDetail(toRef(props, 'internalId'), errorCallback)

// loadOrganization(props.internalId)

useOnlineNotificationSeen(organization)

const { openEditOrganizationDialog } = useOrganizationEdit()

useHeader({
  title: __('Organization'),
  backUrl: '/',
  actionTitle: __('Edit'),
  actionHidden: computed(
    () => organization.value == null || !organization.value.policy.update,
  ),
  refetch: computed(
    () => organization.value != null && organizationQuery.loading().value,
  ),
  onAction() {
    if (!organization.value || !organization.value.policy.update) return
    openEditOrganizationDialog(organization.value)
  },
})

const { getTicketData } = useOrganizationTicketsCount()
const ticketData = computed(() => getTicketData(organization.value))
</script>

<template>
  <div v-if="organization" class="px-4">
    <div class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonOrganizationAvatar
          :entity="organization as AvatarOrganization"
          size="xl"
        />
      </div>
      <div class="mt-2 text-xl font-bold">
        {{ organization.name }}
      </div>
    </div>

    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name']"
    />

    <OrganizationMembersList
      :organization="organization"
      :disable-show-more="loading"
      @load-more="loadAllMembers()"
    />

    <CommonTicketStateList
      v-if="ticketData"
      :create-link="ticketData.createLink"
      :create-label="ticketData.createLabel"
      :counts="ticketData.count"
      :tickets-link-query="ticketData.query"
    />
  </div>
  <CommonLoader v-else-if="loading" class="w-full p-4" :loading="loading" />
</template>
