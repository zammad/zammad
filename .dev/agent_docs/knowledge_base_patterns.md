# Knowledge Base Patterns

**Scope: the new stack only** — the Vue desktop app
(`app/frontend/apps/desktop/pages/knowledge-base/`), the GraphQL layer
(`app/graphql/gql/**/knowledge_base*`) and the services behind it
(`app/services/service/knowledge_base/`). Nothing here describes the other two
consumers: the legacy CoffeeScript admin frontend, and the server-rendered
public help site (`app/controllers/knowledge_base/public/`) — which is not
legacy, just a different stack. Both work on the knowledge base directly and by
their own rules, so do not apply these rules to them, and do not "align" them
with these.

For the layers themselves see `.dev/agent_docs/graphql_patterns.md` and
`.dev/agent_docs/service_patterns.md`.

## A single, active knowledge base

The system supports exactly one knowledge base, and the new stack works on it
only while it is **active** — browse queries, feeds, subscriptions and write
mutations alike. An inactive one is neither browsable nor editable there;
activating it and changing its settings (not its texts) stays with the legacy
admin dialog, which edits the record directly.

Rules for new code:

- Never accept a knowledge base id from the client, and never scope anything by
  one. Resolve it: `::KnowledgeBase.active.first!`.
- Raise `ActiveRecord::RecordNotFound` when none is active, rather than
  answering with null or an empty list. Whoever resolves the record asserts it —
  a write service does it for itself, a resolver with no service behind it does
  it inline.
- Do not pass a `knowledge_base:` into a write service. Pass it to a read
  service only if the resolver had to resolve the record anyway; nothing
  resolves it twice.
- Pass the client's `locale` code straight to the service, which resolves it
  strictly against that knowledge base (a `KnowledgeBase::Locale` record is
  accepted too), then call `store_knowledge_base_locale` so the payload renders
  in the locale that was written.

The single-knowledge-base assumption rests on there being no create route
(`resources :knowledge_bases, only: %i[show update]`) and the legacy admin
dialog offering its creation form only while none exists. It is not enforced by
a validation or a database constraint, so `first!` picks arbitrarily if seeds or
a console ever create a second one.

Where the rules live today — current code, not itself a rule: the write services
resolve the record inside `Service::KnowledgeBase::Base#active_knowledge_base!`.
Everywhere else the resolver resolves it, then either hands it to a read service
(`CategoryContent`, `FeedPaths`) or — where no service sits behind the
operation — asserts it inline and works on the record itself. Grep
`KnowledgeBase.active.first` to see which operations do which; it is a moving
set, so do not rely on a list here.

## Deliberate exceptions

Do not "fix" these without a decision:

- `Gql::Subscriptions::KnowledgeBase::ContentUpdates` pings with a **null**
  knowledge base instead of raising — a subscription cannot raise usefully, and
  this ping is the only signal browse views get after a deactivation. They
  refetch, then hit the not-found from the queries.
- `KnowledgeBasePolicy#show_any?` and `KnowledgeBasePolicy::Scope` let granted
  access outrank the active check, because the public help site previews an
  inactive knowledge base that way — the policy for anyone with effective access
  to the record (a reader included), the scope for the `knowledge_base.editor`
  permission.

Each of these carries the reasoning in a code comment; keep the two in sync.
