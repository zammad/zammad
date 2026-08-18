// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AlertClassMap } from '#shared/components/CommonAlert/types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let alertClasses: AlertClassMap = {
  base: 'common-alert',
  danger: 'common-alert-danger',
  info: 'common-alert-info',
  success: 'common-alert-success',
  warning: 'common-alert-warning',
  dismissButton: '',
  translucent: {
    danger: 'common-alert-danger-translucent',
    info: 'common-alert-info-translucent',
    success: 'common-alert-success-translucent',
    warning: 'common-alert-warning-translucent',
  },
}

export const initializeAlertClasses = (classes: AlertClassMap) => {
  alertClasses = classes
}

export const getAlertClasses = () => alertClasses
