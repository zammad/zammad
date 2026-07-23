<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onBeforeMount, watch } from 'vue'
import { useRouter } from 'vue-router'

import CommonImageViewer from '#shared/components/CommonImageViewer/CommonImageViewer.vue'
import CommonNotifications from '#shared/components/CommonNotifications/CommonNotifications.vue'
import DynamicInitializer from '#shared/components/DynamicInitializer/DynamicInitializer.vue'
import useAuthenticationChanges from '#shared/composables/authentication/useAuthenticationUpdates.ts'
import useFormKitConfig from '#shared/composables/form/useFormKitConfig.ts'
import useAppMaintenanceCheck from '#shared/composables/useAppMaintenanceCheck.ts'
import useMetaTitle from '#shared/composables/useMetaTitle.ts'
import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import usePushMessages from '#shared/composables/usePushMessages.ts'
import { initializeDefaultObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useBetaUiDisclaimer } from '#desktop/components/BetaUi/composables/useBetaUiDisclaimer.ts'
import {
  useBetaUiFeedbackConsent,
  initializeBetaUiFeedbackConsentDialog,
} from '#desktop/components/BetaUi/composables/useBetaUiFeedbackConsent.ts'
import { initializeConfirmationDialog } from '#desktop/components/CommonConfirmationDialog/initializeConfirmationDialog.ts'
import { useConnection } from '#desktop/composables/useConnection.ts'
import { useTicketOverviewsStore } from '#desktop/entities/ticket/stores/ticketOverviews.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'
import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

import { useBetaUi } from './components/BetaUi/composables/useBetaUi.ts'
import { useBetaUiFeedbackRouteGuard } from './components/BetaUi/composables/useBetaUiFeedbackRouteGuard.ts'
import { useMobileDetection } from './composables/responsiveness/useMobileDetection.ts'
import { useKnowledgeBaseAccess } from './entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from './entities/knowledge-base/stores/knowledgeBase.ts'

const router = useRouter()

const authentication = useAuthenticationStore()
const session = useSessionStore()

useMetaTitle().initializeMetaTitle()

const application = useApplicationStore()

const { canBrowse: canBrowseKnowledgeBase } = useKnowledgeBaseAccess()

onBeforeMount(() => {
  application.setLoaded()
})

useAppMaintenanceCheck()
usePushMessages()

// Add a check for authenticated changes (e.g. login/logout in a other
// browser tab or maintenance mode switch).
useAuthenticationChanges()

// TODO: Remove when desktop view is stable.
const { switchValue } = useBetaUi()

// Shows the feedback consent for the BETA usage of the desktop view.
//  The user has by this point enrolled into the BETA program.

initializeBetaUiFeedbackConsentDialog() // Calling it within the check also doesn't pick up the setup scope 😱

if (switchValue.value) {
  useBetaUiFeedbackConsent()
  useBetaUiFeedbackRouteGuard()
}

// Shows the warning for the BETA usage of the desktop view.
//   The user has not yet enrolled into the BETA program.
else {
  useBetaUiDisclaimer()
}

// We need to trigger a manual translation update for the form related strings.
const formConfig = useFormKitConfig()
useLocaleStore().$subscribe(() => {
  formConfig.locale = 'staticLocale'
})

// The handling for invalid sessions. The event will be emitted, when from the server a "NotAuthorized"
// response is received.
useOnEmitter('session-invalid', async () => {
  if (authentication.authenticated) {
    await authentication.clearAuthentication()

    router.replace({
      name: 'Login',
      query: {
        invalidatedSession: '1',
      },
    })
  }
})

initializeConfirmationDialog()

// Initialize the user taskbar tabs store after a valid session is present on
// the app level, so that the query keeps alive.
watch(
  () => session.initialized,
  (newValue, oldValue) => {
    if (!newValue || oldValue) return

    useUserCurrentTaskbarTabsStore()
    useTicketOverviewsStore()
    initializeDefaultObjectAttributes()
    useAppUsageStore()
    useTicketBulkUpdateStore()
    useMobileDetection()

    // Preload the knowledge base base query so entering the section resolves
    //   its default locale instantly — but only when there is a knowledge base
    //   this user can actually browse. Defer until the initial route is
    //   resolved so the store reads the real locale from the URL instead of
    //   firing against the still-unresolved start location on a full reload.
    if (canBrowseKnowledgeBase.value) {
      router.isReady().then(() => useKnowledgeBaseStore())
    }
  },
  { immediate: true },
)

useConnection()
</script>

<template>
  <template v-if="application.loaded">
    <CommonNotifications />
    <Teleport to="body">
      <CommonImageViewer />
    </Teleport>
    <RouterView />

    <DynamicInitializer name="dialog" />
    <DynamicInitializer name="flyout" />
  </template>
</template>
