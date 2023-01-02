<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { i18n } from '@shared/i18n'
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
  ariaLabel?: Maybe<string>
  decorative?: boolean
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

const avatarLabel = computed(() => {
  if (props.decorative) return undefined
  return props.ariaLabel || i18n.t('Avatar with initials %s', props.initials)
})
</script>

<template>
  <span
    :style="{
      backgroundImage: image ? `url(${image})` : undefined,
      backgroundRepeat: image ? 'no-repeat' : undefined,
    }"
    :class="[
      'relative inline-flex h-10 w-10 shrink-0 select-none text-black',
      'items-center justify-center rounded-full bg-cover bg-center',
      `size-${size}`,
    ]"
    role="img"
    :aria-label="avatarLabel"
    :aria-hidden="decorative ? 'true' : undefined"
    data-test-id="common-avatar"
  >
    <CommonIcon
      v-if="vip"
      size="xl"
      class="vip absolute left-1/2 -top-[48px] -ml-5 w-10 text-yellow"
      name="mobile-crown"
      decorative
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
