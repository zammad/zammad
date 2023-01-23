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

export interface CommonTicketAddOptions {
  view: ReturnType<typeof getTicketView>
  config: ConfigList
}

export interface TicketActionAddOptions extends CommonTicketAddOptions {
  recalculate: () => void
  onDispose(callback: () => unknown): void
}

export type TicketTypeAddOptions = CommonTicketAddOptions

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

export interface AppSpecificTicketArticleType {
  value: string
  icon: string
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

export interface TicketArticleType
  extends Omit<AppSpecificTicketArticleType, 'icon'> {
  apps: AppName[]
  icon: AppSpecificRecord<string>
}

// inspired by tiptap plugins config
export interface TicketArticleActionPlugin {
  order: number

  addActions?(
    ticket: TicketById,
    article: TicketArticle,
    options: TicketActionAddOptions,
  ): TicketArticleAction[]
  addTypes?(
    ticket: TicketById,
    options: TicketTypeAddOptions,
  ): TicketArticleType[]
}
