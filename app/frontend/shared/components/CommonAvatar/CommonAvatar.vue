<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { getAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'

import { nextSmallerAvatarSize } from './types.ts'

import type { AvatarSize } from './types.ts'

export interface Props {
  initials?: string
  // path to image
  image?: Maybe<string>
  // name of the icon
  icon?: Maybe<string>
  size?: AvatarSize
  // When `true`, `size` applies from the @5xl container breakpoint upwards and
  // the avatar (including its icon, vip badge and text) scales down to the next
  // smaller size below it.
  responsive?: boolean
  vipIcon?: Maybe<'vip-user' | 'vip-organization'>
  ariaLabel?: Maybe<string>
  decorative?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  initials: '??',
})

// Size the avatar renders at below the @5xl breakpoint. The larger `size` is
// restored at @5xl through the `size-5xl-*` container-query classes below.
const baseSize = computed(() => (props.responsive ? nextSmallerAvatarSize[props.size] : props.size))

const sizeClasses = computed(() =>
  props.responsive ? [`size-${baseSize.value}`, `size-5xl-${props.size}`] : `size-${props.size}`,
)

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
  return iconSizes[baseSize.value]
})

const avatarLabel = computed(() => {
  if (props.decorative) return undefined
  return props.ariaLabel || i18n.t('Avatar with initials %s', props.initials)
})

const classMap = getAvatarClasses()
</script>

<template>
  <span
    class="relative flex shrink-0 items-center justify-center rounded-full bg-cover bg-center select-none print:before:content-[attr(data-initials)]"
    :class="[sizeClasses, classMap.base]"
    :style="{
      backgroundImage: image ? `url(${image})` : undefined,
      backgroundRepeat: image ? 'no-repeat' : undefined,
    }"
    role="img"
    :aria-label="avatarLabel"
    :aria-hidden="decorative ? 'true' : undefined"
    data-test-id="common-avatar"
    :data-initials="icon ? undefined : initials"
  >
    <CommonIcon
      v-if="vipIcon"
      class="vip pointer-events-none absolute"
      :class="vipIcon === 'vip-organization' ? classMap.vipOrganization : classMap.vipUser"
      :name="vipIcon"
      :size="iconSizes[baseSize]"
      decorative
    />
    <CommonIcon v-if="icon" :name="icon" :size="iconSize" />
    <slot v-else>
      <span class="print:hidden">
        {{ image ? '' : initials }}
      </span>
    </slot>
  </span>
</template>

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

/*
 * Responsive overrides: when the `responsive` prop is set the avatar renders at
 * the next smaller `size-*` below the @5xl container breakpoint, and is scaled
 * back up to its target size from @6xl upwards. The icon is sized via the svg's
 * width/height attributes, so it is matched here through CSS as well.
 */
@container (min-width: 64rem) {
  .size-5xl-xs {
    height: 1.5rem;
    width: 1.5rem;
    font-size: 0.75rem;
    line-height: 1.5rem;
  }

  .size-5xl-xs .vip {
    transform: translateY(-0.75rem);
  }

  .size-5xl-xs .icon {
    width: 0.75rem;
    height: 0.75rem;
  }

  .size-5xl-small {
    height: 2rem;
    width: 2rem;
    font-size: 0.75rem;
    line-height: 2rem;
  }

  .size-5xl-small .vip {
    transform: translateY(-1rem);
  }

  .size-5xl-small .icon {
    width: 1.25rem;
    height: 1.25rem;
  }

  .size-5xl-medium {
    height: 2.5rem;
    width: 2.5rem;
    font-size: 1rem;
    line-height: 2.5rem;
  }

  .size-5xl-medium .vip {
    transform: translateY(-1.25rem);
  }

  .size-5xl-medium .icon {
    width: 1.5rem;
    height: 1.5rem;
  }

  .size-5xl-normal {
    height: 3.5rem;
    width: 3.5rem;
    font-size: 1.5rem;
    line-height: 5rem;
  }

  .size-5xl-normal .vip {
    transform: translateY(-1.85rem);
  }

  .size-5xl-normal .icon {
    width: 2rem;
    height: 2rem;
  }

  .size-5xl-large {
    height: 5rem;
    width: 5rem;
    font-size: 2.25rem;
    line-height: 5rem;
  }

  .size-5xl-large .vip {
    transform: translateY(-2.65rem);
  }

  .size-5xl-large .icon {
    width: 3rem;
    height: 3rem;
  }

  .size-5xl-xl {
    height: 9rem;
    width: 9rem;
    font-size: 3.75rem;
    line-height: 5rem;
  }

  .size-5xl-xl .vip {
    transform: translateY(-4.85rem);
  }

  .size-5xl-xl .icon {
    width: 6rem;
    height: 6rem;
  }
}
</style>
