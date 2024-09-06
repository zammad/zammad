// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormGroupClassMap } from './types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let formGroupClasses: FormGroupClassMap = {
  container: 'form-group',
  help: 'form-group-help',
  dirtyMark: 'form-group-mark-dirty',
  bottomMargin: 'form-group-bottom-margin',
}

export const initializeFormGroupClasses = (classes: FormGroupClassMap) => {
  formGroupClasses = classes
}

export const getFormGroupClasses = () => formGroupClasses
