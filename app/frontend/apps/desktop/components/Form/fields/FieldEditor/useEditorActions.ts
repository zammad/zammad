// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, onUnmounted, toRef } from 'vue'

import useEditorActionHelper from '#shared/components/Form/fields/FieldEditor/composables/useEditorActionHelper.ts'
import { EXTENSION_NAME as AiAssistanceTextToolsName } from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
import { EXTENSION_NAME as KnowledgeBaseMentionName } from '#shared/components/Form/fields/FieldEditor/extensions/KnowledgeBaseSuggestion.ts'
import { TableKitExtensionName } from '#shared/components/Form/fields/FieldEditor/extensions/TableKit.ts'
import { EXTENSION_NAME as TextModuleMentionName } from '#shared/components/Form/fields/FieldEditor/extensions/TextModuleSuggestion.ts'
import { EXTENSION_NAME as UserMentionName } from '#shared/components/Form/fields/FieldEditor/extensions/UserMention.ts'
import AiAssistantTextTools from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantTextTools/AiAssistantTextTools.vue'
import EditorColorMenu from '#shared/components/Form/fields/FieldEditor/features/color-picker/EditorColorMenu.vue'
import type {
  EditorButton,
  EditorContentType,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertInlineImages } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import getUuid from '#shared/utils/getUuid.ts'
import testFlags from '#shared/utils/testFlags.ts'

import type { Editor } from '@tiptap/vue-3'
import type { ShallowRef } from 'vue'

export default function useEditorActions(
  editor: ShallowRef<Editor | undefined>,
  contentType: EditorContentType,
  disabledExtensions: string[] = [],
) {
  const { focused, isActive } = useEditorActionHelper(editor)

  // this is primarily used by cypress tests, where it requires an actual input in the DOM tree
  let fileInput: HTMLInputElement | null = null

  const getInputForImage = () => {
    if (fileInput) return fileInput

    fileInput = document.createElement('input')
    fileInput.type = 'file'
    fileInput.multiple = true
    fileInput.accept = 'image/*'
    fileInput.style.display = 'none'
    if (import.meta.env.DEV || VITE_TEST_MODE) {
      fileInput.dataset.testId = 'editor-image-input'
    }
    document.body.appendChild(fileInput)

    return fileInput
  }

  onUnmounted(() => {
    fileInput?.remove()
    fileInput = null
  })

  const applicationConfig = toRef(useApplicationStore(), 'config')
  const { hasPermission } = useSessionStore()

  const { localeData } = useLocaleStore()

  const getActionsList = (): EditorButton[] => [
    {
      id: getUuid(),
      name: AiAssistanceTextToolsName,
      contentType: ['text/html', 'text/plain'],
      label: __('AI writing assistant tools'),
      showDivider: true,
      dividerClass:
        'bg-linear-to-t from-pink-200 to-blue-800 [button[aria-expanded=true]+&]:animate-ai-stripe-vertical [button:hover+&]:animate-ai-stripe-vertical [button:focus-visible+&]:animate-ai-stripe-vertical',
      permission: 'ticket.agent',
      show: (config) => !!(config?.ai_assistance_text_tools && config.ai_provider),
      icon: 'smart-assist-elaborate',
      subMenu: AiAssistantTextTools,
    },
    {
      id: getUuid(),
      name: UserMentionName,
      contentType: ['text/html'],
      label: __('Mention user'),
      icon: 'editor-mention-user',
      command: focused((c) => c.openUserMention()),
      permission: 'ticket.agent',
    },
    {
      id: getUuid(),
      name: KnowledgeBaseMentionName,
      contentType: ['text/html', 'text/plain'],
      label: __('Insert text from knowledge base answer'),
      icon: 'editor-mention-knowledge-base',
      command: focused((c) => c.openKnowledgeBaseMention()),
      permission: 'ticket.agent',
    },
    {
      id: getUuid(),
      name: TextModuleMentionName,
      contentType: ['text/html', 'text/plain'],
      label: __('Insert text from text module'),
      showDivider: true,
      icon: 'editor-mention-text-module',
      command: focused((c) => c.openTextMention()),
      permission: 'ticket.agent',
    },
    {
      id: getUuid(),
      name: 'heading',
      contentType: ['text/html'],
      label: __('Add heading'),
      icon: 'text-style-h',
      subMenu: [
        {
          id: getUuid(),
          name: 'heading',
          contentType: ['text/html'],
          label: __('Heading 1'),
          labelClass: 'text-xl! font-bold',
          icon: 'text-style-h1',
          attributes: {
            level: 1,
          },
          command: focused((c) => c.toggleHeading({ level: 1 })),
        },
        {
          id: getUuid(),
          name: 'heading',
          contentType: ['text/html'],
          label: __('Heading 2'),
          labelClass: 'text-base! font-bold',
          icon: 'text-style-h2',
          attributes: {
            level: 2,
          },
          command: focused((c) => c.toggleHeading({ level: 2 })),
        },
        {
          id: getUuid(),
          name: 'heading',
          contentType: ['text/html'],
          label: __('Heading 3'),
          labelClass: 'text-sm! font-bold',
          icon: 'text-style-h3',
          attributes: {
            level: 3,
          },
          command: focused((c) => c.toggleHeading({ level: 3 })),
        },
      ],
    },
    {
      id: `action-${getUuid()}`,
      name: 'bold',
      contentType: ['text/html'],
      label: __('Format as bold'),
      icon: 'text-style-bold',
      command: focused((c) => c.toggleBold()),
    },
    {
      id: getUuid(),
      name: 'italic',
      contentType: ['text/html'],
      label: __('Format as italic'),
      icon: 'text-style-italic',
      command: focused((c) => c.toggleItalic()),
    },
    {
      id: getUuid(),
      name: 'underline',
      contentType: ['text/html'],
      label: __('Format as underlined'),
      icon: 'text-style-underline',
      command: focused((c) => c.toggleUnderline()),
    },
    {
      id: getUuid(),
      name: 'strike',
      contentType: ['text/html'],
      label: __('Format as strikethrough'),
      icon: 'text-style-strikethrough',
      command: focused((c) => c.toggleStrike()),
    },
    {
      id: getUuid(),
      name: 'textColor',
      contentType: ['text/html'],
      label: __('Change text color'),
      icon: 'editor-text-color',
      subMenu: EditorColorMenu,
    },
    {
      id: getUuid(),
      name: 'blockquote',
      contentType: ['text/html'],
      label: __('Format as quoted text'),
      icon: 'quote',
      command: focused((c) => c.toggleBlockquote()),
    },
    {
      id: getUuid(),
      name: 'removeFormatting',
      contentType: ['text/html'],
      label: __('Remove formatting'),
      icon: 'editor-remove-formatting',
      command: focused((c) => c.clearNodes().unsetAllMarks()),
    },
    {
      id: getUuid(),
      name: 'code',
      contentType: ['text/html'],
      label: __('Insert inline code'),
      icon:
        editor.value?.isActive('code') && !editor.value?.isActive('codeBlock')
          ? 'editor-code-slash'
          : 'editor-code',
      command: focused((c) => c.toggleCode()),
    },
    {
      id: getUuid(),
      name: 'codeBlock',
      contentType: ['text/html'],
      label: __('Insert code block'),
      icon: 'editor-code-block',
      command: focused((c) => c.toggleCodeBlock()),
    },
    {
      id: getUuid(),
      name: 'horizontalRule',
      contentType: ['text/html'],
      label: __('Insert divider'),
      showDivider: true,
      icon: 'editor-insert-divider',
      command: focused((c) => c.setHorizontalRule()),
    },
    {
      id: getUuid(),
      name: 'orderedList',
      contentType: ['text/html'],
      label: __('Add ordered list'),
      icon: 'editor-ordered-list',
      command: focused((c) => {
        if (isActive('orderedList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleOrderedList()
      }),
    },
    {
      id: getUuid(),
      name: 'bulletList',
      contentType: ['text/html'],
      label: __('Add bullet list'),
      icon: 'editor-bullet-list',
      command: focused((c) => {
        if (isActive('bulletList')) {
          return c.liftListItem('listItem')
        }
        return c.toggleBulletList()
      }),
    },
    {
      id: getUuid(),
      name: 'indent',
      contentType: ['text/html'],
      label: __('Indent text'),
      icon: localeData?.dir === 'ltr' ? 'editor-indent-left' : 'editor-indent-right',
      command: focused((c) => c.increaseIndent()),
    },
    {
      id: getUuid(),
      name: 'outdent',
      contentType: ['text/html'],
      label: __('Outdent text'),
      showDivider: true,
      icon: localeData?.dir === 'ltr' ? 'editor-indent-right' : 'editor-indent-left',
      command: focused((c) => c.decreaseIndent()),
    },
    {
      id: getUuid(),
      name: 'image',
      contentType: ['text/html'],
      label: __('Add image'),
      icon: 'editor-inline-image',
      command: focused((c) => {
        const input = getInputForImage()
        input.onchange = async () => {
          if (!input.files?.length || !editor.value) return
          const files = await convertInlineImages(input.files, editor.value.view.dom)

          c.setImages(files).run()
          input.value = ''
          nextTick(() => testFlags.set('editor.inlineImagesAdded'))
        }
        if (!VITE_TEST_MODE || import.meta.env.DEV) input.click()
      }),
    },
    {
      id: getUuid(),
      name: 'link',
      contentType: ['text/html'],
      label: __('Add link'),
      icon: 'editor-inline-link',
      command: focused((c) => c.openLinkForm()),
    },
    {
      id: getUuid(),
      name: TableKitExtensionName,
      contentType: ['text/html'],
      label: __('Insert table'),
      icon: 'editor-table',
      command: () => {
        editor.value?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()

        const end = editor.value?.state.doc.content.size ?? 0
        editor.value?.chain().focus().insertContentAt(end, '<p></p>').run()
      },
    },
  ]

  const actions = computed(() =>
    getActionsList().filter((action) => {
      if (disabledExtensions.includes(action.name)) return false

      if (action.show && !action.show(applicationConfig.value)) return false

      if (action.permission && !hasPermission(action.permission)) return false

      return action.contentType.includes(contentType)
    }),
  )

  return {
    actions,
  }
}
