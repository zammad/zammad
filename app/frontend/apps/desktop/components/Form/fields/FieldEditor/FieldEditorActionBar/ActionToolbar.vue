<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyDown, useEventListener, useIntersectionObserver, whenever } from '@vueuse/core'
import { computed, ref, shallowRef, useTemplateRef, type Ref, toRef } from 'vue'

import FieldEditorActionMenu from '#shared/components/Form/fields/FieldEditor/FieldEditorActionMenu/FieldEditorActionMenu.vue'
import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import stopEvent from '#shared/utils/events.ts'

import ActionButtonWrapper from '#desktop/components/Form/fields/FieldEditor/FieldEditorActionBar/ActionButtonWrapper.vue'
import useEditorActions from '#desktop/components/Form/fields/FieldEditor/useEditorActions.ts'

import ActionButton from './ActionButton.vue'

import type { Editor } from '@tiptap/vue-3'

interface Props {
  actions: EditorButton[]
  editor?: Editor
  visible?: boolean
  isActive?: (type: string, attributes?: Record<string, unknown>) => boolean
  isInline?: boolean
}

// Doesn't pick up the types for some reason, verify again if resolved after an update
const actionBar = useTemplateRef<HTMLDivElement>('action-bar')
const actionButtons = useTemplateRef<Array<InstanceType<typeof ActionButton>>>('action-button')

useIntersectionObserver(
  actionBar,
  ([{ isIntersecting }]) => {
    actionButtons.value?.forEach((actionButton) => {
      if (isIntersecting) actionButton?.resumeIntersectionObserver()
      else actionButton?.pauseIntersectionObserver()
    })
  },
  {
    threshold: 0,
  },
)

const props = withDefaults(defineProps<Props>(), {
  visible: true,
  size: 'medium',
})

const editor = toRef(props, 'editor')

const emit = defineEmits<{
  hide: []
  blur: []
  'click-action': [EditorButton, MouseEvent]
}>()

const restoreScroll = () => {
  const menuBar = actionBar.value as HTMLElement
  // restore scroll position, if needed
  menuBar.scroll(0, 0)
}

useTraverseOptions(actionBar, { direction: 'horizontal', ignoreTabindex: true })

onKeyDown(
  'Escape',
  (e) => {
    stopEvent(e)
    emit('blur')
  },
  { target: actionBar as Ref<EventTarget> },
)

useEventListener('click', (e) => {
  if (!actionBar.value) return

  const target = e.target as HTMLElement

  if (!actionBar.value.contains(target) && !editor.value?.isFocused) {
    restoreScroll()
    emit('hide')
  }
})

const visibleActions = ref<Map<string, boolean>>(new Map())
const disabledActionNames = ref<Set<string>>(new Set())

const editorActions = useEditorActions(toRef(props, 'editor'), 'text/html')

const invisibleActions = computed(() =>
  editorActions.actions.value
    .filter((action) => visibleActions.value.get(action.name) === false)
    .map((action) =>
      Object.assign(action, {
        key: action.name,
        noCloseOnClick: !!action.subMenu,
      }),
    ),
)

const activeActionWithSubmenu = shallowRef<EditorButton['subMenu'] | null>(null)

const activeActions = computed(() =>
  activeActionWithSubmenu.value !== null
    ? activeActionWithSubmenu.value
    : invisibleActions.value.filter(({ name }) => !disabledActionNames.value.has(name)),
)

const handleOverlowMenuItemClick = async (action: EditorButton, event: MouseEvent) => {
  stopEvent(event)

  if (action.subMenu) {
    activeActionWithSubmenu.value = action.subMenu
  }
}

// Unfortunately, we can't rely on mounted or setup hooks here, we need to await the editor to be ready
whenever(
  () => props.editor,
  (editor) => {
    if (!editor) return
    editor.off('toggle-visibility')
    editor.on('toggle-visibility', ({ name, active }) => {
      if (active) disabledActionNames.value.delete(name)
      else disabledActionNames.value.add(name)
    })
  },
  { immediate: true, flush: 'post' },
)
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <div
    ref="action-bar"
    data-test-id="action-bar"
    class="relative flex justify-between gap-1.5 focus-visible-app-default focus-visible:outline-offset-0"
    tabindex="0"
    role="toolbar"
  >
    <div
      class="flex flex-wrap gap-1.5 overflow-hidden"
      :class="{
        'h-10.5 py-2 ps-2.5 pe-0.5': !isInline,
        'h-9 py-1 ps-1.5 pe-0.5': isInline,
      }"
    >
      <ActionButtonWrapper
        v-for="(action, index) in actions"
        :key="action.name"
        :invisible-actions="invisibleActions"
        :actions="actions"
        :index="index"
      >
        <template v-if="!disabledActionNames.has(action.name)" #default="{ hideDivider }">
          <ActionButton
            ref="action-button"
            :action="action"
            :action-bar="actionBar"
            :editor="editor"
            :is-active="isActive"
            @click="
              (event: MouseEvent) => {
                action.command?.(event)
                $emit('click-action', action, event)
              }
            "
            @visible="visibleActions.set(action.name, $event)"
          />
          <hr
            v-if="action.showDivider"
            :class="[
              action.dividerClass,
              {
                invisible: hideDivider,
              },
            ]"
            class="h-full w-px border-0 bg-neutral-700 dark:bg-neutral-800"
          />
        </template>
      </ActionButtonWrapper>
    </div>
    <div
      v-if="invisibleActions.length"
      :class="{
        'flex gap-1.5 px-2.5 py-2': !isInline,
        'flex gap-1.5 px-1.5 py-1': isInline,
      }"
    >
      <FieldEditorActionMenu
        :editor="editor"
        content-type="text/html"
        :actions="activeActions!"
        @click-action="handleOverlowMenuItemClick"
        @close-popover="activeActionWithSubmenu = null"
      >
        <template #default="{ targetId, isOpen }">
          <button
            :id="targetId"
            v-tooltip="$t('Overflow menu')"
            type="button"
            class="rounded-lg p-1.5! focus-visible-app-default hover:bg-blue-600 hover:text-black dark:hover:bg-blue-900 dark:hover:text-white"
            :class="{
              'bg-blue-800! text-white!': isOpen,
            }"
          >
            <CommonIcon name="three-dots-vertical" size="tiny" decorative />
          </button>
        </template>
      </FieldEditorActionMenu>
    </div>
  </div>
</template>
