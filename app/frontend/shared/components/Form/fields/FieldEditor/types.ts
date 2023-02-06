// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  KnowledgeBaseAnswerSuggestionsQuery,
  MentionSuggestionsQuery,
  TextModuleSuggestionsQuery,
} from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import type { ImageFileData } from '@shared/utils/files'

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
  }
}

export type MentionUserItem = ConfidentTake<
  MentionSuggestionsQuery,
  'mentionSuggestions'
>[number]

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
      // where to get id for the current ticket
      ticketNodeId?: string
      // where to get id for the current customer
      customerNodeId?: string
    }
    mentionKnowledgeBase?: {
      disabled?: boolean
      // where to put attachments from knowledge base, if any are available
      attachmentsNodeId?: string
    }
    mentionUser?: {
      disabled?: boolean
      // where to get groupId for user mention query
      groupNodeId?: string
    }
  }
}

export type EditorCustomPlugins = keyof ConfidentTake<FieldEditorProps, 'meta'>
