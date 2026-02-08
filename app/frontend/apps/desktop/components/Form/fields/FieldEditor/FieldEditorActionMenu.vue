<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// import { findParentNodeClosestToPos } from '@tiptap/core'
import { onKeyUp, useEventListener } from '@vueuse/core'
import { computed, nextTick, toRef, type Component } from 'vue'

import useEditorActionHelper from '#shared/components/Form/fields/FieldEditor/composables/useEditorActionHelper.ts'
import type {
  EditorButton,
  EditorContentType,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { Editor } from '@tiptap/vue-3'

type ActionItem = EditorButton & MenuItem
interface Props {
  actions: ActionItem[] | Component
  contentType: EditorContentType
  editor: Editor
  visible?: boolean
  isActive?: (type: string, attributes?: Record<string, unknown>) => boolean
  typeName?: string
  targetId?: string
}

const props = withDefaults(defineProps<Props>(), {
  visible: true,
})

// Generate unique targetId per component instance to avoid cross-editor targeting
const targetId = computed(() => props.targetId || `editor-action-menu-${getUuid()}`)

const emit = defineEmits<{
  hide: []
  blur: []
  'click-action': [EditorButton, MouseEvent]
  'close-popover': []
}>()

const slotActionsConfig = computed(() =>
  (props.actions as ActionItem[]).map((action) => ({
    key: action.key,
    hasSubmenu: !!action.subMenu,
    // keyboardShortcut: action.shortcut :TODO
  })),
)

const { isActive } = useEditorActionHelper(toRef(props, 'editor'))

const { open, close, popoverTarget, popover, isOpen } = usePopover()

const setPopoverTarget = (target?: HTMLDivElement) => {
  if (!props.editor) return

  if (target) {
    popoverTarget.value = target

    if (popoverTarget.value && !isOpen.value) {
      nextTick(() => {
        open()
      })
    }
    return
  }
}

// `ID` gets set on each editor, so we can distinguish between them
const isCurrentFocusedEditorWithTypeName = (element: HTMLElement | null) =>
  element?.closest(`#${props.editor?.view.dom.id}`) &&
  props.editor.isFocused &&
  isActive(props.typeName!)

onKeyUp(['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight'], (e) => {
  if (isCurrentFocusedEditorWithTypeName(e.target as HTMLElement)) {
    setPopoverTarget()
  } else if (isOpen.value) {
    close()
  }
})

useEventListener('click', (e) => {
  const target = e.target as HTMLDivElement

  const targetElementWithId = target.closest(`#${CSS.escape(targetId.value)}`)

  if (targetElementWithId) {
    setPopoverTarget(targetElementWithId as HTMLDivElement)
    return
  }

  if (isCurrentFocusedEditorWithTypeName(e.target as HTMLElement)) setPopoverTarget()
})

const handleMenuItemClick = (action: MenuItem, event: MouseEvent) => {
  if ((action as ActionItem).subMenu) {
    const newPopoverTarget = document.getElementById(`${CSS.escape(targetId.value)}`)
    if (newPopoverTarget) {
      popoverTarget.value = newPopoverTarget as HTMLDivElement
    }
  }

  ;(action as ActionItem).command?.(event)
  emit('click-action', action as ActionItem, event)
}

defineExpose({ close })
</script>

<template>
  <CommonPopover
    ref="popover"
    class="editor-overflow-popover"
    :owner="popoverTarget"
    orientation="autoVertical"
    placement="start"
    hide-arrow
    z-index="50"
    @close="$emit('close-popover')"
  >
    <CommonPopoverMenu
      v-if="Array.isArray(actions)"
      :popover="popover"
      :items="actions"
      @click-item="handleMenuItemClick"
    >
      <template v-for="action in slotActionsConfig" :key="action.key" #[`itemRight-${action.key}`]>
        <CommonIcon
          v-if="action.hasSubmenu"
          class="fill-gray-100 group-hover:fill-white last:mr-2.5 dark:fill-neutral-400"
          name="chevron-down"
          size="tiny"
        />
      </template>
      <template #trailing-item="slotProps">
        <li v-if="(slotProps.item as unknown as ActionItem).showDivider">
          <hr
            :class="(slotProps.item as unknown as ActionItem).dividerClass"
            class="h-px w-full border-0 bg-neutral-100 dark:bg-gray-900"
          />
        </li>
      </template>
    </CommonPopoverMenu>
    <component :is="actions" v-else :editor="editor" @close="$emit('close-popover')" />
  </CommonPopover>
  <slot :target-id="targetId" :is-open="isOpen" />
</template>
