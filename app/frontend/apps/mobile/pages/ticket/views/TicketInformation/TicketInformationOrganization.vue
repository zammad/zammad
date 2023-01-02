<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watchEffect } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import ObjectAttributes from '@shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationEdit } from '@mobile/entities/organization/composables/useOrganizationEdit'
import OrganizationMembersList from '@mobile/components/Organization/OrganizationMembersList.vue'
import { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar'
import { useOrganizationTicketsCount } from '@mobile/entities/organization/composables/useOrganizationTicketsCount'
import { useOrganizationDetail } from '@mobile/entities/organization/composables/useOrganizationDetail'
import { useTicketInformation } from '../../composable/useTicketInformation'

const { ticket } = useTicketInformation()

const {
  organization,
  organizationQuery,
  loading: organizationLoading,
  objectAttributes,
  loadAllMembers,
  loadOrganization,
} = useOrganizationDetail()

const error = ref('')
organizationQuery.onError((apolloError) => {
  error.value = apolloError.message
})

watchEffect(() => {
  const organizationId = ticket.value?.organization?.internalId
  if (!organizationId) {
    return
  }

  loadOrganization(organizationId)
})

const { openEditOrganizationDialog } = useOrganizationEdit()
const { getTicketData } = useOrganizationTicketsCount()

const ticketsData = computed(() => getTicketData(organization.value))
</script>

<template>
  <CommonLoader :loading="!organization && organizationLoading" :error="error">
    <div v-if="organization" class="mb-3 flex items-center gap-3">
      <CommonOrganizationAvatar
        size="normal"
        :entity="(organization as AvatarOrganization)"
      />
      <h2 class="text-lg font-semibold">
        {{ organization.name }}
      </h2>
    </div>
  </CommonLoader>
  <div v-if="organization">
    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name']"
    >
      <template v-if="organization.policy.update" #after-fields>
        <button
          class="p-4 text-blue"
          @click="openEditOrganizationDialog(organization!)"
        >
          {{ $t('Edit Organization') }}
        </button>
      </template>
    </ObjectAttributes>

    <OrganizationMembersList
      :organization="organization"
      :disable-show-more="organizationLoading"
      @load-more="loadAllMembers()"
    />

    <CommonTicketStateList
      v-if="ticketsData"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
    />
  </div>
</template>
