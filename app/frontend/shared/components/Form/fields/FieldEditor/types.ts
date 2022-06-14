// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { ImageFileData } from '@shared/utils/files'

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
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

export interface CommandUserProps {
  id: string
  href: string
  title: string
}

export interface CommandKnowledgeBaseProps {
  content: string
}

export interface CommandTextProps {
  content: string
}

export interface MentionUserItem {
  firstname?: string
  lastname?: string
  email?: string
  id: string
}

export interface MentionKnowledgeBaseItem {
  id: string
  title: string
  content: string
  category: string
}

export interface MentionTextItem {
  title: string
  keyword: string
  content: string
  id: string
}

export type MentionType = 'user' | 'knowledge-base' | 'text'
