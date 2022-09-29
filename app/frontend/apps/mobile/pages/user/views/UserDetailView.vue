<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { useUserEdit } from '@mobile/entities/user/composables/useUserEdit'
import { computed, ref } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonObjectAttributes from '@mobile/components/CommonObjectAttributes/CommonObjectAttributes.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import type { ButtonPillOption } from '@mobile/components/CommonButtonPills/types'
import CommonButtonPills from '@mobile/components/CommonButtonPills/CommonButtonPills.vue'
import { useOrganizationTicketsCount } from '@mobile/entities/organization/composables/useOrganizationTicketsCount'
import { useUsersTicketsCount } from '@mobile/entities/user/composables/useUserTicketsCount'
import { useUserDetail } from '@mobile/entities/user/composables/useUserDetail'
import CommonOrganizationsList from '@mobile/components/CommonOrganizationsList/CommonOrganizationsList.vue'

interface Props {
  internalId: number
}

const props = defineProps<Props>()

const { user, loading, objectAttributes, loadUser } = useUserDetail()

loadUser(props.internalId)

const { openEditUserDialog } = useUserEdit()

useHeader({
  title: __('User'),
  backUrl: '/',
  actionTitle: __('Edit'),
  actionDisabled: computed(() => user.value == null),
  onAction() {
    if (!user.value) return
    openEditUserDialog(user.value)
  },
})

enum TicketLinksState {
  User = 'user',
  Organization = 'organization',
}

const ticketView = ref(TicketLinksState.User)

const ticketButtons = computed<ButtonPillOption[]>(() => {
  if (!user.value?.organization) return []
  return [
    {
      label: __('Their tickets'),
      value: TicketLinksState.User,
    },
    {
      label: __('Organization tickets'),
      value: TicketLinksState.Organization,
    },
  ]
})

const { getTicketData: getOrganizationTicketsData } =
  useOrganizationTicketsCount()
const { getTicketData: getUserTicketsData } = useUsersTicketsCount()

const ticketsData = computed(() => {
  if (!user.value) return null

  if (ticketView.value === TicketLinksState.User) {
    return getUserTicketsData(user.value)
  }

  const { organization } = user.value

  if (!organization) return null

  return getOrganizationTicketsData(organization)
})

// TODO when API is done
const secondaryOrganizations = [
  { id: '1x', internalId: 1, name: 'Zammad' },
  { id: '2x', internalId: 2, name: 'Dammaz' },
]
</script>

<template>
  <div v-if="user" class="px-4">
    <div class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonUserAvatar :entity="user" size="xl" />
      </div>
      <div class="mt-2 text-center text-xl font-bold line-clamp-3">
        {{ user.fullname }}
      </div>
      <CommonLink
        v-if="user.organization"
        data-test-id="organization-link"
        :link="`/organizations/${user.organization.id}`"
        class="text-center text-base text-blue"
      >
        {{ user.organization.name }}
      </CommonLink>
    </div>

    <CommonObjectAttributes :attributes="objectAttributes" :object="user" />

    <CommonOrganizationsList
      :organizations="secondaryOrganizations"
      :label="__('Secondary organizations')"
    />

    <CommonTicketStateList
      v-if="ticketsData"
      :create-link="ticketsData.createLink"
      :create-label="ticketsData.createLabel"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
    >
      <template #before-fields>
        <CommonButtonPills
          v-if="ticketButtons.length"
          v-model="ticketView"
          class="py-3"
          no-border
          :options="ticketButtons"
        />
      </template>
    </CommonTicketStateList>
  </div>
  <CommonLoader v-else center :loading="loading" />
</template>
