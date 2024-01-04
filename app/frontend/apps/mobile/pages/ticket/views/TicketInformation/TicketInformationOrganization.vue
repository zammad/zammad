<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watchEffect } from 'vue'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonTicketStateList from '#mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationEdit } from '#mobile/entities/organization/composables/useOrganizationEdit.ts'
import OrganizationMembersList from '#mobile/components/Organization/OrganizationMembersList.vue'
import { useOrganizationTicketsCount } from '#mobile/entities/organization/composables/useOrganizationTicketsCount.ts'
import { useOrganizationDetail } from '#mobile/entities/organization/composables/useOrganizationDetail.ts'
import { useTicketInformation } from '../../composable/useTicketInformation.ts'

const { ticket, updateRefetchingStatus } = useTicketInformation()

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

watchEffect(() => {
  updateRefetchingStatus(
    organizationLoading.value && organization.value != null,
  )
})

const { openEditOrganizationDialog } = useOrganizationEdit()
const { getTicketData } = useOrganizationTicketsCount()

const ticketsData = computed(() => getTicketData(organization.value))
</script>

<template>
  <CommonLoader :loading="!organization && organizationLoading" :error="error">
    <div v-if="organization" class="mb-3 flex items-center gap-3">
      <CommonOrganizationAvatar size="normal" :entity="organization" />
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
        <CommonButton
          class="p-4"
          variant="primary"
          transparent-background
          @click="openEditOrganizationDialog(organization!)"
        >
          {{ $t('Edit Organization') }}
        </CommonButton>
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
