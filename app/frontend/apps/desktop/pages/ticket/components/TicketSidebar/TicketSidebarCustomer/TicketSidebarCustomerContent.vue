<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { Organization, UserQuery } from '#shared/graphql/types.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'
import { useChangeCustomerMenuItem } from '#desktop/pages/ticket/components/TicketDetailView/actions/TicketChangeCustomer/useChangeCustomerMenuItem.ts'
import {
  type TicketSidebarContentProps,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  customer: UserQuery['user']
  secondaryOrganizations: ReturnType<
    typeof normalizeEdges<Partial<Organization>>
  >
  objectAttributes: ObjectAttribute[]
}

const props = defineProps<Props>()

defineEmits<{
  'load-more-secondary-organizations': []
}>()

const actions = computed<MenuItem[]>(() => {
  const availableActions: MenuItem[] = []

  // :TODO find a way to provide the ticket via prop
  if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) {
    const { customerChangeMenuItem } = useChangeCustomerMenuItem()
    availableActions.push(customerChangeMenuItem)
  }

  return availableActions // ADD the rest available menu actions
})
</script>

<template>
  <TicketSidebarContent
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="customer"
    :actions="actions"
  >
    <div class="flex gap-2">
      <CommonUserAvatar v-if="customer" :entity="customer" size="normal" />
      <div class="flex flex-col justify-center gap-px">
        <CommonLabel size="large" class="text-gray-300 dark:text-neutral-400">
          {{ customer?.fullname }}
        </CommonLabel>

        <CommonLink
          v-if="customer?.organization"
          :link="`/organizations/${customer.organization?.internalId}`"
          class="text-sm leading-snug"
        >
          {{ customer?.organization.name }}
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
      id="customer-secondary-organizations"
      :type="EntityType.Organization"
      :label="__('Secondary organizations')"
      :entity="secondaryOrganizations"
      @load-more="$emit('load-more-secondary-organizations')"
    />

    <CommonSectionCollapse id="customer-tickets" :title="__('Tickets')">
      <NavigationMenuList
        class="mt-1"
        :density="NavigationMenuDensity.Dense"
        :items="[
          {
            label: __('open tickets'),
            icon: 'check-circle-no',
            iconColor: 'fill-yellow-500',
            count: customer?.ticketsCount?.open || 0,
            route: '/search/ticket/open',
          },
          {
            label: __('closed tickets'),
            icon: 'check-circle-outline',
            iconColor: 'fill-green-400',
            count: customer?.ticketsCount?.closed || 0,
            route: '/search/ticket/closed',
          },
        ]"
      />
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
