<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContentProps } from '../types.ts'

const props = defineProps<TicketSidebarContentProps>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

const {
  user: customer,
  objectAttributes,
  secondaryOrganizations,
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

    <CommonSimpleEntityList
      v-if="secondaryOrganizations.totalCount"
      :type="EntityType.Organization"
      :label="$t('Secondary organizations')"
      :entity="secondaryOrganizations"
      @load-more="loadAllSecondaryOrganizations"
    />

    <div class="flex flex-col">
      <CommonLabel
        id="customer-tickets"
        size="small"
        class="mt-2 text-stone-200 dark:text-neutral-500"
      >
        {{ $t('Tickets') }}
      </CommonLabel>

      <NavigationMenuList
        class="mt-1"
        aria-labelledby="customer-tickets"
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
