<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useUserNoteUpdateMutation } from '#shared/entities/user/graphql/mutations/noteUpdate.api.ts'
import { EnumTicketStateTypeCategory, type Organization, type User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'
import TicketListPopoverWithTrigger from '#desktop/components/Ticket/TicketListPopoverWithTrigger.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import { useUserEdit } from '#desktop/entities/user/composables/useUserEdit.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  customer: User
  secondaryOrganizations: ReturnType<typeof normalizeEdges<Partial<Organization>>>
  objectAttributes: ObjectAttribute[]
  // Owned by the sidebar, which also offers it when there is no customer.
  changeCustomerMenuItem: MenuItem
}

const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

defineEmits<{
  'load-more-secondary-organizations': []
}>()

const { openUserEditFlyout } = useUserEdit()

const actions = computed<MenuItem[]>(() => [
  props.changeCustomerMenuItem,
  {
    key: 'edit-customer',
    label: __('Edit customer'),
    icon: 'pencil',
    show: () => props.customer.policy.update,
    onClick: () => openUserEditFlyout(props.customer, { title: __('Edit customer') }),
  },
])
</script>
<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="customer"
    :actions="actions"
  >
    <UserInfo :user="customer" has-organization-popover />

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="customer"
      :skip-attributes="['firstname', 'lastname', 'organization_id', 'organization_ids']"
      :inline-editable="{ note: useUserNoteUpdateMutation }"
      :style="{
        '--top-header-height': '-4.5px', // Needed to offset the negative vertical margin of the inline editor and not receive the global header height as top value
      }"
    />

    <CommonSimpleEntityList
      v-if="secondaryOrganizations.totalCount"
      id="customer-secondary-organizations"
      v-model="persistentStates.collapseOrganizations"
      :type="EntityType.Organization"
      :label="__('Secondary organizations')"
      :entity="secondaryOrganizations"
      has-popover
      @load-more="$emit('load-more-secondary-organizations')"
    />

    <CommonSectionCollapse
      v-if="customer.ticketsCount?.open || customer.ticketsCount?.closed"
      id="customer-tickets"
      v-model="persistentStates.collapseTickets"
      :title="__('Tickets')"
    >
      <NavigationMenuList
        class="mt-1"
        :density="NavigationMenuDensity.Dense"
        :items="[
          {
            id: 'open',
            label: __('open tickets'),
            title: __('Open tickets'),
            icon: 'check-circle-no',
            iconColor: 'fill-yellow-500',
            count: customer?.ticketsCount?.open || 0,
            route: `/search/${customer?.ticketsCount?.openSearchQuery ?? ''}?entity=Ticket`,
            show: () => Boolean(customer?.ticketsCount?.open),
          },
          {
            id: 'closed',
            label: __('closed tickets'),
            title: __('Closed tickets'),
            icon: 'check-circle-outline',
            iconColor: 'fill-green-400',
            count: customer?.ticketsCount?.closed || 0,
            route: `/search/${customer?.ticketsCount?.closedSearchQuery ?? ''}?entity=Ticket`,
            show: () => Boolean(customer?.ticketsCount?.closed),
          },
        ]"
      >
        <template #default="{ entry, paddingClasses, countSize, countVariant }">
          <TicketListPopoverWithTrigger
            :filters="{
              customerId: customer.id,
              stateTypeCategory:
                entry.id === 'open'
                  ? EnumTicketStateTypeCategory.Open
                  : EnumTicketStateTypeCategory.Closed,
            }"
            :title="entry.title!"
            :no-results="entry.count === 0"
            :trigger-class="[
              'focus-visible-app-default flex items-center gap-1 rounded-lg! text-sm text-normal hover:bg-blue-600 hover:text-contrast! hover:no-underline! dark:hover:bg-blue-900',
              paddingClasses,
            ]"
            :trigger-link="typeof entry.route === 'string' ? entry.route : undefined"
            :popover-config="{
              orientation: 'left',
            }"
            no-hover-styling
          >
            <CommonIcon
              size="small"
              aria-hidden="true"
              class="h-4 shrink-0"
              :class="entry.iconColor"
              :name="entry.icon!"
            />
            <CommonLabel class="line-clamp-1! grow text-current!">
              {{ $t(entry.label) }}
            </CommonLabel>
            <CommonBadge
              class="cursor-pointer leading-snug font-bold"
              :size="countSize"
              :variant="countVariant"
              rounded
            >
              {{ entry.count }}
            </CommonBadge>
          </TicketListPopoverWithTrigger>
        </template>
      </NavigationMenuList>
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
