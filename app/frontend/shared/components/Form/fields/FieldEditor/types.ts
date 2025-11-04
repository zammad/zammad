// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { PLUGIN_NAME as TEXT_TOOL_PLUGIN_NAME } from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
import type {
  KnowledgeBaseAnswerSuggestionsQuery,
  MentionSuggestionsQuery,
  TextModuleSuggestionsQuery,
} from '#shared/graphql/types.ts'
import type { ConfigList } from '#shared/types/config.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'
import type { ImageFileData } from '#shared/utils/files.ts'

import type { Except } from 'type-fest'
import type { Component } from 'vue'

export interface PossibleSignature {
  active?: boolean
  position?: number
  body: string
  id: number
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    signature: {
      addSignature: (
        signature: Omit<PossibleSignature, 'position'> & {
          position: string
          from: number
        },
      ) => ReturnType
      removeSignature: () => ReturnType
    }
    mentions: {
      openUserMention: () => ReturnType
      openTextMention: () => ReturnType
      openKnowledgeBaseMention: () => ReturnType
    }
    images: {
      setImages(images: ImageFileData[]): ReturnType
    }
    aiAssistantTextTools: {
      modifyTextWithAi: (textToolId: ID) => ReturnType
    }
    link: {
      toggleLink: (args: { href: string }) => ReturnType // command is set in the library extension
      openLinkForm: () => ReturnType
      closeLinkForm: () => ReturnType
    }
  }
}

export type MentionUserItem = ConfidentTake<MentionSuggestionsQuery, 'mentionSuggestions'>[number]

export type MentionKnowledgeBaseItem = ConfidentTake<
  KnowledgeBaseAnswerSuggestionsQuery,
  'knowledgeBaseAnswerSuggestions'
>[number]

export type MentionTextItem = ConfidentTake<
  TextModuleSuggestionsQuery,
  'textModuleSuggestions'
>[number]

export type MentionType = 'user' | 'knowledge-base' | 'text'
export type EditorContentType = 'text/html' | 'text/plain'

export interface FieldEditorContext {
  addSignature(signature: PossibleSignature): void
  removeSignature(): void
  focus(): void
  getEditorValue(type: EditorContentType): string
}

export interface FieldEditorProps {
  groupId?: string
  ticketId?: string
  customerId?: string
  organizationId?: string
  /**
   * @default 'text/html'
   */
  contentType?: EditorContentType
  /**
   * "meta" represents an object, where the key is a plugin, and the value is an object with plugin-specific options
   */
  meta?: {
    footer?: {
      disabled?: boolean
      text?: string
      maxlength?: number
      warningLength?: number
    }
    image?: {
      disabled?: boolean
    }
    mentionText?: {
      disabled?: boolean
      // where to get id for the current customer
      customerNodeName?: string
      // where to get id for the current group
      groupNodeName?: string
    }
    mentionKnowledgeBase?: {
      disabled?: boolean
      // where to put attachments from knowledge base, if any are available
      attachmentsNodeName?: string
    }
    mentionUser?: {
      disabled?: boolean
      // where to get groupId for user mention query
      groupNodeName?: string
    }
    [TEXT_TOOL_PLUGIN_NAME]?: {
      disabled?: boolean
      // where to get id for the current customer
      customerNodeName?: string
      // where to get id for the current organization
      organizationNodeName?: string
      // where to get id for the current group
      groupNodeName?: string
    }
  }
}

export type EditorCustomPlugins = keyof ConfidentTake<FieldEditorProps, 'meta'>

declare module '@tiptap/vue-3' {
  interface EditorEvents {
    'cancel-ai-assistant-text-tools-updates': void
    'toggle-visibility': {
      name: string
      active: boolean
    }
  }
}

declare module '@tiptap/core' {
  interface Storage {
    showAiTextLoader: boolean
  }
}

export interface EditorButton {
  id: string
  name: string
  /**
   * @type FieldEditorClass['actionBar']['button']['action']
   *
   * @info
   * use `getFieldEditorClasses()` to get the class for the action.
   * Define it in `initializeFieldEditorClasses()` invocation for the mobile/desktop field
   * */
  class?: string
  icon: string
  label?: string
  labelClass?: string
  contentType: EditorContentType[]
  attributes?: Record<string, unknown>
  command?: (e: MouseEvent) => void
  disabled?: boolean
  showDivider?: boolean
  dividerClass?: string
  permission?: string
  show?: (config: ConfigList) => boolean
  subMenu?: Component | Except<EditorButton, 'subMenu'>[]
}

export interface SetFloatingPopoverOptions {
  onClose?: () => void
}
