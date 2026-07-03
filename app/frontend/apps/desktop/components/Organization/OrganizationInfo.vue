<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Sizes } from '#shared/components/CommonLabel/types.ts'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/types.ts'
import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import type { Organization } from '#shared/graphql/types.ts'

interface Props {
  organization: Partial<Organization>
  size?: 'small' | 'normal'
  dense?: boolean
  noLink?: boolean
  titleSize?: Sizes
  titleClass?: string
  responsive?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'normal',
})

const avatarComponent = computed(() => (props.noLink || props.dense ? 'div' : 'CommonLink'))
const nameComponent = computed(() => (props.noLink && !props.dense ? 'div' : 'CommonLink'))

const labelSize = computed(() => (props.size === 'normal' ? 'large' : 'medium'))

const { organizationDisplayName } = useOrganizationEntity(toRef(props, 'organization'))
</script>

<template>
  <!-- 1024 container size plus 24 padding -=  -->
  <div
    class="flex w-full max-w-262 items-center"
    :class="{ 'gap-2': !titleSize, 'gap-3': titleSize }"
  >
    <component
      :is="avatarComponent"
      :class="{
        'hover:rounded-full hover:no-underline! hover:outline-1 hover:outline-blue-600 focus-visible:rounded-full! hover:dark:outline-blue-900':
          !dense && !noLink,
      }"
      :link="!dense && !noLink ? `/organizations/${organization.internalId}` : undefined"
    >
      <CommonOrganizationAvatar
        :entity="organization as AvatarOrganization"
        :responsive="responsive"
        :size="size"
      />
    </component>
    <component
      :is="nameComponent"
      v-if="dense"
      :class="{ group: !noLink }"
      :link="dense && !noLink ? `/organizations/${organization.internalId}` : undefined"
    >
      <CommonLabel
        class="line-clamp-2! break-word"
        :class="{
          [`${titleClass}`]: titleClass,
          'text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!': !noLink,
        }"
        :size="titleSize ? titleSize : labelSize"
      >
        {{ organizationDisplayName }}
      </CommonLabel>
    </component>
    <div v-else class="flex items-center">
      <CommonLabel
        class="line-clamp-2! break-word"
        :class="titleClass"
        :size="titleSize ? titleSize : labelSize"
      >
        {{ organizationDisplayName }}
      </CommonLabel>
      <slot name="label-trailing" />
    </div>

    <slot name="actions" />
  </div>
</template>
