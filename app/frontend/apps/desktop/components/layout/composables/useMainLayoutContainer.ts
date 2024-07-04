// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ComputedRef, type InjectionKey, inject } from 'vue'

/*
 * Injection key for the main content container in LayoutMain
 * */
export const MAIN_LAYOUT_KEY = Symbol('main-content-container') as InjectionKey<
  ComputedRef<HTMLElement | undefined>
>

export const useMainLayoutContainer = () => {
  return {
    node: inject(MAIN_LAYOUT_KEY),
  }
}
