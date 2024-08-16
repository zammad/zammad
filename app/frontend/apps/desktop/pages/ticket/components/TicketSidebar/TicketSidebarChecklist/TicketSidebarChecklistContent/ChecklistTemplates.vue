<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

interface Props {
  templates: MenuItem[]
}

defineProps<Props>()

const { popover, popoverTarget, toggle } = usePopover()
</script>

<template>
  <CommonLabel class="mx-auto text-center" tag="p">
    {{ $t('Or choose a checklist template.') }}
  </CommonLabel>

  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    placement="end"
    orientation="autoVertical"
  >
    <CommonPopoverMenu :popover="popover" :items="templates" />
  </CommonPopover>

  <CommonButton
    ref="popoverTarget"
    class="mx-auto"
    size="medium"
    suffix-icon="chevron-down"
    variant="secondary"
    @click="toggle(true)"
  >
    {{ $t('Add From a Template') }}
  </CommonButton>
</template>
