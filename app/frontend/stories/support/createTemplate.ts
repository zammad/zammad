// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Component } from 'vue'

interface StoryTemplate<Props> {
  (args: Props): Component
  args?: Props
}

export default function createTemplate<Props>(StoryComponent: Component) {
  const fn = (args: Props) => ({
    components: { StoryComponent },
    setup() {
      return { args }
    },
    template: '<StoryComponent v-bind="args"/>',
  })

  fn.create = (args?: Props): StoryTemplate<Props> => {
    const cloned = fn.bind({}) as StoryTemplate<Props>
    if (args) {
      cloned.args = args
    }
    return cloned
  }

  return fn
}
