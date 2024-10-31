<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { getAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'

import type { AvatarSize } from './types.ts'

export interface Props {
  initials?: string
  // path to image
  image?: Maybe<string>
  // name of the icon
  icon?: Maybe<string>
  size?: AvatarSize
  vipIcon?: Maybe<'vip-user' | 'vip-organization'>
  ariaLabel?: Maybe<string>
  decorative?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  initials: '??',
})

const iconSizes = {
  xs: 'xs',
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

const classMap = getAvatarClasses()
</script>

<template>
  <span
    class="relative flex shrink-0 select-none items-center justify-center rounded-full bg-cover bg-center"
    :class="[`size-${size}`, classMap.base]"
    :style="{
      backgroundImage: image ? `url(${image})` : undefined,
      backgroundRepeat: image ? 'no-repeat' : undefined,
    }"
    role="img"
    :aria-label="avatarLabel"
    :aria-hidden="decorative ? 'true' : undefined"
    data-test-id="common-avatar"
  >
    <CommonIcon
      v-if="vipIcon"
      class="vip pointer-events-none absolute"
      :class="
        vipIcon === 'vip-organization'
          ? classMap.vipOrganization
          : classMap.vipUser
      "
      :name="vipIcon"
      :size="iconSizes[props.size]"
      decorative
    />
    <CommonIcon v-if="icon" :name="icon" :size="iconSize" />
    <slot v-else>
      {{ image ? '' : initials }}
    </slot>
  </span>
</template>

<style scoped>
.size-xs {
  @apply h-6 w-6 text-xs leading-6;

  .vip {
    @apply -translate-y-3;
  }
}

.size-small {
  @apply h-8 w-8 text-xs leading-8;

  .vip {
    @apply -translate-y-4;
  }
}

.size-medium {
  @apply h-10 w-10 text-base leading-10;

  .vip {
    @apply -translate-y-5;
  }
}

.size-normal {
  @apply h-14 w-14 text-2xl leading-[5rem];

  .vip {
    @apply -translate-y-[1.85rem];
  }
}

.size-large {
  @apply h-20 w-20 text-4xl leading-[5rem];

  .vip {
    @apply -translate-y-[2.65rem];
  }
}

.size-xl {
  @apply h-36 w-36 text-6xl leading-[5rem];

  .vip {
    @apply -translate-y-[4.85rem];
  }
}
</style>
