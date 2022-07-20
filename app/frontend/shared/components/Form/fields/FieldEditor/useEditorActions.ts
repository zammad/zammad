// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { ChainedCommands } from '@tiptap/core'
import type { Editor } from '@tiptap/vue-3'
import type { Component, ShallowRef } from 'vue'
import ActionImage from './actions/ActionImage.vue'

export interface EditorButton {
  name: string
  class?: string
  icon?: string
  text?: string
  label?: string
  attributes?: Record<string, unknown>
  component?: Component
  command?: () => void
}

export default function useEditorActions(
  editor: ShallowRef<Editor | undefined>,
) {
  const focused = (
    fn: (commands: ChainedCommands) => ChainedCommands | undefined | null,
  ) => {
    return () => {
      if (!editor.value) return
      const chain = editor.value.chain().focus()
      fn(chain)?.run()
    }
  }

  const isActive = (type: string, attributes?: Record<string, unknown>) => {
    return editor.value?.isActive(type, attributes) ?? false
  }

  // TODO decide on icons/what is needed/order
  const actions: EditorButton[] = [
    {
      name: 'underline',
      class: 'underline',
      text: 'U',
      command: focused((c) => c.toggleUnderline()),
    },
    {
      name: 'bold',
      class: 'font-bold',
      text: 'B',
      command: focused((c) => c.toggleBold()),
    },
    {
      name: 'italic',
      class: 'italic',
      text: 'i',
      command: focused((c) => c.toggleItalic()),
    },
    {
      name: 'strike',
      class: 'line-through',
      text: 'S',
      command: focused((c) => c.toggleStrike()),
    },
    {
      name: 'image',
      label: i18n.t('Add image'),
      component: ActionImage,
    },
    {
      name: 'link',
      label: i18n.t('Add link'),
      icon: 'chain',
      command: focused((c) => {
        if (!editor.value) return null
        // eslint-disable-next-line no-alert
        const href = prompt(i18n.t('Enter link URL'))
        if (!href) return null
        const { view, state } = editor.value
        const { from, to } = view.state.selection
        const text = state.doc.textBetween(from, to, '')

        if (text) {
          return c.toggleLink({ href })
        }

        return c.insertContent({
          type: 'text',
          text: href,
          marks: [
            {
              type: 'link',
              attrs: {
                href,
              },
            },
          ],
        })
      }),
    },
    {
      name: 'heading',
      class: 'text-sm',
      text: 'H1',
      label: i18n.t('Add first level heading'),
      attributes: {
        level: 1,
      },
      command: focused((c) => c.toggleHeading({ level: 1 })),
    },
    {
      name: 'heading',
      class: 'text-sm',
      text: 'H2',
      label: i18n.t('Add second level heading'),
      attributes: {
        level: 2,
      },
      command: focused((c) => c.toggleHeading({ level: 2 })),
    },
    {
      name: 'heading',
      class: 'text-sm',
      text: 'H3',
      label: i18n.t('Add third level heading'),
      attributes: {
        level: 3,
      },
      command: focused((c) => c.toggleHeading({ level: 3 })),
    },
    {
      name: 'orderedList',
      text: 'O',
      label: i18n.t('Add ordered list'),
      command: focused((c) => {
        if (isActive('orderedList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleOrderedList()
      }),
    },
    {
      name: 'bulletList',
      text: '*',
      label: i18n.t('Add bullet list'),
      command: focused((c) => {
        if (isActive('orderedList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleBulletList()
      }),
    },
    {
      name: 'jibberish',
      text: 'F',
      label: i18n.t('Remove formatting'),
      command: focused((c) => c.clearNodes().unsetAllMarks()),
    },
    {
      name: 'mention-user',
      text: '@',
      label: i18n.t('Mention user'),
      command: focused((c) => c.openUserMention()),
    },
    {
      name: 'mention-knowledge-base',
      text: '??',
      label: i18n.t('Insert text from Knowledge Base article'),
      command: focused((c) => c.openKnowledgeBaseMention()),
    },
    {
      name: 'mention-text',
      text: '::',
      label: i18n.t('Insert text from text module'),
      command: focused((c) => c.openTextMention()),
    },
  ]

  return {
    focused,
    isActive,
    actions,
  }
}
