// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

// The legacy object names the preview endpoint switches on (`params[:object]`),
//   which are not the GraphQL/Rails class names.
type PreviewObject = 'KnowledgeBase' | 'KnowledgeBaseCategory'

// Build the URL of the REST preview endpoint for a knowledge base node. That
//   endpoint mints a per-editor preview token and redirects to the public help
//   site, so editors can preview unpublished content — which is why we link to
//   it instead of the canonical public path. The gating (whether to show the
//   link at all) is decided by the caller.
export const knowledgeBasePreviewUrl = (object: PreviewObject, graphqlId: string, locale: string) =>
  `/api/v1/knowledge_bases/preview/${object}/${getIdFromGraphQLId(graphqlId)}/${locale}`
