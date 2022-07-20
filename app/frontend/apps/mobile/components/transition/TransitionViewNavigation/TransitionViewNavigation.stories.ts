// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable vue/one-component-per-file */

import type { Story } from '@storybook/vue3'
import TransitionViewNavigation from '@mobile/components/transition/TransitionViewNavigation/TransitionViewNavigation.vue'
import {
  useViewTransition,
  ViewTransitions,
} from '@mobile/components/transition/TransitionViewNavigation'
import { defineComponent, markRaw, ref } from 'vue'

interface Args {
  newViewTransition: ViewTransitions
}

const { setViewTransition } = useViewTransition()

const FirstView = markRaw(
  defineComponent({
    template: '<div>First View</div>',
  }),
)

const SecondView = markRaw(
  defineComponent({
    template: '<div>Second View</div>',
  }),
)

export default {
  title: 'Apps/Mobile/Transition/ViewNavigation',
  component: TransitionViewNavigation,
}

const Template: Story<Args> = (args: Args) => ({
  components: { TransitionViewNavigation },
  setup() {
    const component = ref(FirstView)

    const switchView = () => {
      setViewTransition(args.newViewTransition)
      component.value = SecondView
    }

    const resetView = () => {
      setViewTransition(ViewTransitions.Replace)
      component.value = FirstView
    }

    return { args, switchView, resetView, component }
  },
  template: `<button class="bg-white hover:bg-gray-300 text-gray-800 py-2 px-4 border border-gray-600 rounded text-sm mr-5" v-on:click="switchView()">Switch View</button>
    <button class="bg-white hover:bg-gray-300 text-gray-600 py-2 px-4 border border-gray-600 rounded text-sm mb-10" v-on:click="resetView()">Reset View</button>
    <TransitionViewNavigation> <component :is="component" /></TransitionViewNavigation>
    `,
})

export const NextViewTransition = Template.bind({})
NextViewTransition.args = { newViewTransition: ViewTransitions.Next }

export const PrevViewTransition = Template.bind({})
PrevViewTransition.args = { newViewTransition: ViewTransitions.Prev }

export const ReplaceViewTransition = Template.bind({})
ReplaceViewTransition.args = { newViewTransition: ViewTransitions.Replace }
