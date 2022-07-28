// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import useApplicationStore from '@shared/stores/application'
import CommonLogo from './CommonLogo.vue'

interface Args {
  isCustomLogo: boolean
}

export default {
  title: 'Shared/Logo',
  component: CommonLogo,
}

const Template: Story<Args> = (args: Args) => ({
  components: { CommonLogo },
  setup() {
    const application = useApplicationStore()
    if (args.isCustomLogo) {
      application.config.product_logo = 'icons/logotype.svg'
    } else {
      delete application.config.product_logo
    }
    return { args }
  },
  template: '<CommonLogo />',
})

export const DefaultLogo = Template.bind({})

export const CustomLogo = Template.bind({})
CustomLogo.args = {
  isCustomLogo: true,
}
