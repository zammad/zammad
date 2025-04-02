// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Calendar'),
  category: {
    label: __('Tickets'),
    id: 'category-tickets',
    order: 3000,
  },
  route: {
    path: 'calendar-subscriptions',
    alias: '/profile/calendar_subscriptions',
    name: 'PersonalSettingCalendar',
    component: () => import('../../PersonalSettingCalendar.vue'),
    level: 2,
    meta: {
      title: __('Calendar'),
      requiresAuth: true,
      requiredPermission: ['user_preferences.calendar+ticket.agent'],
    },
  },
  order: 3000,
  keywords: __('subscription,calendars,ticket,ical'),
}
