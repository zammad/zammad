// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { computed } from 'vue'
import type { Props } from './CommonIcon.vue'
import type { Animations, Sizes } from './types'

export const usePrivateIcon = (
  props: Omit<Props, 'size'> & { size: Sizes },
) => {
  const animationClassMap: Record<Animations, string> = {
    pulse: 'animate-pulse',
    spin: 'animate-spin',
    ping: 'animate-ping',
    bounce: 'animate-bounce',
  }

  const sizeMap: Record<Sizes, number> = {
    xs: 12,
    tiny: 16,
    small: 20,
    base: 24,
    medium: 32,
    large: 48,
    xl: 96,
  }

  const iconClass = computed(() => {
    let className = `icon-${props.name}`
    if (props.animation) {
      className += ` ${animationClassMap[props.animation]}`
    }
    return className
  })

  const finalSize = computed(() => {
    if (props.fixedSize) return props.fixedSize

    return {
      width: sizeMap[props.size],
      height: sizeMap[props.size],
    }
  })

  return {
    iconClass,
    finalSize,
  }
}

export const useRawHTMLIcon = (props: Props & { class?: string }) => {
  const { iconClass, finalSize } = usePrivateIcon({ size: 'medium', ...props })
  const html = String.raw

  return html`
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="icon ${iconClass.value} ${props.class || ''} fill-current"
      width="${finalSize.value.width}"
      height="${finalSize.value.height}"
      ${!props.decorative &&
      `aria-label=${i18n.t(props.label || props.name) || ''}`}
      ${(props.decorative && 'aria-hidden="true"') || ''}
    >
      <use href="#icon-${props.name}" />
    </svg>
  `
}
