<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { useUserEdit } from '@mobile/entities/user/composables/useUserEdit'
import { computed, ref } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '@shared/components/ObjectAttributes/ObjectAttributes.vue'
import CommonTicketStateList from '@mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import type { CommonButtonOption } from '@mobile/components/CommonButtonGroup/types'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import { useOrganizationTicketsCount } from '@mobile/entities/organization/composables/useOrganizationTicketsCount'
import { useUsersTicketsCount } from '@mobile/entities/user/composables/useUserTicketsCount'
import { useUserDetail } from '@mobile/entities/user/composables/useUserDetail'
import CommonOrganizationsList from '@mobile/components/CommonOrganizationsList/CommonOrganizationsList.vue'
import { normalizeEdges } from '@shared/utils/helpers'

interface Props {
  internalId: number
}

const props = defineProps<Props>()

const {
  user,
  loading,
  objectAttributes,
  loadUser,
  loadAllSecondaryOrganizations,
} = useUserDetail()

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

const ticketButtons = computed<CommonButtonOption[]>(() => {
  if (!user.value?.organization) return []
  return [
    {
      label: __('Their tickets'),
      value: TicketLinksState.User,
      controls: `tab-${TicketLinksState.User}`,
    },
    {
      label: __('Organization tickets'),
      value: TicketLinksState.Organization,
      controls: `tab-${TicketLinksState.Organization}`,
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

const secondaryOrganizations = computed(() =>
  normalizeEdges(user.value?.secondaryOrganizations),
)
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
        :link="`/organizations/${user.organization.internalId}`"
        class="text-center text-base text-blue"
      >
        {{ user.organization.name }}
      </CommonLink>
    </div>

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="user"
      :skip-attributes="['firstname', 'lastname']"
    />

    <CommonOrganizationsList
      :organizations="secondaryOrganizations.array"
      :total-count="secondaryOrganizations.totalCount"
      :disable-show-more="loading"
      :label="__('Secondary organizations')"
      @show-more="loadAllSecondaryOrganizations()"
    />

    <CommonTicketStateList
      v-if="ticketsData"
      :id="`tab-${ticketView}`"
      :create-link="ticketsData.createLink"
      :create-label="ticketsData.createLabel"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
      role="tabpanel"
      aria-live="polite"
    >
      <template #before-fields>
        <CommonButtonGroup
          v-if="ticketButtons.length"
          v-model="ticketView"
          as="tabs"
          class="py-2"
          :options="ticketButtons"
        />
      </template>
    </CommonTicketStateList>
  </div>
  <CommonLoader v-else :loading="loading" />
</template>
