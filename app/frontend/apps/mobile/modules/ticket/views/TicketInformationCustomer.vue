<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useUserDetail } from '@mobile/entities/user/composables/useUserDetail'
import { useUserEdit } from '@mobile/entities/user/composables/useUserEdit'
import { useUsersTicketsCount } from '@mobile/entities/user/composables/useUserTicketsCount'
import type { ComputedRef } from 'vue'
import { watchEffect, computed, inject } from 'vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import CommonObjectAttributes from '@mobile/components/CommonObjectAttributes/CommonObjectAttributes.vue'
import { useSessionStore } from '@shared/stores/session'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonOrganizationsList from '@mobile/components/CommonOrganizationsList/CommonOrganizationsList.vue'
import type { TicketById } from '../types/tickets'

interface Props {
  internalId: number
}

defineProps<Props>()

const ticket = inject('ticket') as ComputedRef<Maybe<TicketById>>

const session = useSessionStore()
const { user, loading, objectAttributes, loadUser } = useUserDetail()

watchEffect(() => {
  if (ticket.value) {
    loadUser(ticket.value.customer.internalId)
  }
})

const { openEditUserDialog } = useUserEdit()

const { getTicketData } = useUsersTicketsCount()
const ticketsData = computed(() => getTicketData(user.value))

// TODO when API is done
const secondaryOrganizations = [
  { id: '1x', internalId: 1, name: 'Zammad' },
  { id: '2x', internalId: 2, name: 'Dammaz' },
]
</script>

<template>
  <CommonLoader :loading="loading">
    <div v-if="user" class="mb-3 flex items-center gap-3">
      <CommonUserAvatar size="normal" :entity="user" />
      <h2 class="text-lg font-semibold">
        {{ user.fullname }}
      </h2>
    </div>
  </CommonLoader>
  <div v-if="user">
    <CommonObjectAttributes :attributes="objectAttributes" :object="user">
      <template v-if="session.hasPermission(['ticket.agent'])" #after-fields>
        <button class="p-4 text-blue" @click="openEditUserDialog(user!)">
          {{ $t('Edit Customer') }}
        </button>
      </template>
    </CommonObjectAttributes>
    <CommonOrganizationsList
      :organizations="secondaryOrganizations"
      :label="__('Secondary organizations')"
    />
    <CommonTicketStateList
      v-if="ticketsData"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
    />
  </div>
</template>
