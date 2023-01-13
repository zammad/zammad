// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '@shared/components/Form'
import type { FieldEditorProps } from '@shared/components/Form/fields/FieldEditor/types'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import type { getTicketView } from '@shared/entities/ticket/utils/getTicketView'
import type { AppName, AppSpecificRecord } from '@shared/types/app'
import type { ConfigList } from '@shared/types/store'

interface TicketArticlePerformOptions {
  selection?: Range
}

export interface CommonTicketActionAddOptions {
  view: ReturnType<typeof getTicketView>
  config: ConfigList
  recalculate: () => void
  onDispose(callback: () => unknown): void
}

export type TicketViewPolicy = 'change' | 'read'
export type TicketViewPolicyMap = {
  agent?: TicketViewPolicy[]
  customer?: TicketViewPolicy[]
}

export interface TicketArticleAction {
  apps: AppName[]
  label: string // "name" in desktop view
  name: string // "type" in desktop view, but clashes with ArticleType
  icon: AppSpecificRecord<string>
  view: TicketViewPolicyMap
  link?: string // do we need it(?)

  perform?(
    ticket: TicketById,
    article: TicketArticle,
    options: TicketArticlePerformOptions,
  ): void
}

export interface TicketArticleType {
  apps: AppName[]
  name: string
  icon: AppSpecificRecord<string>
  label: string
  attributes: string[]
  internal: boolean
  view: TicketViewPolicyMap
  // TODO: to disable some features, need extensions to allow "plain text" in a different issue
  editorMeta?: FieldEditorProps['meta']
  // when clicked on type, and type is not selected
  onSelected?(ticket: TicketById): void
  // when clicked on other type, but this one is selected
  onDeselected?(ticket: TicketById): void
  // TODO use actual type instead of FormValues
  updateForm?(ticket: TicketById, formValues: FormValues): FormValues
}

// inspired by tiptap plugins config
export interface TicketArticleActionPlugin {
  order: number

  addActions?(
    ticket: TicketById,
    article: TicketArticle,
    options: CommonTicketActionAddOptions,
  ): TicketArticleAction[]
  addTypes?(
    ticket: TicketById,
    options: CommonTicketActionAddOptions,
  ): TicketArticleType[]
}
