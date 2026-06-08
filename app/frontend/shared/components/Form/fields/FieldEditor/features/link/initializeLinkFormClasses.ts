// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

let editorLinkFormClasses = {
  button: {
    danger: '',
    secondary: '',
    primary: '',
  },
  buttonContainer: '',
  form: '',
}

export const initializeEditorLinkFormClasses = (classes: typeof editorLinkFormClasses) => {
  editorLinkFormClasses = classes
}

export const getEditorEditorLinkFormClasses = () => editorLinkFormClasses
