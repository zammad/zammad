// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      label: i18n.t('Format as underlined'),
      icon: 'mobile-text-style-underline',
      command: focused((c) => c.toggleUnderline()),
    },
    {
      name: 'bold',
      label: i18n.t('Format as bold'),
      icon: 'mobile-text-style-bold',
      command: focused((c) => c.toggleBold()),
    },
    {
      name: 'italic',
      label: i18n.t('Format as italic'),
      icon: 'mobile-text-style-italic',
      command: focused((c) => c.toggleItalic()),
    },
    {
      name: 'strike',
      label: i18n.t('Format as strikethrough'),
      icon: 'mobile-text-style-strikethrough',
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
      icon: 'mobile-link',
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
      label: i18n.t('Add first level heading'),
      icon: 'mobile-text-style-h1',
      attributes: {
        level: 1,
      },
      command: focused((c) => c.toggleHeading({ level: 1 })),
    },
    {
      name: 'heading',
      label: i18n.t('Add second level heading'),
      icon: 'mobile-text-style-h2',
      attributes: {
        level: 2,
      },
      command: focused((c) => c.toggleHeading({ level: 2 })),
    },
    {
      name: 'heading',
      label: i18n.t('Add third level heading'),
      icon: 'mobile-text-style-h3',
      attributes: {
        level: 3,
      },
      command: focused((c) => c.toggleHeading({ level: 3 })),
    },
    {
      name: 'orderedList',
      label: i18n.t('Add ordered list'),
      icon: 'mobile-ordered-list',
      command: focused((c) => {
        if (isActive('orderedList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleOrderedList()
      }),
    },
    {
      name: 'bulletList',
      label: i18n.t('Add bullet list'),
      icon: 'mobile-list',
      command: focused((c) => {
        if (isActive('orderedList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleBulletList()
      }),
    },
    {
      name: 'jibberish',
      label: i18n.t('Remove formatting'),
      icon: 'mobile-remove-formatting',
      command: focused((c) => c.clearNodes().unsetAllMarks()),
    },
    {
      name: 'mention-user',
      label: i18n.t('Mention user'),
      icon: 'mobile-at-sign',
      command: focused((c) => c.openUserMention()),
    },
    {
      name: 'mention-knowledge-base',
      label: i18n.t('Insert text from Knowledge Base article'),
      icon: 'mobile-mention-kb',
      command: focused((c) => c.openKnowledgeBaseMention()),
    },
    {
      name: 'mention-text',
      label: i18n.t('Insert text from text module'),
      icon: 'mobile-snippet',
      command: focused((c) => c.openTextMention()),
    },
  ]

  return {
    focused,
    isActive,
    actions,
  }
}
