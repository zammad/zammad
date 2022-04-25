<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonIcon from '@common/components/common/CommonIcon.vue'
import type { AvatarSize } from '@common/types/avatar'

export interface Props {
  initials?: string
  // path to image
  image?: Maybe<string>
  // name of the icon
  icon?: Maybe<string>
  size?: AvatarSize
  vip?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  initials: '??',
})

const iconSizes = {
  small: 'tiny',
  medium: 'small',
  large: 'medium',
} as const

const iconSize = computed(() => {
  if (!props.icon) return 'medium'
  return iconSizes[props.size]
})
</script>

<template>
  <span
    v-bind:style="{
      backgroundImage: image ? `url(${image})` : undefined,
    }"
    v-bind:class="[
      'text-white relative inline-flex h-10 w-10 shrink-0',
      'items-center justify-center rounded-full bg-cover bg-center',
      `size-${size}`,
    ]"
    data-test-id="common-avatar"
  >
    <CommonIcon
      v-if="vip"
      class="vip absolute left-1/2 -top-[15px] -ml-4 w-8"
      name="crown"
    />
    <CommonIcon v-if="icon" v-bind:name="icon" v-bind:size="iconSize" />
    <slot v-else>
      {{ image ? '' : initials }}
    </slot>
  </span>
</template>

<style scoped lang="scss">
.size-small {
  @apply h-8 w-8 text-xs leading-8;

  .vip {
    @apply -ml-3 w-6;
  }
}

.size-large {
  @apply h-20 w-20 text-2xl leading-[5rem];

  .vip {
    @apply -ml-8 w-16;
  }
}

.vip {
  fill: hsl(47, 100%, 59%);
}
</style>
