<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { usePrivateIcon } from '#shared/components/CommonIcon/usePrivateIcon.ts'

import type { KnowledgeBaseIconSet } from '../types.ts'

export interface Props {
  name: string
  set: KnowledgeBaseIconSet
  size?: Sizes
  fixedSize?: { width: number; height: number }
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const { iconClass, finalSize } = usePrivateIcon(props)
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    class="icon fill-current"
    :class="iconClass"
    :width="finalSize.width"
    :height="finalSize.height"
    aria-hidden="true"
  >
    <use :href="`/assets/icon-fonts/${props.set}.svg#icon-${props.name}`" />
  </svg>
</template>
