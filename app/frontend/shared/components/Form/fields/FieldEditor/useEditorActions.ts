// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { convertFileList } from '@shared/utils/files'
import type { ChainedCommands } from '@tiptap/core'
import type { Editor } from '@tiptap/vue-3'
import { computed, onUnmounted } from 'vue'
import type { ShallowRef } from 'vue'

import { PLUGIN_NAME as KnowledgeBaseMentionName } from './suggestions/KnowledgeBaseSuggestion'
import { PLUGIN_NAME as TextModuleMentionName } from './suggestions/TextModuleSuggestion'
import { PLUGIN_NAME as UserMentionName } from './suggestions/UserMention'
import type { EditorContentType } from './types'

export interface EditorButton {
  name: string
  class?: string
  icon: string
  label?: string
  contentType: EditorContentType[]
  attributes?: Record<string, unknown>
  command?: () => void
}

export default function useEditorActions(
  editor: ShallowRef<Editor | undefined>,
  contentType: EditorContentType,
  disabledPlugins: string[],
) {
  const focused = (
    fn: (commands: ChainedCommands) => ChainedCommands | null | void,
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

  // this is primarily used by cypress tests, where it requires actual input in dom
  let fileInput: HTMLInputElement | null = null

  const getInputForImage = () => {
    if (fileInput) return fileInput

    fileInput = document.createElement('input')
    fileInput.type = 'file'
    fileInput.multiple = true
    fileInput.accept = 'image/*'
    fileInput.style.display = 'hidden'
    if (import.meta.env.DEV || VITE_TEST_MODE) {
      fileInput.dataset.testId = 'editor-image-input'
    }
    document.body.appendChild(fileInput)

    return fileInput
  }

  onUnmounted(() => {
    fileInput?.remove()
  })

  const getActionsList = (): EditorButton[] => {
    return [
      {
        name: 'underline',
        contentType: ['text/html'],
        label: i18n.t('Format as underlined'),
        icon: 'mobile-text-style-underline',
        command: focused((c) => c.toggleUnderline()),
      },
      {
        name: 'bold',
        contentType: ['text/html'],
        label: i18n.t('Format as bold'),
        icon: 'mobile-text-style-bold',
        command: focused((c) => c.toggleBold()),
      },
      {
        name: 'italic',
        contentType: ['text/html'],
        label: i18n.t('Format as italic'),
        icon: 'mobile-text-style-italic',
        command: focused((c) => c.toggleItalic()),
      },
      {
        name: 'strike',
        contentType: ['text/html'],
        label: i18n.t('Format as strikethrough'),
        icon: 'mobile-text-style-strikethrough',
        command: focused((c) => c.toggleStrike()),
      },
      {
        name: 'image',
        contentType: ['text/html'],
        label: i18n.t('Add image'),
        icon: 'mobile-photos',
        command: focused((c) => {
          const input = getInputForImage()
          input.onchange = async () => {
            if (!input.files?.length) return
            const files = await convertFileList(input.files)
            c.setImages(files).run()
            input.value = ''
          }
          input.click()
        }),
      },
      {
        name: 'link',
        contentType: ['text/html'],
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
        contentType: ['text/html'],
        label: i18n.t('Add first level heading'),
        icon: 'mobile-text-style-h1',
        attributes: {
          level: 1,
        },
        command: focused((c) => c.toggleHeading({ level: 1 })),
      },
      {
        name: 'heading',
        contentType: ['text/html'],
        label: i18n.t('Add second level heading'),
        icon: 'mobile-text-style-h2',
        attributes: {
          level: 2,
        },
        command: focused((c) => c.toggleHeading({ level: 2 })),
      },
      {
        name: 'heading',
        contentType: ['text/html'],
        label: i18n.t('Add third level heading'),
        icon: 'mobile-text-style-h3',
        attributes: {
          level: 3,
        },
        command: focused((c) => c.toggleHeading({ level: 3 })),
      },
      {
        name: 'orderedList',
        contentType: ['text/html'],
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
        contentType: ['text/html'],
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
        contentType: ['text/html'],
        label: i18n.t('Remove formatting'),
        icon: 'mobile-remove-formatting',
        command: focused((c) => c.clearNodes().unsetAllMarks()),
      },
      {
        name: UserMentionName,
        contentType: ['text/html'],
        label: i18n.t('Mention user'),
        icon: 'mobile-at-sign',
        command: focused((c) => c.openUserMention()),
      },
      {
        name: KnowledgeBaseMentionName,
        contentType: ['text/html', 'text/plain'],
        label: i18n.t('Insert text from Knowledge Base article'),
        icon: 'mobile-mention-kb',
        command: focused((c) => c.openKnowledgeBaseMention()),
      },
      {
        name: TextModuleMentionName,
        contentType: ['text/html', 'text/plain'],
        label: i18n.t('Insert text from text module'),
        icon: 'mobile-snippet',
        command: focused((c) => c.openTextMention()),
      },
    ]
  }

  const actions = computed(() => {
    return getActionsList().filter((action) => {
      if (disabledPlugins.includes(action.name)) {
        return false
      }
      return action.contentType.includes(contentType)
    })
  })

  return {
    focused,
    isActive,
    actions,
  }
}
