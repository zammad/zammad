<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AvatarUserLive } from '#shared/components/CommonUserAvatar/types.ts'
import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import type { User } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'

interface Props {
  user: Partial<User>
  live?: AvatarUserLive
  size?: 'small' | 'normal'
  dense?: boolean
  noLink?: boolean
  hasOrganizationPopover?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'normal',
})

const avatarComponent = computed(() => (props.noLink || props.dense ? 'div' : 'CommonLink'))
const nameComponent = computed(() => (props.noLink && !props.dense ? 'div' : 'CommonLink'))

const labelSize = computed(() => (props.size === 'normal' ? 'large' : 'medium'))
</script>

<template>
  <div class="flex items-center gap-2">
    <component
      :is="avatarComponent"
      :class="{
        'hover:no-underline! hover:rounded-full hover:outline-1 hover:outline-blue-600 hover:dark:outline-blue-900':
          !dense && !noLink,
      }"
      :link="!dense && !noLink ? `/user/profile/${getIdFromGraphQLId(user.id!)}` : undefined"
    >
      <CommonUserAvatar v-if="user" :entity="user as AvatarUser" :live="live" :size="size" />
    </component>
    <div class="flex flex-col justify-center gap-px">
      <component
        :is="nameComponent"
        v-if="dense"
        class="text-sm leading-snug"
        :class="{ group: !noLink }"
        :link="!noLink ? `/user/profile/${getIdFromGraphQLId(user.id!)}` : undefined"
      >
        <CommonLabel
          :class="{
            'text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!': !noLink,
          }"
          :size="labelSize"
        >
          {{ user.fullname }}
        </CommonLabel>
      </component>
      <CommonLabel v-else :size="labelSize" class="text-gray-300! dark:text-neutral-400!">
        {{ user.fullname }}
      </CommonLabel>

      <OrganizationPopoverWithTrigger
        v-if="!dense && user.organization && hasOrganizationPopover"
        class="rounded-sm outline-offset-1 focus-visible:outline-2!"
        :popover-config="{ orientation: 'left' }"
        :organization="user.organization"
        trigger-link-active-class="outline-2! outline-blue-800! hover:outline-blue-800!"
      >
        <CommonLabel
          class="text-blue-800! hover:text-blue-850! hover:dark:text-blue-600!"
          :size="labelSize"
        >
          {{ user.organization.name }}
        </CommonLabel>
      </OrganizationPopoverWithTrigger>
      <CommonLink
        v-else-if="!dense && user.organization"
        :link="`/organization/profile/${user.organization?.internalId}`"
      >
        <CommonLabel
          class="text-blue-800! hover:text-blue-850! hover:dark:text-blue-600!"
          :size="labelSize"
        >
          {{ user.organization.name }}
        </CommonLabel>
      </CommonLink>
    </div>
  </div>
</template>
