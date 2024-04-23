<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  computed,
  type ConcreteComponent,
  nextTick,
  onUnmounted,
  ref,
  type Ref,
  toRef,
} from 'vue'
import { useFocusWhenTyping } from '#shared/composables/useFocusWhenTyping.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import stopEvent from '#shared/utils/events.ts'
import {
  type UseElementBoundingReturn,
  onClickOutside,
  onKeyDown,
  useVModel,
} from '@vueuse/core'
import type {
  MatchedSelectOption,
  SelectOption,
  SelectValue,
} from '#shared/components/CommonSelect/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import testFlags from '#shared/utils/testFlags.ts'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { i18n } from '#shared/i18n.ts'
import CommonSelectItem from './CommonSelectItem.vue'
import { useCommonSelect } from './useCommonSelect.ts'
import type { CommonSelectInternalInstance } from './types.ts'

export interface Props {
  modelValue?:
    | SelectValue
    | SelectValue[]
    | { value: SelectValue; label: string }
    | null
  options: AutoCompleteOption[] | SelectOption[]
  /**
   * Do not modify local value
   */
  passive?: boolean
  multiple?: boolean
  noClose?: boolean
  noRefocus?: boolean
  owner?: string
  noOptionsLabelTranslation?: boolean
  filter?: string
  optionIconComponent?: ConcreteComponent
  initiallyEmpty?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [option: string | number | (string | number)[]]
  select: [option: SelectOption]
  close: []
}>()

const dropdownElement = ref<HTMLElement>()
const localValue = useVModel(props, 'modelValue', emit)

// TODO: do we really want this initial transforming of the value, when it's null?
if (localValue.value == null && props.multiple) {
  localValue.value = []
}

const getFocusableOptions = () => {
  return Array.from<HTMLElement>(
    dropdownElement.value?.querySelectorAll('[tabindex="0"]') || [],
  )
}

const showDropdown = ref(false)

let inputElementBounds: UseElementBoundingReturn
let windowHeight: Ref<number>

const hasDirectionUp = computed(() => {
  if (!inputElementBounds || !windowHeight) return false
  return inputElementBounds.y.value > windowHeight.value / 2
})

const dropdownStyle = computed(() => {
  if (!inputElementBounds) return { top: 0, left: 0, width: 0, maxHeight: 0 }

  const style: Record<string, string> = {
    left: `${inputElementBounds.left.value}px`,
    width: `${inputElementBounds.width.value}px`,
    maxHeight: `calc(50vh - ${inputElementBounds.height.value}px)`,
  }

  if (hasDirectionUp.value) {
    style.bottom = `${windowHeight.value - inputElementBounds.top.value}px`
  } else {
    style.top = `${
      inputElementBounds.top.value + inputElementBounds.height.value
    }px`
  }

  return style
})

const { activateTabTrap, deactivateTabTrap } = useTrapTab(dropdownElement)

let lastFocusableOutsideElement: HTMLElement | null = null

const getActiveElement = () => {
  if (props.owner) {
    return document.getElementById(props.owner)
  }

  return document.activeElement as HTMLElement
}

const { instances } = useCommonSelect()

const closeDropdown = () => {
  deactivateTabTrap()
  showDropdown.value = false
  emit('close')

  // TODO: move to existing nextTick.
  if (!props.noRefocus) {
    nextTick(() => lastFocusableOutsideElement?.focus())
  }

  nextTick(() => {
    testFlags.set('common-select.closed')
  })
}

const openDropdown = (
  bounds: UseElementBoundingReturn,
  height: Ref<number>,
) => {
  inputElementBounds = bounds
  windowHeight = toRef(height)
  instances.value.forEach((instance) => {
    if (instance.isOpen.value) instance.closeDropdown()
  })
  showDropdown.value = true
  lastFocusableOutsideElement = getActiveElement()

  onClickOutside(dropdownElement, closeDropdown, {
    ignore: [lastFocusableOutsideElement as unknown as HTMLElement],
  })

  requestAnimationFrame(() => {
    nextTick(() => {
      testFlags.set('common-select.opened')
    })
  })
}

const moveFocusToDropdown = (lastOption = false) => {
  // Focus selected or first available option.
  //   https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/listbox_role#keyboard_interactions
  const focusableElements = getFocusableOptions()
  if (!focusableElements?.length) return

  let focusElement = focusableElements[0]

  if (lastOption) {
    focusElement = focusableElements[focusableElements.length - 1]
  } else {
    const selected = focusableElements.find(
      (el) => el.getAttribute('aria-selected') === 'true',
    )
    if (selected) focusElement = selected
  }

  focusElement?.focus()
  activateTabTrap()
}

const exposedInstance: CommonSelectInternalInstance = {
  isOpen: computed(() => showDropdown.value),
  openDropdown,
  closeDropdown,
  getFocusableOptions,
  moveFocusToDropdown,
}

instances.value.add(exposedInstance)

onUnmounted(() => {
  instances.value.delete(exposedInstance)
})

defineExpose(exposedInstance)

// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/listbox_role#keyboard_interactions
useTraverseOptions(dropdownElement, { direction: 'vertical' })

// - Type-ahead is recommended for all listboxes, especially those with more than seven options
useFocusWhenTyping(dropdownElement)

onKeyDown(
  'Escape',
  (event) => {
    stopEvent(event)
    closeDropdown()
  },
  { target: dropdownElement as Ref<EventTarget> },
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
      closeDropdown()
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
    closeDropdown()
  }
}

const hasMoreSelectableOptions = computed(
  () =>
    props.options.filter(
      (option) => !option.disabled && !isCurrentValue(option.value),
    ).length > 0,
)

const selectAll = () => {
  props.options
    .filter((option) => !option.disabled && !isCurrentValue(option.value))
    .forEach((option) => select(option))
}

const highlightedOptions = computed(() =>
  props.options.map((option) => {
    let label = option.label || i18n.t('%s (unknown)', option.value.toString())

    // Highlight the matched text within the option label by re-using passed regex match object.
    //   This approach has several benefits:
    //   - no repeated regex matching in order to identify matched text
    //   - support for matched text with accents, in case the search keyword didn't contain them (and vice-versa)
    if (option.match && option.match[0]) {
      const labelBeforeMatch = label.slice(0, option.match.index)

      // Do not use the matched text here, instead use part of the original label in the same length.
      //   This is because the original match does not include accented characters.
      const labelMatchedText = label.slice(
        option.match.index,
        option.match.index + option.match[0].length,
      )

      const labelAfterMatch = label.slice(
        option.match.index + option.match[0].length,
      )

      const highlightClasses = option.disabled
        ? 'bg-blue-200 dark:bg-gray-300'
        : 'bg-blue-600 dark:bg-blue-900 group-hover:bg-blue-800 group-hover:group-focus:bg-blue-600 dark:group-hover:group-focus:bg-blue-900 group-hover:text-white group-focus:text-black dark:group-focus:text-white group-hover:group-focus:text-black dark:group-hover:group-focus:text-white'

      label = `${labelBeforeMatch}<span class="${highlightClasses}">${labelMatchedText}</span>${labelAfterMatch}`
    }

    return {
      ...option,
      matchedLabel: label,
    } as MatchedSelectOption
  }),
)

const emptyLabelText = computed(() => {
  if (!props.initiallyEmpty) return __('No results found')
  return props.filter ? __('No results found') : __('Start typing to search…')
})

const duration = VITE_TEST_MODE ? undefined : { enter: 300, leave: 200 }
</script>

<template>
  <slot
    :state="showDropdown"
    :open="openDropdown"
    :close="closeDropdown"
    :focus="moveFocusToDropdown"
  />
  <Teleport to="body">
    <Transition :duration="duration">
      <div
        v-if="showDropdown"
        id="common-select"
        ref="dropdownElement"
        class="fixed z-10 flex min-h-9 antialiased"
        :style="dropdownStyle"
      >
        <div
          class="select-dialog w-full"
          role="menu"
          :class="{
            'select-dialog--up': hasDirectionUp,
            'select-dialog--down': !hasDirectionUp,
          }"
        >
          <div
            class="flex h-full flex-col items-start border-x border-neutral-100 bg-white dark:border-gray-900 dark:bg-gray-500"
            :class="{
              'rounded-t-lg border-t': hasDirectionUp,
              'rounded-b-lg border-b': !hasDirectionUp,
            }"
          >
            <div
              v-if="multiple && hasMoreSelectableOptions"
              class="flex w-full justify-between gap-2 px-2.5 py-1.5"
            >
              <CommonLabel
                class="ms-auto text-blue-800 focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-blue-800"
                prefix-icon="check-all"
                role="button"
                tabindex="0"
                @click.stop="selectAll()"
                @keypress.enter.prevent.stop="selectAll()"
                @keypress.space.prevent.stop="selectAll()"
              >
                {{ $t('select all options') }}
              </CommonLabel>
            </div>
            <div
              :aria-label="$t('Select…')"
              role="listbox"
              :aria-multiselectable="multiple"
              tabindex="-1"
              class="w-full overflow-y-auto"
            >
              <CommonSelectItem
                v-for="option in filter ? highlightedOptions : options"
                :key="String(option.value)"
                :class="{
                  'first:rounded-t-lg':
                    hasDirectionUp && (!multiple || !hasMoreSelectableOptions),
                  'last:rounded-b-lg': !hasDirectionUp,
                }"
                :selected="isCurrentValue(option.value)"
                :multiple="multiple"
                :option="option"
                :no-label-translate="noOptionsLabelTranslation"
                :filter="filter"
                :option-icon-component="optionIconComponent"
                @select="select($event)"
              />
              <CommonSelectItem
                v-if="!options.length"
                :option="{
                  label: emptyLabelText,
                  value: '',
                  disabled: true,
                }"
                no-selection-indicator
              />
              <slot name="footer" />
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.select-dialog {
  &--down {
    @apply origin-top;
  }

  &--up {
    @apply origin-bottom;
  }
}

.v-enter-active {
  .select-dialog {
    @apply duration-200 ease-out;
  }
}

.v-leave-active {
  .select-dialog {
    @apply duration-200 ease-in;
  }
}

.v-enter-to,
.v-leave-from {
  .select-dialog {
    @apply scale-y-100 opacity-100;
  }
}

.v-enter-from,
.v-leave-to {
  .select-dialog {
    @apply scale-y-50 opacity-0;
  }
}
</style>
