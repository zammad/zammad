<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// TODO doesn't work as expected
import { defineComponent, h, ref } from 'vue'
import { useViewTransition } from './composable'
import TransitionViewNavigation from './TransitionViewNavigation.vue'
import { ViewTransitions } from './types'

const FirstView = defineComponent(() => () => h('div', 'First View'))
const SecondView = defineComponent(() => () => h('div', 'Second View'))

const { setViewTransition } = useViewTransition()
const component = ref('first')
const transition = ref(ViewTransitions.Next)

const switchView = () => {
  setViewTransition(transition.value)
  component.value = 'second'
}

const resetView = () => {
  setViewTransition(ViewTransitions.Replace)
  component.value = 'first'
}
</script>

<template>
  <Story>
    <Variant title="Default">
      <template #controls>
        <HstSelect
          v-model="transition"
          title="Transition"
          :options="ViewTransitions"
        />
      </template>

      <button @click="switchView()">Switch View</button>

      <button @click="resetView()">Reset View</button>

      <TransitionViewNavigation>
        <component :is="component === 'first' ? FirstView : SecondView" />
        <!-- <FirstView v-if="component === 'first'" /> -->
        <!-- <SecondView v-else-if="component === 'second'" /> -->
      </TransitionViewNavigation>
    </Variant>
  </Story>
</template>
