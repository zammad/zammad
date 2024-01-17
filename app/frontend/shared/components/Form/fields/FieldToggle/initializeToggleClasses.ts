// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ToggleClassMap } from './types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let toggleClasses: ToggleClassMap = {
  track: 'field-toggle-track',
  trackOn: 'field-toggle-track--on',
  knob: 'field-toggle-knob',
}

export const initializeToggleClasses = (classes: ToggleClassMap) => {
  toggleClasses = classes
}

export const getToggleClasses = () => toggleClasses
