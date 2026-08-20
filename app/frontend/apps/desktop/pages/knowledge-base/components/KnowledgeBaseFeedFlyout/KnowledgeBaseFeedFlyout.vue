<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, ref } from 'vue'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import { useBaseUrl } from '#shared/composables/useBaseUrl.ts'
import type { KnowledgeBaseFeedAttributesFragment } from '#shared/graphql/types.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import CommonInputCopyToClipboard from '#desktop/components/CommonInputCopyToClipboard/CommonInputCopyToClipboard.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useKnowledgeBaseFeedTokenRenewMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseFeedTokenRenew.api.ts'
import { useKnowledgeBaseFeedQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseFeed.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { KNOWLEDGE_BASE_FEED_FLYOUT_NAME } from '#desktop/pages/knowledge-base/composables/useKnowledgeBaseFeedAction.ts'

interface Props {
  // The browsed category, so its feed — the category including its
  //   sub-categories — is offered next to the knowledge base one. Omitted at the
  //   knowledge base root, where only the latter exists.
  categoryId?: string
}

const props = defineProps<Props>()

// The feeds deliver the locale that is being browsed, which is the one in the
//   URL — not the header's locale code, which is upper-cased for display.
const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

// Never cached: the paths carry an access token that renewing invalidates —
//   here, in another tab, or in the old interface — so every opening has to ask
//   for what is valid now, and the token has no business sitting in the cache.
const feedQuery = new QueryHandler(
  useKnowledgeBaseFeedQuery(
    () => ({
      categoryId: props.categoryId,
      locale: activeLocale.value,
    }),
    {
      fetchPolicy: 'no-cache',
    },
  ),
)

const result = feedQuery.result()

// Renewing answers with the new paths, which replace the ones on screen in the
//   same step — no reload in between, so the fields never blank out and the URLs
//   they offer are never the invalidated ones.
const renewedFeed = ref<KnowledgeBaseFeedAttributesFragment>()

const feed = computed(() => renewedFeed.value ?? result.value?.knowledgeBaseFeed)

// The backend returns paths; the absolute URL for the feed reader is built here,
//   because only the browser knows the origin to fall back to while the fqdn is
//   still the placeholder default.
const { baseUrl } = useBaseUrl()

const knowledgeBaseUrl = computed(() =>
  feed.value ? `${baseUrl.value}${feed.value.knowledgeBasePath}` : undefined,
)

const categoryUrl = computed(() =>
  feed.value?.categoryPath ? `${baseUrl.value}${feed.value.categoryPath}` : undefined,
)

const loading = feedQuery.loadingWithoutCachedResult()

// While a renewal is on its way the server may already have rotated the token, so
//   the URLs on screen cannot be trusted: copying is blocked, and a second renewal
//   too — overlapping ones could answer out of order and leave an obsolete token.
const renewing = ref(false)

// Set when a renewal failed and the paths could not be reconciled either: what is
//   in hand may already be rotated, so nothing is offered until a renewal succeeds.
const unreconciled = ref(false)

const queryError = feedQuery.operationError()

// Nothing to show and nothing to act on: the paths either never arrived, or a
//   renewal left them of unknown state. Both are rare enough to leave at an alert —
//   opening the flyout anew asks for them again.
const error = computed(() =>
  unreconciled.value || queryError.value ? __('Content could not be loaded.') : undefined,
)

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionButton: { variant: 'primary' },
  actionLabel: __('OK'),
  hideCancelButton: true,
}))

const { notify } = useNotifications()

const renewToken = async () => {
  if (renewing.value) return

  renewing.value = true

  const renewMutation = new MutationHandler(useKnowledgeBaseFeedTokenRenewMutation(), {
    errorNotificationMessage: __('Renewing the access token failed.'),
  })

  try {
    const data = await renewMutation.send({
      categoryId: props.categoryId,
      locale: activeLocale.value,
    })

    const renewed = data?.knowledgeBaseFeedTokenRenew?.feed

    if (!renewed) return

    renewedFeed.value = renewed
    unreconciled.value = false

    // Only once the new paths are in hand, never on the strength of the request
    //   having gone out.
    notify({
      id: 'knowledge-base-feed-token-renewed',
      type: NotificationTypes.Success,
      message: __('Access token renewed, update your RSS reader with the new feed URLs.'),
    })
  } catch {
    // The renewal may have gone through all the same (a lost response), so the paths
    //   on screen are of unknown state and go away with the rest. Opening the flyout
    //   anew asks for ones that are certainly valid.
    unreconciled.value = true
  } finally {
    renewing.value = false
  }
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Knowledge base feed')"
    header-icon="rss"
    :name="KNOWLEDGE_BASE_FEED_FLYOUT_NAME"
    :footer-action-options="footerActionOptions"
  >
    <CommonLoader :loading="loading">
      <div class="flex flex-col gap-6">
        <div v-if="!error" class="flex flex-col gap-6" data-test-id="knowledge-base-feed-urls">
          <CommonInputCopyToClipboard
            v-if="knowledgeBaseUrl"
            :label="__('Knowledge base feed')"
            :help="__('The latest internal answers in the whole knowledge base.')"
            :copy-button-text="__('Copy URL')"
            :disabled="renewing"
            :value="knowledgeBaseUrl"
          />

          <CommonInputCopyToClipboard
            v-if="categoryUrl"
            :label="__('Category feed')"
            :help="
              __('The latest internal answers of the current category and its sub-categories.')
            "
            :copy-button-text="__('Copy URL')"
            :disabled="renewing"
            :value="categoryUrl"
          />
        </div>

        <CommonAlert v-if="error" variant="danger">{{ $t(error) }}</CommonAlert>

        <div v-else class="flex flex-col gap-2.5">
          <CommonLabel>
            {{
              $t(
                'If you want to invalidate your feed URLs, renew the access token below. Make sure to update your RSS reader with new feed URLs afterwards.',
              )
            }}
          </CommonLabel>

          <CommonButton
            class="self-end"
            size="medium"
            variant="submit"
            :disabled="renewing || !feed"
            @click="renewToken"
          >
            {{ $t('Renew access token') }}
          </CommonButton>
        </div>
      </div>
    </CommonLoader>
  </CommonFlyout>
</template>
