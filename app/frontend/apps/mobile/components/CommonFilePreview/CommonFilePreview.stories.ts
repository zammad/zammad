// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import CommonFilePreview, { type Props } from './CommonFilePreview.vue'

export default {
  title: 'Apps/Mobile/CommonFilePreview',
  component: CommonFilePreview,
}

const Template = createTemplate<Props>(CommonFilePreview)

export const Default = Template.create({
  file: {
    name: 'test file.txt',
    type: 'text/plain',
    size: 12343,
  },
  downloadUrl: '/',
})
