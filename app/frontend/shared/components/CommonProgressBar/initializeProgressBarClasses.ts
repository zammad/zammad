// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

let progressBarClasses = ''

export const initializeProgressBarClasses = (classes: string) => {
  progressBarClasses = classes
}

export const getProgressBarClasses = () => progressBarClasses
