// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isFuture, parseISO } from 'date-fns'

import { i18n } from '#shared/i18n.ts'

import { useAlertFormHandler } from './useAlertFormHandler.ts'

export const useArchiveBeforeWarningHandler = () =>
  useAlertFormHandler(
    'archive_before',
    {
      key: 'archiveBeforeWarning',
      value: i18n.t(
        'You have selected a cut-off time in the future. Be aware that all emails (including future ones) are going to be archived until the selected time is reached.',
      ),
    },
    (field, fields) =>
      Boolean(
        fields.archive.props.value &&
          field.props.value &&
          isFuture(parseISO(field.props.value as string)),
      ),
    (changedField, fields) =>
      Boolean(
        fields.archive.props.value &&
          changedField?.name === 'archive_before' &&
          changedField.newValue &&
          isFuture(parseISO(changedField.newValue as string)),
      ),
    (node, addAlert, clearAlert) => {
      const { value } = node

      if (value && isFuture(parseISO(value as string))) addAlert()
      else clearAlert()
    },
  )
