<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
    class="relative flex shrink-0 items-center justify-center rounded-full bg-cover bg-center select-none"
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

Sure, here is the refactored style using native CSS: ```css
<style scoped>
.size-xs {
  height: 1.5rem;
  width: 1.5rem;
  font-size: 0.75rem;
  line-height: 1.5rem;
}

.size-xs .vip {
  transform: translateY(-0.75rem);
}

.size-small {
  height: 2rem;
  width: 2rem;
  font-size: 0.75rem;
  line-height: 2rem;
}

.size-small .vip {
  transform: translateY(-1rem);
}

.size-medium {
  height: 2.5rem;
  width: 2.5rem;
  font-size: 1rem;
  line-height: 2.5rem;
}

.size-medium .vip {
  transform: translateY(-1.25rem);
}

.size-normal {
  height: 3.5rem;
  width: 3.5rem;
  font-size: 1.5rem;
  line-height: 5rem;
}

.size-normal .vip {
  transform: translateY(-1.85rem);
}

.size-large {
  height: 5rem;
  width: 5rem;
  font-size: 2.25rem;
  line-height: 5rem;
}

.size-large .vip {
  transform: translateY(-2.65rem);
}

.size-xl {
  height: 9rem;
  width: 9rem;
  font-size: 3.75rem;
  line-height: 5rem;
}

.size-xl .vip {
  transform: translateY(-4.85rem);
}
</style>
```
