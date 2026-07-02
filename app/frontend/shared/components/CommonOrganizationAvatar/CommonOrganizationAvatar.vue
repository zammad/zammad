<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'

import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'
import { nextSmallerAvatarSize } from '../CommonAvatar/index.ts'

import type { AvatarOrganization } from './types.ts'
import type { AvatarSize } from '../CommonAvatar/index.ts'

export interface Props {
  entity: AvatarOrganization
  size?: AvatarSize
  // When `true`, `size` applies from the @5xl container breakpoint upwards and
  // the avatar scales down to the next smaller size below it (see CommonAvatar).
  responsive?: boolean
}

const props = defineProps<Props>()

const icon = computed(() => {
  return props.entity.active ? 'organization' : 'inactive-organization'
})

const { base, inactive } = getOrganizationAvatarClasses()

// Inner padding scales the organization icon together with the avatar size.
const paddingForSize = (size?: AvatarSize) => {
  switch (size) {
    case 'xs':
      return 'p-0.5'
    case 'small':
      return 'p-2'
    case 'medium':
      return 'p-2.5'
    case 'large':
      return 'p-4'
    case 'xl':
      return 'p-6'
    default:
      // normal (and unset)
      return 'p-3.5'
  }
}

// The breakpoint here must match the avatar's size-restore breakpoint in
// CommonAvatar (@6xl); otherwise the padding grows before the circle does and
// squeezes the icon in the intermediate range.
const responsivePaddingForSize = (size?: AvatarSize) => {
  switch (size) {
    case 'xs':
      return '@5xl:p-0.5'
    case 'small':
      return '@5xl:p-2'
    case 'medium':
      return '@5xl:p-2.5'
    case 'large':
      return '@5xl:p-4'
    case 'xl':
      return '@5xl:p-6'
    default:
      return '@5xl:p-3.5'
  }
}

const sizeClass = computed(() => {
  const resolvedSize = props.size ?? 'medium'
  if (!props.responsive) return paddingForSize(resolvedSize)

  return [
    paddingForSize(nextSmallerAvatarSize[resolvedSize]),
    responsivePaddingForSize(resolvedSize),
  ]
})
</script>

<template>
  <CommonAvatar
    :class="[
      base,
      sizeClass,
      {
        [inactive]: !entity.active,
      },
    ]"
    :size="size"
    :responsive="responsive"
    :icon="icon"
    :aria-label="`Avatar (${entity.name})`"
    :vip-icon="entity.vip ? 'vip-organization' : undefined"
  />
</template>
