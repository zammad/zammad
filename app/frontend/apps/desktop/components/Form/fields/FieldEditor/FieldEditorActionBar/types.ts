// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'

export interface ExtendedEditorButton extends EditorButton {
  key: string
  noCloseOnClick: boolean
}
