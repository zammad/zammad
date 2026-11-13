// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Allowlist of .graphql documents whose generated composables use the native
// @vue/apollo-composable v5 shape; every document not listed keeps the compat
// (v4 three-argument) shape until its call sites are migrated.
//
// Policy: a document added while this allowlist exists goes on it from the
// start. Fragment-only documents never go on it — both generators emit
// identical bytes for them.

const fs = require('fs')
const path = require('path')

// Repo-relative POSIX paths, one per line.
const vueApolloV5Documents = new Set([
  'app/frontend/apps/mobile/entities/ticket/graphql/queries/overviewOrder.graphql',
  'app/frontend/apps/mobile/entities/ticket/graphql/queries/overviewTicketCount.graphql',
  'app/frontend/apps/mobile/entities/ticket/graphql/queries/overviews.graphql',
  'app/frontend/apps/mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.graphql',
  'app/frontend/apps/mobile/entities/ticket/graphql/subscriptions/ticketOverviewUpdates.graphql',
  'app/frontend/apps/mobile/pages/account/graphql/queries/userCurrentAvatarActive.graphql',
  'app/frontend/apps/mobile/pages/search/graphql/queries/searchOverview.graphql',
  'app/frontend/apps/mobile/pages/ticket/graphql/mutations/live-user/delete.graphql',
  'app/frontend/apps/mobile/pages/ticket/graphql/mutations/live-user/ticketLiveUserUpsert.graphql',
  'app/frontend/apps/mobile/pages/ticket/graphql/queries/ticketsByOverviewSlim.graphql',
  'app/frontend/shared/graphql/queries/about.graphql',
  'app/frontend/shared/graphql/queries/applicationConfig.graphql',
  'app/frontend/shared/graphql/queries/locales.graphql',
  'app/frontend/shared/graphql/queries/translations.graphql',
  'app/frontend/shared/graphql/queries/session.graphql',
  'app/frontend/shared/graphql/queries/currentUser.graphql',
  'app/frontend/shared/graphql/queries/applicationBuildChecksum.graphql',
  'app/frontend/shared/graphql/queries/macros.graphql',
  'app/frontend/shared/graphql/mutations/login.graphql',
  'app/frontend/shared/graphql/mutations/logout.graphql',
  'app/frontend/shared/graphql/mutations/twoFactorMethodInitiateAuthentication.graphql',
  'app/frontend/shared/graphql/subscriptions/currentUserUpdates.graphql',
  'app/frontend/shared/graphql/subscriptions/configUpdates.graphql',
  'app/frontend/shared/graphql/subscriptions/appMaintenance.graphql',
  'app/frontend/shared/graphql/subscriptions/pushMessages.graphql',
  'app/frontend/shared/graphql/subscriptions/macrosUpdate.graphql',
  'app/frontend/shared/entities/core/attributes/graphql/queries/objectManagerFrontendAttributes.graphql',
  'app/frontend/shared/components/Form/graphql/queries/formUpdater.graphql',
  'app/frontend/shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.graphql',
  'app/frontend/shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/remove.graphql',
  'app/frontend/shared/components/Form/fields/FieldAgent/graphql/queries/autocompleteSearch/agent.graphql',
  'app/frontend/shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.graphql',
  'app/frontend/shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.graphql',
  'app/frontend/shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.graphql',
  'app/frontend/shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.graphql',
  'app/frontend/shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.graphql',
  'app/frontend/shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.graphql',
  'app/frontend/shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.graphql',
  'app/frontend/shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.graphql',
  'app/frontend/shared/components/Form/fields/FieldEditor/graphql/queries/aiAssistanceTextTools/aiAssistanceTextToolsList.graphql',
  'app/frontend/shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.graphql',
  'app/frontend/shared/graphql/mutations/aiAssistanceTextToolsRun.graphql',
  'app/frontend/shared/graphql/mutations/aiAnalyticsUsage.graphql',
  'app/frontend/shared/graphql/subscriptions/aiTextToolUpdates.graphql',
])

const toRepoRelativePath = (location) =>
  path.relative(process.cwd(), path.resolve(location)).split(path.sep).join('/')

// A typo here must abort codegen instead of silently leaving the document on compat.
vueApolloV5Documents.forEach((documentPath) => {
  if (!fs.existsSync(path.resolve(documentPath))) {
    throw new Error(`vueApolloV5Documents lists a file that does not exist: ${documentPath}`)
  }
})

const isVueApolloV5Document = (location) => vueApolloV5Documents.has(toRepoRelativePath(location))

module.exports = { isVueApolloV5Document, vueApolloV5Documents }
