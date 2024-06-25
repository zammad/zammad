<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

interface Props {
  title: string
  icon: string
  entity?: ObjectLike
  actions?: MenuItem[]
}

defineProps<Props>()
</script>

<template>
  <div class="flex w-full gap-2 p-3">
    <CommonLabel
      tag="h2"
      class="grow"
      size="large"
      :prefix-icon="icon"
      icon-color="text-stone-200 dark:text-neutral-500"
    >
      {{ $t(title) }}
    </CommonLabel>

    <CommonActionMenu
      v-if="actions"
      class="text-gray-100 dark:text-neutral-400"
      no-single-action-mode
      placement="arrowEnd"
      :entity="entity"
      :actions="actions"
    />
  </div>

  <div class="flex flex-col gap-3 p-3">
    <slot></slot>
  </div>
</template>
