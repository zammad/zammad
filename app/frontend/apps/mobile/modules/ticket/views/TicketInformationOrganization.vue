<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { QueryHandler } from '@shared/server/apollo/handler'
import type { ComputedRef } from 'vue'
import { computed, ref, watchEffect, inject } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import CommonObjectAttributes from '@mobile/components/CommonObjectAttributes/CommonObjectAttributes.vue'
import { useOrganizationObjectManagerAttributesStore } from '@mobile/entities/organization/stores/objectManagerAttributes'
import { useOrganizationLazyQuery } from '@mobile/entities/organization/graphql/queries/organization.api'
import { useOrganizationEdit } from '@mobile/entities/organization/composables/useOrganizationEdit'
import OrganizationMembersList from '@mobile/components/Organization/OrganizationMembersList.vue'
import { OrganizationUpdatesDocument } from '@mobile/entities/organization/graphql/subscriptions/organizationUpdates.api'
import { useSessionStore } from '@shared/stores/session'
import type { TicketById } from '../types/tickets'

const ticket = inject('ticket') as ComputedRef<Maybe<TicketById>>

const session = useSessionStore()

const organizationQuery = new QueryHandler(
  useOrganizationLazyQuery(() => ({
    organizationId: ticket.value?.organization?.id || '',
    membersCount: 3,
  })),
)

const organizationResult = organizationQuery.result()
const organization = computed(() => organizationResult.value?.organization)
const organizationLoading = organizationQuery.loading()

const error = ref('')
organizationQuery.onError((apolloError) => {
  error.value = apolloError.message
})

watchEffect(() => {
  const organizationId = ticket.value?.organization?.id
  if (!organizationId) {
    return
  }
  organizationQuery.load()

  organizationQuery.subscribeToMore({
    document: OrganizationUpdatesDocument,
    variables: {
      organizationId,
    },
  })
})

const loadAllMembers = () => {
  organizationQuery.refetch({
    organizationId: organization.value?.id || '',
    membersCount: null,
  })
}

const objectAttributesManager = useOrganizationObjectManagerAttributesStore()

const objectAttributes = computed(
  () => objectAttributesManager.attributes || [],
)

const { openEditOrganizationDialog } = useOrganizationEdit()

const ticketsLinkQuery = computed(() => {
  return `organization.name: "${organization.value?.name}"`
})
</script>

<template>
  <CommonLoader
    center
    :loading="!organization && organizationLoading"
    :error="error"
  >
    <div v-if="organization" class="mb-3 flex items-center gap-3">
      <CommonOrganizationAvatar size="normal" :entity="organization" />
      <h2 class="text-lg font-semibold">
        {{ organization.name }}
      </h2>
    </div>
  </CommonLoader>
  <div v-if="organization">
    <CommonObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
    >
      <template v-if="session.hasPermission(['ticket.agent'])" #after-fields>
        <button
          class="p-4 text-blue"
          @click="openEditOrganizationDialog(organization!)"
        >
          {{ $t('Edit organization') }}
        </button>
      </template>
    </CommonObjectAttributes>

    <OrganizationMembersList
      :organization="organization"
      :disable-show-more="organizationLoading"
      @load-more="loadAllMembers()"
    />

    <CommonTicketStateList
      v-if="organization.ticketsCount"
      :counts="organization.ticketsCount"
      :tickets-link-query="ticketsLinkQuery"
    />
  </div>
</template>
