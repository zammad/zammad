// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

let editorColorMenuClasses = {
  colorSchemeList: {
    base: '',
    button: '',
    autoButton: '',
    autoButtonIcon: '',
  },
}

export const initializeEditorColorMenuClasses = (classes: typeof editorColorMenuClasses) => {
  editorColorMenuClasses = classes
}

export const getEditorColorMenuClasses = () => editorColorMenuClasses
