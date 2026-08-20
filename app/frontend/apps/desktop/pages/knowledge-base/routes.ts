// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useKnowledgeBaseAccess } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'

import type { RouteRecordRaw } from 'vue-router'

// Both browse routes render the same view; sharing one component reference (not
//   two inline `() => import()`) keeps the section's single KeepAlive instance
//   alive across root ↔ category, so its state survives the switch.
const KnowledgeBaseBrowse = () => import('./views/KnowledgeBaseBrowse.vue')

const LEGACY_PATH_PREFIX = '/knowledge_base/:knowledgeBaseInternalId(\\d+)/locale/:localeCode'

const route: RouteRecordRaw[] = [
  {
    // The single "root entry" for the knowledge base section. It owns the
    //   shared concerns — authentication, the dynamic access gate, and the
    //   section-level nav/KeepAlive meta — which are inherited by every child
    //   page via the merged `route.meta` (and by the sidebar via this first-
    //   level record). New pages (e.g. the answer detail view) are added as
    //   children and pick these up automatically.
    path: '/knowledge-base',
    name: 'KnowledgeBaseLayout',
    component: () => import('./views/KnowledgeBase.vue'),
    meta: {
      title: __('Knowledge Base'),
      icon: 'book',
      mainNavigation: true,
      requiresAuth: true,
      requiredPermission: [],
      canAccess: () => useKnowledgeBaseAccess().canBrowse.value,
      order: 300,
      pageKey: 'knowledge-base',
      permanentItem: true,
    },
    children: [
      {
        // The root browse page: lists the knowledge base's top-level categories
        //   for the locale. The empty alias is the locale-less entry (e.g. the
        //   sidebar link); the shell's route guards resolve it (see
        //   KnowledgeBase.vue).
        path: 'locale/:localeCode?',
        alias: '',
        name: 'KnowledgeBaseBrowse',
        component: KnowledgeBaseBrowse,
        props: true,
      },
      {
        // The category browse page: the same view scoped to one category,
        //   showing its child categories and answers. The category lives behind
        //   `category/` as its own segment so the upcoming `/answer/:id` route
        //   slots in beside it (and both stay off the locale root).
        path: 'locale/:localeCode/category/:categoryInternalId(\\d+)',
        name: 'KnowledgeBaseCategory',
        component: KnowledgeBaseBrowse,
        props: true,
      },
      {
        path: 'locale/:localeCode/answer/:answerInternalId(\\d+)',
        name: 'KnowledgeBaseAnswer',
        component: () => import('./views/KnowledgeBaseAnswer.vue'),
        props: true,
      },
    ],
  },
  // The legacy stack addresses knowledge base nodes as
  //   `#knowledge_base/<kb id>/locale/<locale>[/category|answer/<id>][/edit]`, and links in
  //   those shapes still arrive here: from answer bodies going through useHtmlLinks(), and
  //   from the "edit" button the public help site puts on every node — where the feeds lead.
  //   Without these they match no route and useHtmlLinks() drops the click on the dashboard.
  //   The old interface's remaining routes (search, the `new` forms) have no counterpart yet.
  //
  //   Redirects rather than aliases on the routes above: an alias must declare the exact same
  //   params, and these shapes carry the knowledge base id — which is not needed here (there
  //   is only ever one) and is dropped on the way to the canonical URL. The `/edit` action is
  //   matched and dropped as well: the new interface has no separate editing routes, so those
  //   links open the node itself.
  {
    path: `${LEGACY_PATH_PREFIX}/answer/:answerInternalId(\\d+)/:action(edit)?`,
    name: 'KnowledgeBaseAnswerLegacyUrl',
    redirect: (to) => ({
      name: 'KnowledgeBaseAnswer',
      params: {
        localeCode: to.params.localeCode,
        answerInternalId: to.params.answerInternalId,
      },
    }),
  },
  {
    path: `${LEGACY_PATH_PREFIX}/category/:categoryInternalId(\\d+)/:action(edit)?`,
    name: 'KnowledgeBaseCategoryLegacyUrl',
    redirect: (to) => ({
      name: 'KnowledgeBaseCategory',
      params: {
        localeCode: to.params.localeCode,
        categoryInternalId: to.params.categoryInternalId,
      },
    }),
  },
  {
    path: `${LEGACY_PATH_PREFIX}/:action(edit)?`,
    name: 'KnowledgeBaseLegacyUrl',
    redirect: (to) => ({
      name: 'KnowledgeBaseBrowse',
      params: {
        localeCode: to.params.localeCode,
      },
    }),
  },
]

export default route
