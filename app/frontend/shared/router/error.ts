// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ErrorStatusCodes } from '#shared/types/error.ts'
import { ref } from 'vue'
import type { NavigationHookAfter, Router } from 'vue-router'

interface ErrorOptions {
  title: string
  message: string
  statusCode: ErrorStatusCodes
  messagePlaceholder?: string[]
  route?: string
}

const defaultOptions: ErrorOptions = {
  title: __('Not Found'),
  message: __("This page doesn't exist."),
  messagePlaceholder: [],
  statusCode: ErrorStatusCodes.NotFound,
}

export const errorOptions = ref<ErrorOptions>({ ...defaultOptions })

export const errorAfterGuard: NavigationHookAfter = (to) => {
  // we don't want to reset the error in case it was changed inside router hook
  // that way this hook will still fire, but we will keep changed options
  if (!to.query.redirect) {
    errorOptions.value = { ...defaultOptions }
  }
}

export const redirectToError = (
  router: Router,
  options: Partial<ErrorOptions> = {},
) => {
  errorOptions.value = {
    ...defaultOptions,
    ...options,
  }

  return router.replace({
    name: 'Error',
    query: {
      redirect: '1',
    },
  })
}
