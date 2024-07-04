<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import { computed } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationDetail } from '#shared/entities/organization/composables/useOrganizationDetail.ts'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContentProps } from '../types.ts'

const props = defineProps<TicketSidebarContentProps>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

const { user: customer } = useUserDetail(customerId, undefined, 'cache-first')

const organizationInternalId = computed(() => {
  if (props.context.formValues?.organization_id)
    return Number(props.context.formValues?.organization_id)

  return customer.value?.organization?.internalId
})

const { organization, objectAttributes, loadAllMembers } =
  useOrganizationDetail(organizationInternalId, undefined, 'cache-first')

const actions: MenuItem[] = [
  {
    key: 'edit-organization',
    label: __('Edit Organization'),
    icon: 'organization-edit',
    show: (entity) => entity?.policy.update,
    onClick: (id) => {
      console.log(id, 'Edit organization')
    },
  },
]

const normalizedMembersList = computed(
  () => normalizeEdges(organization.value?.allMembers) || [],
)
</script>

<template>
  <TicketSidebarContent
    v-if="organization"
    :title="__('Organization')"
    icon="buildings"
    :entity="organization"
    :actions="actions"
  >
    <CommonLink
      :link="`/organizations/${organization.internalId}`"
      class="flex gap-2"
    >
      <CommonOrganizationAvatar
        class="p-3.5"
        :entity="organization"
        size="normal"
      />
      <CommonLabel size="large" class="dark:text-white"
        >{{ organization.name }}
      </CommonLabel>
    </CommonLink>

    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name', 'vip', 'active']"
    />

    <CommonSimpleEntityList
      :type="EntityType.User"
      :label="$t('Members')"
      :entity="normalizedMembersList"
      @load-more="loadAllMembers"
    />
  </TicketSidebarContent>
</template>
