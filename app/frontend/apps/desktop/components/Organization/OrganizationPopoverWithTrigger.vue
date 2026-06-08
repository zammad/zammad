<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonOrganizationAvatar, {
  type Props as CommonOrganizationAvatarProps,
} from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { type Props as CommonPopoverProps } from '#desktop//components/CommonPopover/CommonPopover.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import OrganizationPopover from '#desktop/components/Organization/OrganizationPopoverWithTrigger/OrganizationPopover.vue'

export interface Props {
  organization: AvatarOrganization
  popoverConfig?: Omit<CommonPopoverProps, 'owner'>
  avatarConfig?: Omit<CommonOrganizationAvatarProps, 'entity'>
  triggerClass?: string
  noLink?: boolean
  noFocusStyling?: boolean
  noHoverStyling?: boolean
  zIndex?: string
}

const props = defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

defineSlots<{
  default(props: {
    isOpen?: boolean | undefined
    popoverId?: string
    hasOpenViaLongClick?: boolean
  }): never
}>()

const organizationInternalId = computed(() => getIdFromGraphQLId(props.organization.id))

const session = useSessionStore()

const hasOrganizationAccess = computed(() =>
  session.hasPermission(['ticket.agent', 'admin.organization']),
)
</script>

<template>
  <CommonPopoverWithTrigger
    v-if="hasOrganizationAccess"
    :class="[
      !$slots?.default?.() ? 'rounded-full! focus-visible:outline-2!' : '',
      triggerClass ?? '',
    ]"
    :no-hover-styling="noHoverStyling"
    :no-focus-styling="noFocusStyling"
    :z-index="zIndex"
    :trigger-link="!noLink ? `/organizations/${organizationInternalId}` : undefined"
    :trigger-link-active-class="
      !$slots?.default?.()
        ? 'outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!'
        : ''
    "
    v-bind="{ ...popoverConfig, ...$attrs }"
  >
    <template #popover-content="{ popoverId, hasOpenedViaLongClick }">
      <OrganizationPopover
        :id="popoverId"
        :organization-avatar="organization"
        :has-open-via-long-click="hasOpenedViaLongClick"
      />
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps">
        <CommonOrganizationAvatar v-bind="avatarConfig" :entity="organization" />
      </slot>
    </template>
  </CommonPopoverWithTrigger>
  <div v-else class="pointer-events-none" v-bind="$attrs">
    <slot>
      <CommonOrganizationAvatar v-bind="avatarConfig" :entity="organization" />
    </slot>
  </div>
</template>
