// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLogo from '@common/components/common/CommonLogo.vue'
import useApplicationConfigStore from '@common/stores/application/config'
import { Story } from '@storybook/vue3'

export default {
  title: 'Common/Logo',
  component: CommonLogo,
}

const Template: Story = (args) => ({
  components: { CommonLogo },
  setup() {
    const configStore = useApplicationConfigStore()
    if (args.isCustomLogo) {
      configStore.value.product_logo = 'icons/logotype.svg'
    } else {
      configStore.value.product_logo = undefined
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
