// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'

import { useAlertFormHandler } from './useAlertFormHandler.ts'

export const useSSLVerificationWarningHandler = () =>
  useAlertFormHandler(
    'sslVerify',
    {
      key: 'sslVerificationWarning',
      value: i18n.t(
        'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
      ),
    },
    (field) => !field.props.disabled && field.props.value === false,
    (changedField, fields) =>
      !fields.sslVerify.props.disabled && changedField?.newValue === false,
    (node, addAlert, clearAlert) => {
      const { props, value } = node

      if (props.disabled) clearAlert()
      else if (value === false) addAlert()
    },
    'prop:disabled',
  )
