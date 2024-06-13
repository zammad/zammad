// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldEditorClass, FieldEditorProps } from './types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let editorClasses: FieldEditorClass = {
  actionBar: {
    buttonContainer: '',
    tableMenuContainer: '',
    leftGradient: {
      left: '',
      before: {
        background: {
          light: '',
          dark: '',
        },
      },
    },
    rightGradient: {
      before: {
        background: {
          light: '',
          dark: '',
        },
      },
    },
    shadowGradient: {
      before: {
        top: '',
        height: '',
      },
    },
    button: {
      base: '',
      active: '',
    },
  },
  input: {
    container: '',
  },
}

export const initializeFieldEditorClasses = (classes: FieldEditorClass) => {
  editorClasses = classes
}

export const getFieldEditorClasses = () => editorClasses

let editorProps: FieldEditorProps = {
  actionBar: {
    button: {
      icon: {
        size: 'small',
      },
    },
  },
}

export const initializeFieldEditorProps = (props: FieldEditorProps) => {
  editorProps = props
}

export const getFieldEditorProps = () => editorProps
