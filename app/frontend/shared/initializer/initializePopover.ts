// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// Classes
let popoverClasses = {
  base: '',
  arrow: '',
}

export const initializePopoverClasses = (classes: typeof popoverClasses) => {
  popoverClasses = classes
}
export const getPopoverClasses = () => popoverClasses
