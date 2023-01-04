<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { SelectOption } from '@shared/components/Form/fields/FieldSelect/types'
import { useFocusWhenTyping } from '@shared/composables/useFocusWhenTyping'
import { useTrapTab } from '@shared/composables/useTrapTab'
import { useTraverseOptions } from '@shared/composables/useTraverseOptions'
import stopEvent from '@shared/utils/events'
import { onClickOutside, onKeyDown, useVModel } from '@vueuse/core'
import type { Ref } from 'vue'
import { computed, nextTick, ref } from 'vue'
import testFlags from '@shared/utils/testFlags'
import CommonSelectItem from './CommonSelectItem.vue'

export interface Props {
  // we cannot move types into separate file, because Vue would not be able to
  // transform these into runtime types
  modelValue?: string | number | boolean | (string | number | boolean)[] | null
  options: SelectOption[]
  /**
   * Do not modify local value
   */
  passive?: boolean
  multiple?: boolean
  noClose?: boolean
  noRefocus?: boolean
  noOptionsLabelTranslation?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:modelValue', option: string | number | (string | number)[]): void
  (e: 'select', option: SelectOption): void
  (e: 'close'): void
}>()

const dialogElement = ref<HTMLElement>()
const localValue = useVModel(props, 'modelValue', emit)

// TODO: do we really want this initial transfomring of the value, when it's null?
if (localValue.value == null && props.multiple) {
  localValue.value = []
}

const getFocusableOptions = () => {
  return Array.from<HTMLElement>(
    dialogElement.value?.querySelectorAll('[tabindex="0"]') || [],
  )
}

const showDialog = ref(false)
let lastFocusableOutsideElement: HTMLElement | null = null

const openDialog = () => {
  showDialog.value = true
  lastFocusableOutsideElement = document.activeElement as HTMLElement
  requestAnimationFrame(() => {
    // https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/listbox_role#keyboard_interactions
    // focus selected or first available option
    const focusableElements = getFocusableOptions()
    const selected = focusableElements.find(
      (el) => el.getAttribute('aria-selected') === 'true',
    )
    const focusElement = selected || focusableElements[0]
    focusElement?.focus()

    nextTick(() => {
      testFlags.set('common-select.opened')
    })
  })
}

const closeDialog = () => {
  showDialog.value = false
  emit('close')
  if (!props.noRefocus) {
    nextTick(() => lastFocusableOutsideElement?.focus())
  }

  nextTick(() => {
    testFlags.set('common-select.closed')
  })
}

defineExpose({
  isOpen: computed(() => showDialog.value),
  openDialog,
  closeDialog,
  getFocusableOptions,
})

useTrapTab(dialogElement)

// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/listbox_role#keyboard_interactions
useTraverseOptions(dialogElement, { direction: 'vertical' })

// - Type-ahead is recommended for all listboxes, especially those with more than seven options
useFocusWhenTyping(dialogElement)

onClickOutside(dialogElement, closeDialog)
onKeyDown(
  'Escape',
  (event) => {
    stopEvent(event)
    closeDialog()
  },
  { target: dialogElement as Ref<EventTarget> },
)

const isCurrentValue = (value: string | number | boolean) => {
  if (props.multiple && Array.isArray(localValue.value)) {
    return localValue.value.includes(value)
  }

  return localValue.value === value
}

const select = (option: SelectOption) => {
  if (option.disabled) return

  emit('select', option)

  if (props.passive) {
    if (!props.multiple) {
      closeDialog()
    }
    return
  }

  if (props.multiple && Array.isArray(localValue.value)) {
    if (localValue.value.includes(option.value)) {
      localValue.value = localValue.value.filter((v) => v !== option.value)
    } else {
      localValue.value.push(option.value)
    }

    return
  }

  if (props.modelValue === option.value) {
    localValue.value = undefined
  } else {
    localValue.value = option.value
  }

  if (!props.multiple && !props.noClose) {
    closeDialog()
  }
}

const duration = VITE_TEST_MODE ? undefined : { enter: 300, leave: 200 }
</script>

<template>
  <slot :open="openDialog" :close="closeDialog" />
  <Teleport to="body">
    <Transition :duration="duration">
      <div
        v-if="showDialog"
        id="common-select"
        class="fixed inset-0 z-10 flex overflow-y-auto"
        :aria-label="$t('Dialog window with selections')"
        role="dialog"
      >
        <div
          class="select-overlay fixed inset-0 flex h-full w-full bg-gray-500 opacity-60"
          data-test-id="dialog-overlay"
        ></div>
        <div class="select-dialog relative m-auto">
          <div
            class="flex min-w-[294px] max-w-[90vw] flex-col items-start rounded-xl bg-gray-400/80 backdrop-blur-[15px]"
          >
            <div
              ref="dialogElement"
              :aria-label="$t('Select…')"
              role="listbox"
              :aria-multiselectable="multiple"
              class="max-h-[50vh] w-full divide-y divide-solid divide-white/10 overflow-y-auto"
            >
              <CommonSelectItem
                v-for="option in options"
                :key="String(option.value)"
                :selected="isCurrentValue(option.value)"
                :multiple="multiple"
                :option="option"
                :no-label-translate="noOptionsLabelTranslation"
                @select="select($event)"
              />
              <slot name="footer" />
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped lang="scss">
.v-enter-active {
  .select-overlay,
  .select-dialog {
    @apply duration-300 ease-out;
  }
}

.v-leave-active {
  .select-overlay,
  .select-dialog {
    @apply duration-200 ease-in;
  }
}

.v-enter-to,
.v-leave-from {
  .select-dialog {
    @apply scale-100 opacity-100;
  }

  .select-overlay {
    @apply opacity-60;
  }
}

.v-enter-from,
.v-leave-to {
  .select-dialog {
    @apply scale-95 opacity-0;
  }

  .select-overlay {
    @apply opacity-0;
  }
}
</style>
