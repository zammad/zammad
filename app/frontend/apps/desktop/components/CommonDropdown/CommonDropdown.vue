<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import CommonPopoverMenuItem from '#desktop/components/CommonPopoverMenu/CommonPopoverMenuItem.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

interface Props {
  items: MenuItem[]
  orientation?: 'top' | 'bottom'
  /**
   * Will apply on the button label if v-model is not bound
   * */
  actionLabel?: string
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'bottom',
})

const emit = defineEmits<{
  'handle-action': [DropdownItem]
}>()

const { popover, popoverTarget, isOpen, toggle } = usePopover()

const locale = useLocaleStore()

const currentPopoverPlacement = computed(() => {
  if (locale.localeData?.dir === EnumTextDirection.Rtl) return 'start'
  return 'end'
})

/**
 * MenuItem transformed into a radio button model
 * */
const modelValue = defineModel<DropdownItem>()

const dropdownLabel = computed(() =>
  modelValue.value ? i18n.t(modelValue.value?.label) : props.actionLabel,
)

const handleSelectRadio = (item: DropdownItem) => {
  modelValue.value = item
  toggle()
}

const router = useRouter()

const actionItems = computed(() =>
  // oxlint-disable no-map-spread
  props.items.map((item) => ({
    ...item,
    // We can't use the original object, since it would overwrite the memory reference to the prop as well
    onClick: () => {
      emit('handle-action', item)
      item.onClick?.(item, router)
    },
  })),
)
</script>

<template>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    :placement="currentPopoverPlacement"
    :orientation="orientation"
  >
    <CommonPopoverMenu v-if="modelValue" :popover="popover" :items="items">
      <template v-for="(item, index) in items" :key="item.key" #[`item-${item.key}`]>
        <div class="group flex grow cursor-pointer items-center">
          <CommonPopoverMenuItem
            class="flex grow items-center gap-2 p-2.5 focus-visible-app-default focus-visible:-outline-offset-1!"
            :class="{
              'rounded-t-lg!': index === 0,
              'rounded-b-lg!': index === items?.length - 1,
            }"
            :label="item.label"
            :variant="item.variant"
            :link="item.link"
            :icon="item.icon"
            :label-placeholder="item.labelPlaceholder"
            role="checkbox"
            :aria-checked="modelValue.key === item.key"
            @click="handleSelectRadio(item)"
          >
            <template #leading>
              <CommonIcon
                :class="{ 'opacity-0': modelValue.key !== item.key }"
                size="tiny"
                name="check2"
              />
            </template>
          </CommonPopoverMenuItem>
        </div>
      </template>
    </CommonPopoverMenu>
    <CommonPopoverMenu v-else :popover="popover" :items="actionItems" />
  </CommonPopover>

  <CommonButton
    v-bind="$attrs"
    ref="popoverTarget"
    class="group"
    :class="{
      'hover:bg-blue-600! hover:text-black dark:hover:bg-blue-900! dark:hover:text-white': !isOpen,
      'bg-blue-800! text-white! outline! outline-offset-1! outline-blue-800! hover:bg-blue-800!':
        isOpen,
    }"
    size="large"
    variant="secondary"
    @click="toggle"
  >
    <template #label>
      <span class="truncate">
        {{ dropdownLabel }}
      </span>
      <CommonIcon
        size="small"
        decorative
        class="pointer-events-none shrink-0 text-stone-200 dark:text-neutral-500 dark:group-hover:text-white"
        :class="{
          'text-white dark:text-white': isOpen,
          'group-hover:text-black dark:group-hover:text-white': !isOpen,
        }"
        name="chevron-up"
      />
    </template>
  </CommonButton>
</template>
