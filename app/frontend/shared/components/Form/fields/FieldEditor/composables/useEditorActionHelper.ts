// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { CanCommands, ChainedCommands } from '@tiptap/core'
import type { Editor } from '@tiptap/vue-3'
import type { ShallowRef } from 'vue'

export default function useEditorActionHelper(editor: ShallowRef<Editor | undefined>) {
  const focused = (fn: (commands: ChainedCommands) => ChainedCommands | null | void) => {
    return () => {
      if (!editor.value || editor.value.isDestroyed) return
      const chain = editor.value.chain().focus()
      fn(chain)?.run()
    }
  }

  const isActive = (type: string, attributes?: Record<string, unknown>) =>
    !!editor.value?.isActive(type, attributes)

  const canExecute = (func: keyof CanCommands) => {
    if (!editor.value || editor.value.isDestroyed) return false
    return !!editor.value?.can()[func](null as never, null as never)
  }

  return {
    focused,
    isActive,
    canExecute,
  }
}
