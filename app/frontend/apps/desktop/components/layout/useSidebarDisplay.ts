// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

export enum SidebarName {
  Primary = 'primary',
  TicketContent = 'ticket-content',
  TicketOverviews = 'ticket-overviews',
  PersonalSetting = 'personal-setting',
}

export const isSidebarCollapsed = {
  [SidebarName.Primary]: ref(false),
  [SidebarName.TicketContent]: ref(false),
  [SidebarName.TicketOverviews]: ref(false), // Are not collapsible
  [SidebarName.PersonalSetting]: ref(false), // Are not collapsible
}

export const useSidebarDisplay = (name: SidebarName) => {
  const toggleSidebar = (value?: boolean) => {
    isSidebarCollapsed[name].value = value ?? !isSidebarCollapsed[name].value
  }

  return {
    isSidebarCollapsed: computed(() => isSidebarCollapsed[name].value),
    toggleSidebar,
  }
}
