<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { AvatarSize } from './types'

export interface Props {
  initials?: string
  // path to image
  image?: Maybe<string>
  // name of the icon
  icon?: Maybe<string>
  size?: AvatarSize
  vip?: Maybe<boolean>
  ariaLabel?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  initials: '??',
})

const iconSizes = {
  xs: 'tiny',
  small: 'small',
  medium: 'base',
  normal: 'medium',
  large: 'large',
  xl: 'xl',
} as const

const iconSize = computed(() => {
  if (!props.icon) return 'medium'
  return iconSizes[props.size]
})

// const iconSize = computed(() => {
//   switch (props.size) {
//     case 'xs':
//       return { width: 16, height: 16 }
//     case 'small':
//       return { width: 22, height: 22 }
//     case 'large':
//       return { width: 68, height: 68 }
//     case 'xl':
//       return { width: 128, height: 128 }
//     case 'medium':
//     case 'normal':
//     default:
//       return { width: 45, height: 45 }
//   }
// })
</script>

<template>
  <span
    :style="{
      backgroundImage: image ? `url(${image})` : undefined,
      backgroundRepeat: image ? 'no-repeat' : undefined,
    }"
    :class="[
      'relative inline-flex h-10 w-10 shrink-0 select-none text-white',
      'items-center justify-center rounded-full bg-cover bg-center',
      `size-${size}`,
    ]"
    role="img"
    :aria-label="ariaLabel || $t('Avatar with initials %s', initials)"
    data-test-id="common-avatar"
  >
    <CommonIcon
      v-if="vip"
      size="xl"
      class="vip absolute left-1/2 -top-[48px] -ml-5 w-10 text-yellow"
      name="mobile-crown"
    />
    <CommonIcon v-if="icon" :name="icon" :size="iconSize" />
    <slot v-else>
      {{ image ? '' : initials }}
    </slot>
  </span>
</template>

<style scoped lang="scss">
.size-xs {
  @apply h-6 w-6 text-xs leading-6;

  .vip {
    @apply -top-[49px] -ml-2 w-4;
  }
}

.size-small {
  @apply h-8 w-8 text-xs leading-8;

  .vip {
    @apply -top-[49px] -ml-3 w-6;
  }
}

.size-normal {
  @apply h-14 w-14 text-2xl leading-[5rem];

  .vip {
    @apply -top-[49px] -ml-6 w-12;
  }
}

.size-large {
  @apply h-20 w-20 text-4xl leading-[5rem];

  .vip {
    @apply -top-[51px] -ml-8 w-16;
  }
}

.size-xl {
  @apply h-36 w-36 text-6xl leading-[5rem];

  .vip {
    @apply -top-[55px] -ml-12 w-24;
  }
}
</style>
