<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  type UseElementBoundingReturn,
  onClickOutside,
  onKeyDown,
  useVModel,
} from '@vueuse/core'
import {
  useTemplateRef,
  onUnmounted,
  computed,
  nextTick,
  ref,
  toRef,
} from 'vue'

import type {
  FlatSelectOption,
  MatchedFlatSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import { useFocusWhenTyping } from '#shared/composables/useFocusWhenTyping.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import stopEvent from '#shared/utils/events.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useCommonSelect } from '#desktop/components/CommonSelect/useCommonSelect.ts'
import { useTransitionCollapse } from '#desktop/composables/useTransitionCollapse.ts'

import FieldTreeSelectInputDropdownItem from './FieldTreeSelectInputDropdownItem.vue'

import type { FieldTreeSelectInputDropdownInternalInstance } from './types.ts'
import type { Ref } from 'vue'

export interface Props {
  // we cannot move types into separate file, because Vue would not be able to
  // transform these into runtime types
  modelValue?: string | number | boolean | (string | number | boolean)[] | null
  options: FlatSelectOption[]
  /**
   * Do not modify local value
   */
  passive?: boolean
  multiple?: boolean
  noClose?: boolean
  noRefocus?: boolean
  owner?: string
  noOptionsLabelTranslation?: boolean
  currentPath: FlatSelectOption[]
  filter: string
  flatOptions: FlatSelectOption[]
  currentOptions: FlatSelectOption[]
  optionValueLookup: { [index: string | number]: FlatSelectOption }
  isTargetVisible?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [option: string | number | (string | number)[]]
  select: [option: FlatSelectOption]
  close: []
  push: [option: FlatSelectOption]
  pop: []
  'clear-filter': []
}>()

const locale = useLocaleStore()

const dropdownElement = useTemplateRef('dropdown')
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

const { activateTabTrap, deactivateTabTrap } = useTrapTab(
  dropdownElement as Ref<HTMLElement>,
)

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
  if (!props.noRefocus) {
    nextTick(() => lastFocusableOutsideElement?.focus())
  }

  nextTick(() => {
    testFlags.set('field-tree-select-input-dropdown.closed')
  })
}

const openDropdown = (
  bounds: UseElementBoundingReturn,
  height: Ref<number>,
) => {
  inputElementBounds = bounds
  windowHeight = toRef(height)
  instances.value.forEach((instance) => {
    if (instance.isOpen) instance.closeDropdown()
  })
  showDropdown.value = true
  lastFocusableOutsideElement = getActiveElement()

  onClickOutside(dropdownElement, closeDropdown, {
    ignore: [lastFocusableOutsideElement as unknown as HTMLElement],
  })

  requestAnimationFrame(() => {
    nextTick(() => {
      testFlags.set('field-tree-select-input-dropdown.opened')
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

const exposedInstance: FieldTreeSelectInputDropdownInternalInstance = {
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

const select = (option: FlatSelectOption) => {
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

const hasMoreSelectableOptions = computed(() => {
  if (props.currentPath.length)
    return props.currentOptions.some(
      (option) => !option.disabled && !isCurrentValue(option.value),
    )

  return (
    props.options.filter(
      (option) => !option.disabled && !isCurrentValue(option.value),
    ).length > 0
  )
})

const focusFirstOption = () => {
  const focusableElements = getFocusableOptions()
  if (!focusableElements?.length) return

  const focusElement = focusableElements[0]

  focusElement?.focus()
}

const selectAll = (noFocus?: boolean) => {
  // If currently viewing a parent, select visible only.
  if (props.currentPath.length) {
    props.currentOptions
      .filter((option) => !option.disabled && !isCurrentValue(option.value))
      .forEach((option) => select(option))
  } else {
    props.options
      .filter((option) => !option.disabled && !isCurrentValue(option.value))
      .forEach((option) => select(option))
  }

  if (noFocus) return

  nextTick(() => {
    focusFirstOption()
  })
}

const previousPageCallback = (noFocus?: boolean) => {
  emit('pop')
  emit('clear-filter')

  if (noFocus) return

  nextTick(() => {
    focusFirstOption()
  })
}

const goToPreviousPage = (noFocus?: boolean) => {
  previousPageCallback(noFocus)
}

const nextPageCallback = (option?: FlatSelectOption, noFocus?: boolean) => {
  if (option?.hasChildren) {
    emit('push', option)

    if (noFocus) return

    nextTick(() => {
      focusFirstOption()
    })
  }
}

const goToNextPage = ({
  option,
  noFocus,
}: {
  option: FlatSelectOption
  noFocus?: boolean
}) => {
  nextPageCallback(option, noFocus)
}

const maybeGoToNextOrPreviousPage = (
  option: FlatSelectOption,
  direction: 'left' | 'right',
) => {
  if (
    (locale.localeData?.dir === 'rtl' && direction === 'right') ||
    (locale.localeData?.dir === 'ltr' && direction === 'left')
  ) {
    goToPreviousPage()

    return
  }

  goToNextPage({ option })
}

const getCurrentIndex = (option: FlatSelectOption) => {
  return props.flatOptions.findIndex((o) => o.value === option.value)
}

const highlightedOptions = computed(() =>
  props.options.map((option) => {
    let parentPaths: string[] = []

    if (option.parents) {
      parentPaths = option.parents.map((parentValue) => {
        const parentOption =
          props.optionValueLookup[parentValue as string | number]

        return `${parentOption.label || parentOption.value} \u203A `
      })
    }

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
        : 'bg-blue-600 dark:bg-blue-900 group-hover:bg-blue-800 group-hover:group-focus:bg-blue-600 group-hover:text-white group-focus:text-black group-hover:group-focus:text-black'

      label = `${labelBeforeMatch}<span class="${highlightClasses}">${labelMatchedText}</span>${labelAfterMatch}`
    }

    return {
      ...option,
      matchedPath: parentPaths.join('') + label,
    } as MatchedFlatSelectOption
  }),
)

const { collapseDuration, collapseEnter, collapseAfterEnter, collapseLeave } =
  useTransitionCollapse()
</script>

<template>
  <slot
    :state="showDropdown"
    :open="openDropdown"
    :close="closeDropdown"
    :focus="moveFocusToDropdown"
  />
  <Teleport to="body">
    <Transition
      :name="isTargetVisible ? 'collapse' : 'none'"
      :duration="collapseDuration"
      @enter="collapseEnter"
      @after-enter="collapseAfterEnter"
      @leave="collapseLeave"
    >
      <div
        v-if="showDropdown"
        v-show="isTargetVisible"
        id="field-tree-select-input-dropdown"
        ref="dropdown"
        class="fixed z-50 flex min-h-9 antialiased"
        :style="dropdownStyle"
      >
        <div class="w-full" role="menu">
          <div
            class="flex h-full flex-col items-start border-x border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
            :class="{
              'rounded-t-lg border-t': hasDirectionUp,
              'rounded-b-lg border-b': !hasDirectionUp,
            }"
          >
            <div
              v-if="
                currentPath.length || (multiple && hasMoreSelectableOptions)
              "
              class="flex w-full justify-between gap-2 px-2.5 py-1.5"
            >
              <CommonLabel
                v-if="currentPath.length"
                class="text-blue-800 hover:text-black focus-visible:rounded-xs focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-blue-800 dark:hover:text-white"
                :prefix-icon="
                  locale.localeData?.dir === 'rtl'
                    ? 'chevron-right'
                    : 'chevron-left'
                "
                :aria-label="$t('Back to previous page')"
                size="small"
                role="button"
                tabindex="0"
                @click.stop="goToPreviousPage(true)"
                @keypress.enter.prevent.stop="goToPreviousPage()"
                @keypress.space.prevent.stop="goToPreviousPage()"
              >
                {{ $t('Back') }}
              </CommonLabel>
              <CommonLabel
                v-if="multiple && hasMoreSelectableOptions"
                class="ms-auto text-blue-800 hover:text-black focus-visible:rounded-xs focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-blue-800 dark:hover:text-white"
                prefix-icon="check-all"
                size="small"
                role="button"
                tabindex="0"
                @click.stop="selectAll(true)"
                @keypress.enter.prevent.stop="selectAll()"
                @keypress.space.prevent.stop="selectAll()"
              >
                {{
                  currentPath.length
                    ? $t('select visible options')
                    : $t('select all options')
                }}
              </CommonLabel>
            </div>
            <div
              :aria-label="$t('Select…')"
              role="listbox"
              :aria-multiselectable="multiple"
              tabindex="-1"
              class="w-full overflow-y-auto"
            >
              <FieldTreeSelectInputDropdownItem
                v-for="option in filter ? highlightedOptions : currentOptions"
                :key="String(option.value)"
                :class="{
                  'first:rounded-t-[7px]':
                    hasDirectionUp &&
                    !currentPath.length &&
                    (!multiple || !hasMoreSelectableOptions),
                  'last:rounded-b-[7px]': !hasDirectionUp,
                }"
                :aria-setsize="flatOptions.length"
                :aria-posinset="getCurrentIndex(option) + 1"
                :selected="isCurrentValue(option.value)"
                :multiple="multiple"
                :filter="filter"
                :option="option"
                :no-label-translate="noOptionsLabelTranslation"
                @select="select($event)"
                @next="goToNextPage($event)"
                @keydown.right.prevent="
                  maybeGoToNextOrPreviousPage(option, 'right')
                "
                @keydown.left.prevent="
                  maybeGoToNextOrPreviousPage(option, 'left')
                "
              />
              <FieldTreeSelectInputDropdownItem
                v-if="!options.length"
                :option="
                  {
                    label: __('No results found'),
                    value: '',
                    disabled: true,
                  } as MatchedFlatSelectOption
                "
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
