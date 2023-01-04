<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable zammad/zammad-detect-translatable-string */
import { useRouter } from 'vue-router'
import { computed } from 'vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { useHeader } from '@mobile/composables/useHeader'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import { redirectToError } from '@mobile/router/error'
import { ErrorStatusCodes } from '@shared/types/error'
import { useOrganizationEdit } from '@mobile/entities/organization/composables/useOrganizationEdit'
import OrganizationMembersList from '@mobile/components/Organization/OrganizationMembersList.vue'
import { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar'
import ObjectAttributes from '@shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationTicketsCount } from '@mobile/entities/organization/composables/useOrganizationTicketsCount'
import { useOrganizationDetail } from '@mobile/entities/organization/composables/useOrganizationDetail'

interface Props {
  internalId: number
}

const props = defineProps<Props>()

const {
  organization,
  organizationQuery,
  loading,
  objectAttributes,
  loadAllMembers,
  loadOrganization,
} = useOrganizationDetail()

loadOrganization(props.internalId)

const router = useRouter()

organizationQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const { openEditOrganizationDialog } = useOrganizationEdit()

useHeader({
  title: __('Organization'),
  backUrl: '/',
  actionTitle: __('Edit'),
  onAction() {
    if (!organization.value) return
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
          :entity="(organization as AvatarOrganization)"
          size="xl"
          personal
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
