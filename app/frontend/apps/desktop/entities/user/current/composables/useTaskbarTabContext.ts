// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, type ComputedRef, type Ref } from 'vue'

import type { TaskbarTabContext } from '../types.ts'

// The taskbar tab renders itself from its context, so the context must not change identity on
//   every keystroke: an equal context keeps the previous object.
//
// `isSettled` is for a context fed by a form - until the form has answered, its values are not
//   the ones of the tab, and reporting them would make an untouched tab look edited.
export const useTaskbarTabContext = (
  buildContext: () => TaskbarTabContext,
  isSettled?: Ref<boolean>,
): ComputedRef<TaskbarTabContext> =>
  computed((currentContext) => {
    if (isSettled && !isSettled.value) return {}

    const newContext = buildContext()

    if (currentContext && isEqual(newContext, currentContext)) return currentContext

    return newContext
  })
