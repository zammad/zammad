<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { cloneDeep } from 'lodash-es'
import { computed, ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'
import { i18n } from '#shared/i18n.ts'

import { useTransitionCollapse } from '#desktop/composables/useTransitionCollapse.ts'

import type { PermissionsChildOption, PermissionsProps } from './types.ts'

const props = defineProps<{
  context: PermissionsProps
}>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue<string[] | undefined>(contextReactive)

const valueLookup = computed<Record<string, boolean>>(() => {
  const values: string[] = localValue.value || []

  return values.reduce((value: Record<string, boolean>, key) => {
    value[key] = true

    return value
  }, {})
})

const parentChildLookup = ref(
  props.context.options.reduce(
    (lookup: Record<string, PermissionsChildOption[]>, option) => {
      lookup[option.value] = option.children
      return lookup
    },
    {},
  ),
)

const initializeCollapseState = (key: string) =>
  !!localValue.value?.some((value: string) =>
    parentChildLookup.value[key]?.some((option) => option.value === value),
  )

const collapseLookup = ref(
  props.context.options.reduce((lookup: Record<string, boolean>, option) => {
    lookup[option.value] = initializeCollapseState(option.value)
    return lookup
  }, {}),
)

const updateValue = (key: string, state: boolean | undefined) => {
  const values: string[] = cloneDeep(localValue.value) || []

  if (state === true && !values.includes(key)) {
    values.push(key)
    localValue.value = values
    collapseLookup.value[key] = false
  } else if (state === false) {
    localValue.value = values.filter((value) => value !== key)
    collapseLookup.value[key] = initializeCollapseState(key)
  }
}

const toggleCollapse = (value: string) => {
  collapseLookup.value[value] = !collapseLookup.value[value]
}

const { delegateFocus } = useDelegateFocus(
  props.context.id,
  `permissions_toggle_${props.context.id}_${props.context?.options && props.context?.options[0]?.value}`,
)

const { collapseDuration, collapseEnter, collapseAfterEnter, collapseLeave } =
  useTransitionCollapse()
</script>

<template>
  <output
    :id="context.id"
    class="block rounded-lg bg-blue-200 focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-blue-800 hover:focus:outline-blue-800 dark:bg-gray-700"
    role="tree"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    :tabindex="context.disabled ? '-1' : '0'"
    v-bind="context.attrs"
    @focus="delegateFocus"
  >
    <div
      v-for="(option, index) in context.options"
      :key="`option-${option.value}`"
      class="flex flex-col"
    >
      <div
        class="flex items-center gap-2.5 px-3 py-2.5"
        role="treeitem"
        :aria-selected="valueLookup[option.value]"
      >
        <FormKit
          :id="`permissions_toggle_${context.id}_${option.value}`"
          :model-value="valueLookup[option.value]"
          type="toggle"
          :name="`permissions_toggle_${context.id}_${option.value}`"
          :ignore="true"
          outer-class="grow"
          wrapper-class="justify-end gap-2.5 formkit-disabled:opacity-100"
          inner-class="formkit-disabled:opacity-50"
          :variants="{ true: 'True', false: 'False' }"
          :disabled="context.disabled || option.disabled"
          size="small"
          :label="option.label"
          :sections-schema="{
            label: {
              attrs: {
                class: 'flex flex-col cursor-pointer',
                for: `permissions_toggle_${context.id}_${option.value}`,
                tabindex: '-1',
              },
              children: [
                {
                  $cmp: 'CommonLabel',
                  props: {
                    class: 'text-black dark:text-white',
                  },
                  children: [
                    {
                      $el: 'div',
                      attrs: {
                        class: 'shrink-0',
                      },
                      children: i18n.t(option.label),
                    },
                    {
                      $cmp: 'CommonBadge',
                      props: {
                        class: 'inline truncate',
                        variant: 'neutral',
                      },
                      children: option.value,
                    },
                  ],
                },
                {
                  $cmp: 'CommonLabel',
                  props: {
                    class: 'text-stone-200 dark:text-neutral-500',
                  },
                  children: i18n.t(option.description),
                },
              ],
            },
          }"
          @update:model-value="updateValue(option.value, $event)"
          @blur="index === 0 ? context.handlers.blur : undefined"
        />
        <CommonIcon
          v-if="option.children && !valueLookup[option.value]"
          class="shrink-0 fill-stone-200 hover:fill-black focus:outline-none focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
          :aria-label="i18n.t('Toggle Group')"
          :name="collapseLookup[option.value] ? 'chevron-up' : 'chevron-down'"
          size="xs"
          role="button"
          tabindex="0"
          @click.stop="toggleCollapse(option.value)"
          @keypress.enter.prevent.stop="toggleCollapse(option.value)"
          @keypress.space.prevent.stop="toggleCollapse(option.value)"
        />
      </div>
      <Transition
        name="collapse"
        :duration="collapseDuration"
        @enter="collapseEnter"
        @after-enter="collapseAfterEnter"
        @leave="collapseLeave"
      >
        <div
          v-if="option.children"
          v-show="collapseLookup[option.value]"
          class="ms-10 flex flex-col"
          role="group"
        >
          <div
            v-for="childOption in option.children"
            :key="`child-option-${childOption.value}`"
            class="flex gap-2.5 px-3 py-2.5"
            role="treeitem"
            :aria-selected="valueLookup[childOption.value]"
          >
            <FormKit
              :id="`permissions_child_toggle_${context.id}_${childOption.value}`"
              :model-value="valueLookup[childOption.value]"
              type="toggle"
              :name="`permissions_child_toggle_${context.id}_${childOption.value}`"
              :ignore="true"
              wrapper-class="gap-2.5"
              :variants="{ true: 'True', false: 'False' }"
              :disabled="context.disabled"
              size="small"
              :label="childOption.label"
              :sections-schema="{
                label: {
                  attrs: {
                    class: 'flex flex-col cursor-pointer',
                    for: `permissions_child_toggle_${context.id}_${childOption.value}`,
                    tabindex: '-1',
                  },
                  children: [
                    {
                      $cmp: 'CommonLabel',
                      props: {
                        class: 'text-black dark:text-white',
                      },
                      children: [
                        {
                          $el: 'div',
                          attrs: {
                            class: 'shrink-0',
                          },
                          children: i18n.t(childOption.label),
                        },
                        {
                          $cmp: 'CommonBadge',
                          props: {
                            class: 'inline truncate',
                            variant: 'neutral',
                          },
                          children: childOption.value,
                        },
                      ],
                    },
                    {
                      $cmp: 'CommonLabel',
                      props: {
                        class: 'text-stone-200 dark:text-neutral-500',
                      },
                      children: i18n.t(childOption.description),
                    },
                  ],
                },
              }"
              @update:model-value="updateValue(childOption.value, $event)"
            />
          </div>
        </div>
      </Transition>
    </div>
  </output>
</template>
