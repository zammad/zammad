<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside } from '@vueuse/core'
import {
  computed,
  defineAsyncComponent,
  ref,
  useSlots,
  type ComponentPublicInstance,
} from 'vue'

import {
  setCursorAtTextEnd,
  setPastedTextToCurrentSelection,
} from '#shared/utils/browser.ts'

const CommonButton = defineAsyncComponent(
  () => import('#desktop/components/CommonButton/CommonButton.vue'),
)

export interface Props {
  name: string
  value: string
  disabled?: boolean
  required?: boolean
  validationVisibility?: 'live' | 'lazy'
  submitLabel?: string
  cancelLabel?: string
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  validationVisibility: 'live',
})

const emit = defineEmits<{
  'submit-edit': [string]
  'cancel-edit': []
}>()

const target = ref<HTMLElement>()

const isValid = ref(false) // default user made no changes

const isEditing = defineModel<boolean>('editing', {
  default: false,
})

const editableComponent = ref<ComponentPublicInstance | HTMLElement>()

const activeEditingMode = computed(() => {
  return !props.disabled && isEditing.value
})

const baseFocusClasses =
  'rounded-md focus-within:outline-1 focus-within:outline-offset-1  focus-within:outline-blue-600 focus-within:dark:outline-blue-900 outline-none hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:hover:outline focus:hover:outline-1 focus:hover:outline-offset-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:hover:outline-blue-900'

const baseNonEditClasses = computed(() => ({
  [baseFocusClasses]: !isEditing.value && !props.disabled,
}))

const disabledClasses = computed(() => ({
  'cursor-text': props.disabled,
}))

const editedContent = computed(() => {
  if (editableComponent.value instanceof HTMLElement) {
    return editableComponent.value.textContent?.trim()
  }

  return editableComponent.value?.$el.textContent?.trim() || ''
})

const stopEditing = (emitCancel = true) => {
  isEditing.value = false
  if (emitCancel) emit('cancel-edit')
}

const activateEditing = () => {
  if (isEditing.value) return
  isEditing.value = true
}

const checkValidity = (edit: string) => {
  if (props.value === edit) {
    isValid.value = false
  } else if (props.required) {
    isValid.value = edit.length >= 1
  } else {
    isValid.value = true
  }

  return isValid.value
}

const submitEdit = () => {
  if (!checkValidity(editedContent.value)) return // :TODO rethink validation

  emit('submit-edit', editedContent.value)
  stopEditing(false)
}

onClickOutside(target, () => stopEditing())

const slots = useSlots()

const vFocus = (el: HTMLElement) => {
  el.focus()
  setCursorAtTextEnd(el)
}

const component = computed(() => {
  const vNode = slots.default?.()

  if (!vNode) return null

  if (vNode.length > 1)
    console.warn('CommonInlineEdit component works only with one root node')

  return vNode[0]
})

const handleEditInput = ({ target }: InputEvent) => {
  if (props.validationVisibility === 'live') {
    const newEdit = (target as HTMLElement).textContent?.trim()
    isValid.value = checkValidity(newEdit!)
  } else {
    isValid.value = true
  }
}
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions-->
  <div
    ref="target"
    :role="activeEditingMode ? undefined : 'button'"
    class="-:w-fit flex items-center gap-1"
    :class="[baseNonEditClasses, disabledClasses]"
    :aria-disabled="disabled"
    :tabindex="activeEditingMode ? undefined : 0"
    @click.capture="activateEditing"
    @keydown.enter.capture="activateEditing"
  >
    <div v-show="!isEditing" class="flex gap-1">
      <slot />
    </div>
    <div
      v-if="isEditing"
      class="flex items-center gap-2 rounded-md bg-blue-200 px-1.5 py-1 dark:bg-gray-700"
      :class="baseFocusClasses"
    >
      <div class="relative flex max-h-[4ch] overflow-y-auto">
        <component
          :is="component"
          key="editable-content-key"
          ref="editableComponent"
          v-focus
          :aria-label="label"
          tabindex="0"
          class="line-clamp-none max-w-full outline-none"
          role="textbox"
          contenteditable="true"
          @input="handleEditInput"
          @paste.prevent="setPastedTextToCurrentSelection"
          @keydown.enter.prevent="submitEdit"
          @keydown.esc="stopEditing"
        />
      </div>

      <Transition name="fade-up" appear>
        <div class="flex gap-1 rtl:-order-1">
          <CommonButton
            icon="x-lg"
            :aria-label="cancelLabel"
            variant="danger"
            @click="stopEditing"
          />
          <CommonButton
            class="rtl:-order-1"
            icon="check2"
            :aria-label="submitLabel"
            :disabled="!isValid"
            variant="submit"
            @click="submitEdit"
          />
        </div>
      </Transition>
    </div>
  </div>
</template>
