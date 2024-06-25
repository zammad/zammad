<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContext } from '../types.ts'

interface Props {
  context: TicketSidebarContext
}

const props = defineProps<Props>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

const {
  user: customer,
  objectAttributes,
  secondaryOrganizations,
  loading,
  loadAllSecondaryOrganizations,
} = useUserDetail(customerId, undefined, 'cache-first')

const actions: MenuItem[] = [
  {
    key: 'change-customer',
    label: __('Edit Customer'),
    icon: 'person-gear',
    show: (entity) => entity?.policy.update,
    onClick: (id) => {
      console.log(id, 'Edit customer')
    },
  },
]
</script>

<template>
  <TicketSidebarContent
    v-if="customer"
    :title="__('Customer')"
    icon="person"
    :entity="customer"
    :actions="actions"
  >
    <div class="flex gap-2">
      <CommonUserAvatar :entity="customer" size="normal" />
      <div class="flex flex-col justify-center gap-px">
        <CommonLabel size="large" class="text-gray-300 dark:text-neutral-400">
          {{ customer.fullname }}
        </CommonLabel>

        <CommonLink
          v-if="customer.organization"
          :link="`/organizations/${customer.organization.internalId}`"
          class="text-sm leading-snug"
        >
          {{ customer.organization.name }}
        </CommonLink>
      </div>
    </div>

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="customer"
      :skip-attributes="['firstname', 'lastname']"
    />

    <div v-if="secondaryOrganizations.totalCount" class="flex flex-col gap-1.5">
      <CommonLabel
        size="small"
        class="mt-2 text-stone-200 dark:text-neutral-500"
      >
        {{ $t('Secondary organizations') }}
      </CommonLabel>

      <CommonLink
        v-for="secondaryOrganization of secondaryOrganizations.array"
        :key="secondaryOrganization.id"
        :link="`/organizations/${secondaryOrganization.internalId}`"
        class="flex items-center gap-1.5 text-sm leading-snug"
      >
        <CommonOrganizationAvatar
          :entity="secondaryOrganization"
          size="small"
        />
        {{ secondaryOrganization.name }}
      </CommonLink>

      <CommonShowMoreButton
        class="self-end"
        :entities="secondaryOrganizations.array"
        :total-count="secondaryOrganizations.totalCount"
        :disabled="loading"
        @click="loadAllSecondaryOrganizations"
      />
    </div>

    <div class="flex flex-col">
      <CommonLabel
        size="small"
        class="mt-2 text-stone-200 dark:text-neutral-500"
      >
        {{ $t('Tickets') }}
      </CommonLabel>

      <NavigationMenuList
        class="mt-1"
        :density="NavigationMenuDensity.Dense"
        :items="[
          {
            label: __('open tickets'),
            icon: 'check-circle-no',
            iconColor: 'fill-yellow-500',
            count: customer.ticketsCount?.open || 0,
            route: '/search/ticket/open',
          },
          {
            label: __('closed tickets'),
            icon: 'check-circle-outline',
            iconColor: 'fill-green-400',
            count: customer.ticketsCount?.closed || 0,
            route: '/search/ticket/closed',
          },
        ]"
      />
    </div>
  </TicketSidebarContent>
</template>
