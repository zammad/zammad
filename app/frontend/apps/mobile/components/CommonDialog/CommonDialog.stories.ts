// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialog } from '@shared/composables/useDialog'
import type { Story } from '@storybook/vue3'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import CommonDialog from './CommonDialog.vue'

export default {
  title: 'dialog/CommonDialog',
  component: CommonDialog,
  argTypes: {
    label: { defaultValue: 'Hello, World!', type: { name: 'string' } },
    content: { defaultValue: 'I am dialog content', type: { name: 'string' } },
  },
}

interface StoryArgs {
  label?: string
  content?: string
}

const html = String.raw

const Dialog = async () => ({
  components: { CommonDialog },
  props: {
    label: { default: 'Hello, World' },
    content: { default: 'I am dialog content' },
  },
  template: html`
    <CommonDialog name="story" :label="label"> {{ content }} </CommonDialog>
  `,
})

const Template: Story<StoryArgs> = (args) => ({
  components: { DynamicInitializer },
  setup() {
    const dialog = useDialog({
      name: 'story',
      component: Dialog,
    })
    return { dialog, args }
  },
  template: html` <button @click="dialog.toggle(args)">Toggle Dialog</button> `,
})

export const Default = Template.bind({})
