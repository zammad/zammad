<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useOrganizationNoteUpdateMutation } from '#shared/entities/organization/graphql/mutations/noteUpdate.api.ts'
import type { Organization, User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import { useOrganizationEdit } from '#desktop/entities/organization/composables/useOrganizationEdit.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  organization: Organization
  organizationMembers: ReturnType<typeof normalizeEdges<Partial<User>>>
  objectAttributes: ObjectAttribute[]
}

const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

defineEmits<{
  'load-more-members': []
}>()

const { openOrganizationEditFlyout } = useOrganizationEdit()

const actions: MenuItem[] = [
  {
    key: 'edit-organization',
    label: __('Edit organization'),
    icon: 'pencil',
    show: (entity) => entity?.policy.update,
    onClick: () =>
      openOrganizationEditFlyout(props.organization, { title: __('Edit organization') }),
  },
]
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="organization"
    :actions="actions"
  >
    <OrganizationInfo :organization="organization" />

    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name', 'vip', 'active']"
      :inline-editable="{
        note: useOrganizationNoteUpdateMutation,
      }"
    />

    <CommonSimpleEntityList
      id="organization-members"
      v-model="persistentStates.collapseMembers"
      :type="EntityType.User"
      :label="__('Members')"
      :entity="organizationMembers"
      has-popover
      @load-more="$emit('load-more-members')"
    />
  </TicketSidebarContent>
</template>
