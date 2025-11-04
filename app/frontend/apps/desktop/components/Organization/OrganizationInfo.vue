<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/types.ts'
import type { Organization } from '#shared/graphql/types.ts'

interface Props {
  organization: Partial<Organization>
  size?: 'small' | 'normal'
  dense?: boolean
  noLink?: boolean
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
      :link="!dense && !noLink ? `/organization/profile/${organization.internalId}` : undefined"
    >
      <CommonOrganizationAvatar :entity="organization as AvatarOrganization" :size="size" />
    </component>
    <component
      :is="nameComponent"
      v-if="dense"
      :class="{ group: !noLink }"
      :link="dense && !noLink ? `/organization/profile/${organization.internalId}` : undefined"
    >
      <CommonLabel
        :class="{
          'text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!': !noLink,
        }"
        :size="labelSize"
      >
        {{ organization.name }}
      </CommonLabel>
    </component>
    <CommonLabel v-else :size="labelSize">{{ organization.name }}</CommonLabel>
  </div>
</template>
