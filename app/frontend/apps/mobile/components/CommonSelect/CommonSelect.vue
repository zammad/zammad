<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { SelectOption } from '@shared/components/Form/fields/FieldSelect/types'
import { onClickOutside, onKeyDown, useVModel } from '@vueuse/core'
import { ref } from 'vue'
import CommonSelectItem from './CommonSelectItem.vue'

export interface Props {
  modelValue?: string | number | (string | number)[]
  options: SelectOption[]
  /**
   * Do not modify local value
   */
  passive?: boolean
  multiple?: boolean
  noClose?: boolean
  noOptionsLabelTranslation?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:modelValue', option: string | number | (string | number)[]): void
  (e: 'select', option: SelectOption): void
}>()

const dialogElement = ref<HTMLElement>()
const localValue = useVModel(props, 'modelValue', emit)

if (localValue.value == null && props.multiple) {
  localValue.value = []
}

const showDialog = ref(false)

const openDialog = () => {
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
}

defineExpose({
  openDialog,
  closeDialog,
})

onClickOutside(dialogElement, closeDialog)
onKeyDown('Escape', closeDialog)

const isCurrentValue = (value: string | number) => {
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

const getElementUp = (currentIndex: number, elements: HTMLElement[]) => {
  if (currentIndex === 0) {
    return elements[elements.length - 1]
  }
  return elements[currentIndex - 1]
}

const getElementDown = (currentIndex: number, elements: HTMLElement[]) => {
  if (currentIndex === elements.length - 1) {
    return elements[0]
  }
  return elements[currentIndex + 1]
}

const advanceDialogFocus = (event: KeyboardEvent, currentIndex: number) => {
  if (!['ArrowUp', 'ArrowDown'].includes(event.key)) return

  const focusableElements: HTMLElement[] = Array.from(
    dialogElement.value?.querySelectorAll('[tabindex="0"]') || [],
  )
  const nextElement =
    event.key === 'ArrowUp'
      ? getElementUp(currentIndex, focusableElements)
      : getElementDown(currentIndex, focusableElements)

  nextElement?.focus()
}
</script>

<template>
  <slot :open="openDialog" :close="closeDialog" />
  <Transition :duration="{ enter: 300, leave: 200 }">
    <div
      v-if="showDialog"
      class="fixed inset-0 z-10 flex overflow-y-auto"
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
            role="listbox"
            class="max-h-[50vh] w-full divide-y divide-solid divide-white/10 overflow-y-auto"
          >
            <CommonSelectItem
              v-for="(option, index) in options"
              :key="option.value"
              :selected="isCurrentValue(option.value)"
              :multiple="multiple"
              :option="option"
              :no-label-translate="noOptionsLabelTranslation"
              @select="select($event)"
              @keydown="advanceDialogFocus($event, index)"
            />
            <slot name="footer" />
          </div>
        </div>
      </div>
    </div>
  </Transition>
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
