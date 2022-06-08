// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import LayoutHeader, { type Props } from './LayoutHeader.vue'

export default {
  title: 'layout/LayoutHeader',
  component: LayoutHeader,
}

const Template = createTemplate<Props>(LayoutHeader)

export const Default = Template.create({
  title: 'Custom Title',
})

export const WithBackButton = Template.create({
  title: 'Custom Title',
  backTitle: 'Back',
  backUrl: '/',
})

export const WithAction = Template.create({
  title: 'Custom Title',
  actionTitle: 'Action',
  onAction() {
    // eslint-disable-next-line no-alert
    alert('Hello, World!')
  },
})

export const FullHeader = Template.create({
  title: 'Custom Title',
  actionTitle: 'Action',
  onAction() {
    // eslint-disable-next-line no-alert
    alert('Hello, World!')
  },
  backTitle: 'Back',
  backUrl: '/',
})
