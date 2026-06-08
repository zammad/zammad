// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { inject, type InjectionKey, provide } from 'vue'

import type { FieldEditorOptions } from '#desktop/components/Form/fields/FieldEditor/types.ts'

export const FIELD_EDITOR_OPTIONS = Symbol(
  'field-editor-options',
) as InjectionKey<FieldEditorOptions>

export const provideFieldEditorOptions = (options: FieldEditorOptions) =>
  provide(FIELD_EDITOR_OPTIONS, options)

export const useFieldEditorOptions = () => inject(FIELD_EDITOR_OPTIONS, { zIndex: '20' })
