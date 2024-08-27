<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watchEffect, computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import CommonOrganizationsList from '#mobile/components/CommonOrganizationsList/CommonOrganizationsList.vue'
import CommonTicketStateList from '#mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import { useUserEdit } from '#mobile/entities/user/composables/useUserEdit.ts'
import { useUsersTicketsCount } from '#mobile/entities/user/composables/useUserTicketsCount.ts'

import { useTicketInformation } from '../../composable/useTicketInformation.ts'

interface Props {
  internalId: number
}

defineProps<Props>()

const { ticket, updateRefetchingStatus } = useTicketInformation()

const { createQueryErrorHandler } = useErrorHandler()

const errorCallback = createQueryErrorHandler({
  notFound: __(
    'User with specified ID was not found. Try checking the URL for errors.',
  ),
  forbidden: __('You have insufficient rights to view this user.'),
})

const customerInternalId = computed(() => ticket.value?.customer.internalId)

const {
  user,
  loading,
  objectAttributes,
  secondaryOrganizations,
  loadAllSecondaryOrganizations,
} = useUserDetail(customerInternalId, errorCallback)

watchEffect(() => {
  updateRefetchingStatus(loading.value && user.value != null)
})

const { openEditUserDialog } = useUserEdit()

const { getTicketData } = useUsersTicketsCount()
const ticketsData = computed(() => getTicketData(user.value))
</script>

<template>
  <CommonLoader :loading="loading && !user">
    <div v-if="user" class="mb-3 flex items-center gap-3">
      <CommonUserAvatar aria-hidden="true" size="normal" :entity="user" />
      <div>
        <h2 class="text-lg font-semibold">
          {{ user.fullname }}
        </h2>
        <h3 v-if="user.organization">
          <CommonLink
            :link="`/organizations/${user.organization.internalId}`"
            class="text-blue"
          >
            {{ user.organization.name }}
          </CommonLink>
        </h3>
      </div>
    </div>
  </CommonLoader>
  <div v-if="user">
    <ObjectAttributes
      :attributes="objectAttributes"
      :object="user"
      :skip-attributes="['firstname', 'lastname']"
      :always-show-after-fields="user.policy.update"
    >
      <template v-if="user.policy.update" #after-fields>
        <CommonButton
          class="p-4"
          variant="primary"
          transparent-background
          @click="openEditUserDialog(user!)"
        >
          {{ $t('Edit Customer') }}
        </CommonButton>
      </template>
    </ObjectAttributes>
    <CommonOrganizationsList
      :organizations="secondaryOrganizations.array"
      :total-count="secondaryOrganizations.totalCount"
      :disable-show-more="loading"
      :label="__('Secondary organizations')"
      @show-more="loadAllSecondaryOrganizations()"
    />
    <CommonTicketStateList
      v-if="ticketsData"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
    />
  </div>
</template>
