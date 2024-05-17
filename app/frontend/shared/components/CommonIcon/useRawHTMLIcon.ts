// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'

import { usePrivateIcon } from './usePrivateIcon.ts'

import type { Props } from './CommonIcon.vue'

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
