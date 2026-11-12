<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, toRef, useTemplateRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

const props = defineProps<{
  context: FormFieldContext<{
    description?: string
    emptyLabel?: string
    itemLabel: string
    itemPlaceholder?: string
    addLabel: string
    editLabel: string
    removeLabel: string
  }>
}>()

const context = toRef(props, 'context')

const { localValue } = useValue<string[]>(context)

const items = computed<string[]>(() => localValue.value ?? [])

// One line right below the label: what the texts are for once there are some, that there are none before.
const hint = computed(() =>
  items.value.length ? context.value.description : context.value.emptyLabel,
)

const hintId = computed(() => `${context.value.id}-hint`)

const describedBy = computed(
  () =>
    [hint.value ? hintId.value : undefined, context.value.describedBy].filter(Boolean).join(' ') ||
    undefined,
)

const inlineEdits = useTemplateRef<InstanceType<typeof CommonInlineEdit>[]>('inline-edit')

const list = useTemplateRef('list')

const addButton = useTemplateRef<InstanceType<typeof CommonButton>>('add-button')

const updateItem = (index: number, text: string) => {
  localValue.value = items.value.map((item, position) => (position === index ? text : item))
}

// Taken out of the list only: the form writes it once it is submitted.
const removeItem = (index: number) => {
  localValue.value = items.value.filter((_, position) => position !== index)
}

const addItem = async () => {
  localValue.value = [...items.value, '']

  await nextTick()

  inlineEdits.value?.at(-1)?.activateEditing()
}

const focusAddButton = async () => {
  await nextTick()

  ;(addButton.value?.$el as HTMLElement | undefined)?.focus()
}

// A line left empty is not kept, however its editing ended: Enter and a click elsewhere stop
//   it without a cancel, as Escape does with one. The focus it took with it goes back to the
//   button; a click elsewhere has given it its own place already.
const dropEmptyItem = (index: number) => {
  if (items.value[index]) return

  const hadFocus = Boolean(list.value?.children[index]?.contains(document.activeElement))

  removeItem(index)

  if (hadFocus) focusAddButton()
}

// Rows are keyed by position, so it is always the last row that unmounts. When that is the row
//   removed, the menu trigger the focus would return to is gone with it.
const removeItemFromMenu = (index: number) => {
  const wasLast = index === items.value.length - 1

  removeItem(index)

  if (wasLast) focusAddButton()
}

const actions = (index: number): MenuItem[] => [
  {
    key: 'edit',
    icon: 'pencil',
    label: context.value.editLabel,
    onClick: () => inlineEdits.value?.[index]?.activateEditing(),
  },
  {
    key: 'remove',
    icon: 'trash3',
    label: context.value.removeLabel,
    separatorTop: true,
    onClick: () => removeItemFromMenu(index),
  },
]
</script>

<template>
  <div :id="context.id" class="flex flex-col gap-2" :aria-describedby="context.describedBy">
    <!-- Right below the label rather than as the field's help, which comes after the list and its button. -->
    <CommonLabel v-if="hint" :id="hintId" class="text-muted!" size="small">
      {{ $t(hint) }}
    </CommonLabel>

    <ul
      v-if="items.length"
      ref="list"
      class="flex flex-col gap-2"
      :aria-labelledby="`label-${context.id}`"
      :aria-describedby="describedBy"
    >
      <li
        v-for="(item, index) in items"
        :key="index"
        class="flex min-h-10 gap-2 overflow-x-clip rounded-lg bg-blue-200 p-2 text-muted dark:bg-gray-700"
      >
        <CommonInlineEdit
          ref="inline-edit"
          alternative-background
          block
          :value="item"
          :label="$t(context.itemLabel)"
          :placeholder="context.itemPlaceholder"
          :disabled="context.disabled"
          :classes="{ label: 'text-contrast pe-7!', input: 'text-contrast' }"
          @submit-edit="(text: string) => updateItem(index, text)"
          @update:editing="(editing: boolean) => editing || dropEmptyItem(index)"
        />

        <CommonActionMenu
          v-if="!inlineEdits?.[index]?.isEditing && !context.disabled"
          button-size="small"
          class="mt-0.5 flex!"
          placement="arrowEnd"
          no-single-action-mode
          :actions="actions(index)"
        />
      </li>
    </ul>

    <CommonButton
      ref="add-button"
      v-tooltip="$t(context.addLabel)"
      class="self-end ltr:mr-2 rtl:ml-2"
      size="medium"
      icon="plus-square-fill"
      :disabled="context.disabled"
      @click="addItem"
    />
  </div>
</template>
