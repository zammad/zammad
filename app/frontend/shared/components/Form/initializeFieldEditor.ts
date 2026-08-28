// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type Component } from 'vue'

import type { FieldEditorClass } from './types.ts'

type EditorComponentMap = {
  [key: string]: Component | null
}

// Provide your own map with the following keys, the values given here are just examples.
let editorClasses: FieldEditorClass = {
  actionBar: {
    tableMenuContainer: '',
    tableMenuGrid: '',
    button: {
      base: '',
    },
  },
  input: {
    container: '',
    inlineContainer: '',
  },
  tableMenu: {
    triggerButton: '',
  },
}

let editorComponents: EditorComponentMap = {
  actionBar: null,
  actionMenu: null,
  suggestionList: null,
  // The knowledge base answer flavour of the link form. It is built on an autocomplete field only
  //   the desktop app has, so the shared link extension reaches it through here.
  knowledgeBaseAnswerLinkForm: null,
}

export const initializeFieldEditorClasses = (classes: FieldEditorClass) => {
  editorClasses = classes
}

export const getFieldEditorClasses = () => editorClasses

export const initializeEditorComponents = (components: EditorComponentMap) => {
  editorComponents = components
}

export const getEditorComponents = () => editorComponents
