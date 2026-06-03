<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import type { Props as CommonPopoverProps } from '#desktop/components/CommonPopover/CommonPopover.vue'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'

import CommonButton from '../CommonButton/CommonButton.vue'

import type { Props as CommonButtonProps } from '../CommonButton/CommonButton.vue'
import type { Props as CommonPopoverMenuProps } from '../CommonPopoverMenu/CommonPopoverMenu.vue'

export interface Props
  extends
    CommonButtonProps,
    Pick<CommonPopoverProps, 'orientation' | 'placement'>,
    Pick<CommonPopoverMenuProps, 'items'> {
  addonDisabled?: boolean
  addonLabel?: string
  /**
   * User it depending where the popover is shown
   * Popover on top of target -> caret should point up
   * Popover on bottom of target -> caret should point down
   */
  caretPointer?: 'up' | 'down'
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'top',
  placement: 'end',
  caretPointer: 'up',
})

defineOptions({
  inheritAttrs: false,
})

// A11y - Id is required for CommonPopover to link popover to target
const targetId = getUuid()

const addonPaddingClasses = computed(() => {
  switch (props.size) {
    case 'large':
      return ['px-2.5!', 'py-3']
    case 'medium':
      return ['px-2!', 'py-2.5']
    case 'small':
    default:
      return ['p-2!']
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

const variantWrapperClass = computed(() => {
  // tertiary-light has a border which acts as a divider
  if (props.variant === 'tertiary-light') return ''

  return 'gap-px'
})

const firstButtonClasses = computed(() => {
  if (props.variant === 'tertiary-light') return ['border-r-0!']

  return ''
})

// TODO: we should fix v-bind="props", because not everything is supported by the buttons component and
// it will also duplicate some labels?
const { popover, popoverTarget, isOpen: popoverIsOpen, toggle, close } = usePopover()
</script>

<template>
  <div class="inline-flex" :class="[variantWrapperClass, { 'w-full': block }]">
    <CommonButton
      v-bind="{ ...props, ...$attrs }"
      class="rounded-e-none -outline-offset-1! hover:z-10 focus-visible:z-10"
      :class="[
        firstButtonClasses,
        {
          grow: block,
        },
      ]"
      :block="false"
    >
      <slot />
    </CommonButton>
    <CommonButton
      v-bind="props"
      :id="targetId"
      ref="popoverTarget"
      v-tooltip="$t(addonLabel || __('Context menu'))"
      class="rounded-s-none -outline-offset-1!"
      :class="[
        addonPaddingClasses,
        {
          'outline-1! outline-blue-800!': popoverIsOpen,
        },
      ]"
      :disabled="addonDisabled"
      :block="false"
      type="button"
      :aria-expanded="popoverIsOpen"
      @click="toggle(true)"
    >
      <CommonIcon
        class="pointer-events-none block shrink-0"
        decorative
        :size="addonIconSize"
        :name="caretPointer === 'down' ? 'chevron-down' : 'chevron-up'"
      />
    </CommonButton>
  </div>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    :orientation="orientation"
    :placement="placement"
  >
    <slot name="popover-content" :popover="popover" :close="close">
      <CommonPopoverMenu :popover="popover" :items="items" />
    </slot>
  </CommonPopover>
</template>
