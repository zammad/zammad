// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

// A link to a knowledge base answer is marked up for the server, which resolves the target on read
//   and rewrites the href per consumer (`KnowledgeBaseRichText.resolve_answer_links`). Both the
//   type string and the id are a contract with it: the type is matched literally, and the id is the
//   *translation's* internal one, which the backend looks the translation up by.
export const ANSWER_LINK_TARGET_TYPE = 'knowledge-base-answer'

// Name of the toolbar tool that writes such a link. It is a tool over the `link` mark, not a TipTap
//   extension of its own, and it is opted into per field — see `optInExtensionNames`, whose
//   `satisfies` check ties this name to the `meta` key a form declares to switch the tool on.
export const ANSWER_LINK_ACTION_NAME = 'knowledgeBaseAnswerLink'

// The `href` is only a placeholder — the server replaces it on read — but it must not be empty, or
//   the link is unusable in the editor and in a preview of the unsaved answer.
export const answerLinkAttributes = (href: string, translationId: string) => ({
  href,
  'data-target-type': ANSWER_LINK_TARGET_TYPE,
  'data-target-id': String(getIdFromGraphQLId(translationId)),
})
