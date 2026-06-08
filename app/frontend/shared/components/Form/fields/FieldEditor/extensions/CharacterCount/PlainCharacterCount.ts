// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { CharacterCount } from '@tiptap/extension-character-count'

import { useFormkitMessageManager } from '#shared/composables/useFormkitMessageManager.ts'

// Monkey patch CharacterCount to add warning management for plain text mode
export const PlainCharacterCount = CharacterCount.extend({
  name: 'characterCount',

  onBeforeCreate() {
    const formkitNodeId = (this.editor.options?.editorProps?.attributes as Record<string, unknown>)
      ?.id as string

    const messageKey = 'characterLimitWarning'

    const { setNodeMessage, removeNodeMessage } = useFormkitMessageManager(formkitNodeId)

    // augmenting type mess up the entire type interface
    // @ts-expect-error @ts-ignore
    this.storage.clearWarnings = () => removeNodeMessage(messageKey)

    const validateLimit = (countedText: number) => {
      const hasReachedLimit = countedText > (this.options?.limit ?? Infinity)

      if (hasReachedLimit) {
        setNodeMessage(messageKey, {
          type: 'warning',
          message: __('Character limit reached'),
        })
      } else {
        removeNodeMessage(messageKey)
      }
    }

    this.storage.characters = (options) => {
      const node = options?.node || this.editor.state.doc
      const mode = options?.mode || this.options.mode

      if (mode === 'textSize') {
        const text = node.textBetween(0, node.content.size, undefined, ' ')

        const countedText = this.options.textCounter(text)

        validateLimit(countedText)

        return countedText
      }

      validateLimit(node.nodeSize)

      return node.nodeSize
    }

    this.storage.words = (options) => {
      const node = options?.node || this.editor.state.doc
      const text = node.textBetween(0, node.content.size, ' ', ' ')

      return this.options.wordCounter(text)
    }
  },
})
