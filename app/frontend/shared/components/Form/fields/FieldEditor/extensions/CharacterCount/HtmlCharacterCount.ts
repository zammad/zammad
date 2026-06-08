// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { CharacterCount } from '@tiptap/extension-character-count'
import { DOMSerializer } from '@tiptap/pm/model'

import { useFormkitMessageManager } from '#shared/composables/useFormkitMessageManager.ts'

// Monkey patch CharacterCount to count HTML characters instead of text characters
export const HtmlCharacterCount = CharacterCount.extend({
  name: 'characterCount',

  onBeforeCreate() {
    this.storage.characters = (options) => {
      const node = options?.node || this.editor.state.doc

      const dom = document.createElement('div')
      const serializer = DOMSerializer.fromSchema(this.editor.schema)
      dom.appendChild(serializer.serializeFragment(node.content))

      const htmlLength = dom.innerHTML.length

      const hasReachedLimit = htmlLength > (this.options?.limit ?? Infinity)

      const formkitNodeId = (
        this.editor.options?.editorProps?.attributes as Record<string, unknown>
      )?.id as string

      const messageKey = 'characterLimitWarning'

      const { setNodeMessage, removeNodeMessage } = useFormkitMessageManager(formkitNodeId)

      if (hasReachedLimit) {
        setNodeMessage(messageKey, {
          type: 'warning',
          message: __('Character limit reached'),
        })
      } else {
        removeNodeMessage(messageKey)
      }

      // augmenting type mess up the entire type interface
      // @ts-expect-error @ts-ignore
      this.storage.clearWarnings = () => removeNodeMessage(messageKey)

      // Should behave similar as it get's evaluated on the server side
      return dom.innerHTML.length
    }
  },
})
