<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import type { Props as CommonPopoverProps } from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'

import CommonButton from '../CommonButton/CommonButton.vue'

import type { Props as CommonButtonProps } from '../CommonButton/CommonButton.vue'
import type { Props as CommonPopoverMenuProps } from '../CommonPopoverMenu/CommonPopoverMenu.vue'

export interface Props
  extends CommonButtonProps,
    Pick<CommonPopoverProps, 'orientation' | 'placement'>,
    Pick<CommonPopoverMenuProps, 'items'> {
  addonDisabled?: boolean
  addonLabel?: string
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'top',
  placement: 'end',
})

defineOptions({
  inheritAttrs: false,
})

const addonPaddingClasses = computed(() => {
  switch (props.size) {
    case 'large':
      return ['px-2!', 'py-3']
    case 'medium':
      return ['px-1.5!', 'py-2.5']
    case 'small':
    default:
      return ['px-1!', 'py-2']
  }
})

const addonIconSize = computed(() => {
  switch (props.size) {
    case 'large':
      return 'small'
    case 'medium':
      return 'tiny'
    case 'small':
    default:
      return 'xs'
  }
})

const { popover, popoverTarget, isOpen: popoverIsOpen, toggle } = usePopover()
</script>

<template>
  <div class="inline-flex gap-px" :class="{ 'w-full': block }">
    <CommonButton
      v-bind="{ ...props, ...$attrs }"
      class="rounded-e-none hover:z-10 focus-visible:z-10"
      :class="{
        grow: block,
      }"
      :block="false"
    >
      <slot />
    </CommonButton>
    <CommonButton
      ref="popoverTarget"
      v-bind="props"
      class="rounded-s-none"
      :class="[
        addonPaddingClasses,
        {
          'outline-1! outline-offset-1 outline-blue-800!': popoverIsOpen,
        },
      ]"
      :disabled="addonDisabled"
      :block="false"
      type="button"
      :aria-label="$t(addonLabel || __('Context menu'))"
      @click="toggle(true)"
    >
      <CommonIcon
        class="pointer-events-none block shrink-0"
        decorative
        :size="addonIconSize"
        name="chevron-up"
      />
    </CommonButton>
  </div>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    :orientation="orientation"
    :placement="placement"
    hide-arrow
  >
    <slot name="popover-content">
      <CommonPopoverMenu :popover="popover" :items="items" />
    </slot>
  </CommonPopover>
</template>
