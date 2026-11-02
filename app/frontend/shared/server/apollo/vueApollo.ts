// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useMutation as useMutationInScope } from '@vue/apollo-composable/compat'
import { effectScope, getCurrentScope } from 'vue'

export * from '@vue/apollo-composable/compat'

// Mutations are sent on demand - from event handlers, store actions and
//  plugins - where no effect scope is active. vue-apollo tracks their loading
//  state with `onScopeDispose`, which warns without a scope and, given one,
//  holds that scope in a module-level map until it is stopped. Setting the
//  mutation up is all it is needed for, so stop it right away: `mutate` and
//  the returned refs work on without it. Queries and subscriptions get none,
//  they outlive their call and stay with the scope of their caller.
const inOwnedScope = <TComposable extends (...args: never[]) => unknown>(
  composable: TComposable,
): TComposable =>
  ((...args: never[]) => {
    if (getCurrentScope()) return composable(...args)

    const scope = effectScope(true)

    try {
      return scope.run(() => composable(...args))
    } finally {
      scope.stop()
    }
  }) as TComposable

export const useMutation = inOwnedScope(useMutationInScope)
