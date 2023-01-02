// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'
import { nextTick, reactive } from 'vue'

import type { DestroyComponentData, PushComponentData } from './types'

export enum Events {
  Push = 'dynamic-component.push',
  Destroy = 'dynamic-component.destroy',
}

const createEvent = <T = PushComponentData | DestroyComponentData>(
  title: string,
  detail: T,
) => {
  return new CustomEvent<T>(title, { detail })
}

export const pushComponent = async (
  name: string,
  id: string,
  cmp: Component,
  props = {},
) => {
  const event = createEvent(Events.Push, {
    name,
    id,
    cmp,
    props: reactive(props),
  })

  window.dispatchEvent(event)

  await nextTick()
}

// if no id is passed down, destroys all named components
export const destroyComponent = async (name: string, id?: string) => {
  const event = createEvent(Events.Destroy, { name, id })

  window.dispatchEvent(event)

  await nextTick()
}
