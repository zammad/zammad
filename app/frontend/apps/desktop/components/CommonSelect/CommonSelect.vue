<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  type UseElementBoundingReturn,
  onClickOutside,
  onKeyDown,
  useVModel,
} from '@vueuse/core'
import { useTemplateRef } from 'vue'
import {
  computed,
  type ConcreteComponent,
  nextTick,
  onUnmounted,
  ref,
  type Ref,
  toRef,
} from 'vue'

import type {
  MatchedSelectOption,
  SelectOption,
  SelectValue,
} from '#shared/components/CommonSelect/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import { useFocusWhenTyping } from '#shared/composables/useFocusWhenTyping.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import stopEvent from '#shared/utils/events.ts'
import testFlags from '#shared/utils/testFlags.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useTransitionCollapse } from '#desktop/composables/useTransitionCollapse.ts'

import CommonSelectItem from './CommonSelectItem.vue'
import { useCommonSelect } from './useCommonSelect.ts'

import type {
  CommonSelectInternalInstance,
  DropdownOptionsAction,
} from './types.ts'

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
  emptyInitialLabelText?: string
  actions?: DropdownOptionsAction[]
  isChildPage?: boolean
  isLoading?: boolean
  isTargetVisible?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  emptyInitialLabelText: __('Start typing to search…'),
})

const emit = defineEmits<{
  'update:modelValue': [option: string | number | (string | number)[]]
  select: [option: SelectOption]
  push: [option: AutoCompleteOption]
  pop: []
  close: []
  'focus-filter-input': []
}>()

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

const { activateTabTrap, deactivateTabTrap } = useTrapTab(dropdownElement)

let lastFocusableOutsideElement: HTMLElement | null = null

const getActiveElement = () => {
  if (props.owner) {
    return document.getElementById(props.owner)
  }

  return document.activeElement as HTMLElement
}

const { instances } = useCommonSelect()

const closeDropdown = (refocusOnEscape?: boolean) => {
  deactivateTabTrap()

  showDropdown.value = false
  emit('close')

  nextTick(() => {
    if (!props.noRefocus || refocusOnEscape)
      lastFocusableOutsideElement?.focus()
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

  onClickOutside(dropdownElement, () => closeDropdown(), {
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
    closeDropdown(true)
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

const focusFirstOption = () => {
  const focusableElements = getFocusableOptions()
  if (!focusableElements?.length) return

  const focusElement = focusableElements[0]

  focusElement?.focus()
}

const selectAll = (focusInput = false) => {
  props.options
    .filter((option) => !option.disabled && !isCurrentValue(option.value))
    .forEach((option) => select(option))

  if (focusInput === true) {
    emit('focus-filter-input')
    return
  }

  focusFirstOption()
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
  return props.filter ? __('No results found') : props.emptyInitialLabelText
})

const { collapseDuration, collapseEnter, collapseAfterEnter, collapseLeave } =
  useTransitionCollapse()

const dropdownActions = computed(() => {
  return [
    ...(props.actions || []),
    ...(props.multiple && hasMoreSelectableOptions.value
      ? [
          {
            key: 'selectAll',
            label: __('select all options'),
            icon: 'check-all',
            onClick: selectAll,
          },
        ]
      : []),
  ]
})

const locale = useLocaleStore()

const parentPageCallback = (noFocus?: boolean) => {
  emit('pop')

  if (noFocus) return

  nextTick(() => {
    focusFirstOption()
  })
}

const goToParentPage = (noFocus?: boolean) => {
  parentPageCallback(noFocus)
}

const childPageCallback = (option?: AutoCompleteOption, noFocus?: boolean) => {
  if (option?.children) {
    emit('push', option)

    if (noFocus) return

    nextTick(() => {
      focusFirstOption()
    })
  }
}

const goToChildPage = ({
  option,
  noFocus,
}: {
  option: AutoCompleteOption
  noFocus?: boolean
}) => {
  childPageCallback(option, noFocus)
}
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
        id="common-select"
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
              v-if="isChildPage || dropdownActions.length"
              class="flex w-full justify-between gap-2 px-2.5 py-1.5"
            >
              <CommonLabel
                v-if="isChildPage"
                class="text-blue-800 hover:text-black focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-blue-800 dark:hover:text-white"
                :aria-label="$t('Back to previous page')"
                :prefix-icon="
                  locale.localeData?.dir === 'rtl'
                    ? 'chevron-right'
                    : 'chevron-left'
                "
                size="small"
                role="button"
                tabindex="0"
                @click.stop="goToParentPage(true)"
                @keypress.enter.prevent.stop="goToParentPage()"
                @keypress.space.prevent.stop="goToParentPage()"
              >
                {{ $t('Back') }}
              </CommonLabel>
              <div
                v-if="dropdownActions.length"
                class="flex grow justify-end gap-2"
              >
                <CommonLabel
                  v-for="action of dropdownActions"
                  :key="action.key"
                  :prefix-icon="action.icon"
                  class="text-blue-800 hover:text-black focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-blue-800 dark:hover:text-white"
                  size="small"
                  role="button"
                  tabindex="0"
                  @click.stop="action.onClick(true)"
                  @keypress.enter.prevent.stop="action.onClick"
                  @keypress.space.prevent.stop="action.onClick"
                >
                  {{ $t(action.label) }}
                </CommonLabel>
              </div>
            </div>
            <div
              :aria-label="$t('Select…')"
              role="listbox"
              :aria-multiselectable="multiple"
              tabindex="-1"
              class="w-full overflow-y-auto"
            >
              <Transition name="none" mode="out-in">
                <div v-if="options.length">
                  <CommonSelectItem
                    v-for="option in filter ? highlightedOptions : options"
                    :key="String(option.value)"
                    :class="{
                      'first:rounded-t-lg':
                        hasDirectionUp &&
                        !isChildPage &&
                        (!multiple || !hasMoreSelectableOptions),
                      'last:rounded-b-lg': !hasDirectionUp,
                    }"
                    :selected="isCurrentValue(option.value)"
                    :multiple="multiple"
                    :option="option"
                    :no-label-translate="noOptionsLabelTranslation"
                    :filter="filter"
                    :option-icon-component="optionIconComponent"
                    @select="select($event)"
                    @next="goToChildPage($event)"
                  />
                </div>

                <div v-else-if="isLoading" class="flex items-center">
                  <CommonLoader
                    v-if="!options.length"
                    class="ltr:ml-2 rtl:mr-2"
                    size="small"
                    loading
                  />
                  <CommonSelectItem
                    :option="{
                      label: __('Loading…'),
                      value: '',
                      disabled: true,
                    }"
                    no-selection-indicator
                  />
                </div>
                <CommonSelectItem
                  v-else-if="!options.length"
                  :option="{
                    label: emptyLabelText,
                    value: '',
                    disabled: true,
                  }"
                  no-selection-indicator
                />
              </Transition>

              <slot name="footer" />
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
