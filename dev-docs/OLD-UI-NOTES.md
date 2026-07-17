# Old UI Notes — Zammad "Request Participants"

> **STATUS: 🚧 IN ARBEIT — wachsendes Dokument.** Dieses Dokument wird nach Abschluss von
> Produkt 1 (insb. Phase 8 Security/GDPR) vervollständigt. Produkt 1 ist abgeschlossen,
> Produkt 2 in Umsetzung: Häppchen 1 (REST) ✅, Häppchen 2 (Widget) ✅ gebaut, Browser-Test steht aus.
>
> Vorlage für den jQuery/CoffeeScript-Implementierungsblock (Produkt 2, nach Vue-Fertigstellung)
>
> **Stand:** 17.06.2026 — Widget gebaut (sidebar_participants.coffee + .jst.eco), ECO-Parse-Fehler behoben.
> **Nächster Schritt:** Browser-Verifikation durch Entwickler (siehe Checkliste unten).

---

## Architektur der alten UI

```
Ticket-Detail-Seite (/) → ApplicationController → application.html.erb
  └── Sprockets: /assets/application.js
       └── App.TicketZoomSidebar (Observer, CoffeeScript)
            └── sidebarBackends = App.Config.get('TicketZoomSidebar')
                 ├── sidebar_ticket.coffee      → Ticket-Infos + Mention-Widget
                 ├── sidebar_ticket_summary.coffee
                 └── sidebar_checklist.coffee
```

**Erweiterungspunkt:**
```coffeescript
App.Config.set('TicketZoomSidebar', { participants: App.TicketZoomSidebarParticipants })
```

## Für Participants relevante Dateien

| Datei | Inhalt |
|-------|--------|
| `app/assets/javascripts/app/controllers/ticket_zoom/sidebar.coffee` | Sidebar-Host (`App.TicketZoomSidebar`), lädt `App.Config.get('TicketZoomSidebar')` |
| `app/assets/javascripts/app/controllers/ticket_zoom/sidebar_ticket.coffee` | Ticket-Info-Tab, enthält `@mentionWidget = new App.WidgetMention(...)` |
| `app/assets/javascripts/app/controllers/widget/mention.coffee` | `App.WidgetMention` — rendert Mentions, Subscribe/Unsubscribe (existiert!) |
| `app/assets/javascripts/app/views/widget/mention.jst.eco` | Mention-Template |

---

## Übertragene Entscheidungen aus dem MASTER-Dokument

Alle im MASTER getroffenen Architekturentscheidungen gelten für beide UIs:

| # | Entscheidung | Implikation für alte UI |
|---|-------------|-------------------------|
| **D1** | Cache-loses Design | Kein Stale-Access-Fenster. Entfernen = sofort kein Zugriff. Backend-only, alte UI muss nichts beachten. |
| **D2** | Agent-only MVP (Kunden-Add zurückgestellt) | Nur Agenten sehen den Tab. Kein "Share"-Button für Kunden. |
| **D3** | Org-übergreifende Teilnehmer (Default: ja) | Keine Same-Org-Einschränkung in der Suche. Optionales Setting `ticket_participants_same_org_only` später. |
| **D4** | Hard-Cap 50 Teilnehmer/Ticket | **Frontend muss prüfen:** Ist die aktuelle Mention-Anzahl < 50 bevor der Add-Button klickbar ist? Fehlermeldung im UI anzeigen. |
| **D5** | "Sie wurden hinzugefügt"-Mail | Backend-only. Alte UI muss nichts tun. |
| **D6** | Cap auch im Subscribe-Pfad | Backend-only (Trigger-Schutz). |
| **D7** | Migrations-Rails-Version | Backend-only. |

---

## Übertragene Findings (Bad Cop #1–#26) — Relevanz-Matrix

### 🔴 Backend — bereits gelöst, alte UI erbt automatisch

| # | Finding | Warum für alte UI egal |
|---|---------|------------------------|
| 3 | `customer_field_scope` truthy | Backend, keine UI-Aktion |
| 4 | Teilnehmer könnten updaten | `update?`-Guard im Backend, alte UI sendet keine Update-Requests für Teilnehmer |
| 5 | ReadScope fehlt | Backend, `BaseScope#resolve`-Fix gilt für REST + GraphQL gleichermaßen |
| 8 | `group_access?` filtert Teilnehmer | Notification-Fix im Backend |
| 9 | `notification_config` fehlt | Default-Matrix im Backend |
| 12 | N+1 in `participant?` | `participant_ids` Memoization im Backend |
| 13 | Notification-Spam | D4-Hard-Cap im Backend |
| 18 | `dependent: :destroy` User | Existiert bereits, kein Fix nötig |
| 19 | Deaktivierter User bleibt Teilnehmer | `active?`-Filter in `participant_ids` |
| 22 | `mentionable?` prüft Ticket-Zugriff nicht | `show?`-Check im Backend |
| 23 | Online-Notification-Seen | Backend, keine Aktion |

### 🟡 Backend — muss vor alter UI fertig sein

| # | Finding | Abhängigkeit |
|---|---------|-------------|
| 1 | `Setting.get` im Initializer | Braucht Table-Check. Blockiert alte UI nicht (läuft nach Boot). |
| 2 | Package-Migration-Pfad | Pfad `db/addon/` muss korrekt sein für Settings-Seed. |
| 6 | `create_mentions?` zu restriktiv | D2: Agent-only bleibt. REST-Add läuft via `MentionsController` → braucht den Actor-Check. |
| 10/11 | CC→Mention (Postmaster) | Phase 7, Backend-only. |
| 21 | Trigger/Scheduler subscriben | D6: Cap im Subscribe-Pfad. Backend-only. |
| 26 | `show?` ≠ Add-Autorisierung (Henne-Ei) | **Wichtig!** REST-Add via `MentionsController` muss denselben Pfad wie GraphQL nehmen: Agent-Add umgeht `mentionable?` via `create_mentions?`. |

### 🟢 Frontend — für alte UI relevant

| # | Finding | Implikation für alte UI |
|---|---------|-------------------------|
| 7 | `subscribed`-Kriterium existiert | `WidgetMention` nutzt bereits subscribed/unsubscribed. Kann als Anzeige-Basis dienen. |
| 16 | `import.meta.glob` = Build-time | ❌ Alte UI nutzt Sprockets, kein Vite/ESM. `App.Config.set()` ist Runtime-Registrierung. |
| 17 | Settings-Types generieren | ❌ CoffeeScript hat keine TypeScript-Types. `App.Setting.get()` liefert dynamischen Wert. |

---

## ⚠️ Real-Path-Bugs (B1–B3) — Lehren für die alte UI

Diese drei Bugs wurden im Vue-QA-Durchlauf gefunden. Sie folgen alle demselben Muster:
**Mechanismus in isolierten Tests grün, im echten End-to-End-Pfad nie erreicht.**

> **Übertragbare Lehre:** Der härteste Test ist immer: „Nutzer klickt im Browser, was passiert?"
> Isolierte Tests beweisen nur Einzelteile — nicht ihr Zusammenspiel über Schichten hinweg.

### B1: `mentionable?`-Henne-Ei

| | Beschreibung |
|---|-------------|
| **Symptom** | `mentionable?` prüft `show?` → true für Kunden. Agent fügt NEUEN Kunden hinzu: `show?` schlägt fehl weil Kunde Ticket noch nicht sehen darf → `mentionable?` blockiert. |
| **Fix (Vue)** | Agent-Add läuft über `create_mentions?` (umgeht `mentionable?`). Richtig: eigene Actor/Target-Autorisierung (D2, NEU-26). |
| **Relevanz alte UI** | ✅ **Kritisch!** REST-`MentionsController` muss denselben Pfad nehmen. Der Controller-Action muss prüfen: ist der aufrufende User ein Agent (Actor-Check)? Wenn ja → `create_mentions?` durchlassen, NICHT `mentionable?`. |

### B2: Cap im echten Pfad stumm

| | Beschreibung |
|---|-------------|
| **Symptom** | Backend: `subscribe!` wirft Exception ✅. Frontend: `MutationHandler.send()` → `null`-Destrukturierung warf `TypeError` bevor `result.errors` geprüft wurde → Fehler verschluckt, kein UI-Feedback. |
| **Relevanz alte UI** | ✅ **Direkt übertragbar.** `$.ajax` error-Handler muss HTTP-Status und Response-Body auswerten: <br>• 422 + `{"error": "Maximum of 50 participants per ticket reached"}` → rote Meldung im UI<br>• 403 → "Keine Berechtigung"<br>• Netzwerkfehler → "Verbindungsfehler"<br>**NIEMALS** nur `.fail()` ohne Body-Inspektion. |

### B3: Notification-EventBuffer

| | Beschreibung |
|---|-------------|
| **Symptom** | `GraphQL::Batch` führt Mutation asynchron aus → `EventBuffer` (Thread.current) leer beim `TransactionDispatcher.commit` → Mail wurde nie gesendet. |
| **Fix** | Direkter `NotificationFactory::Mailer.deliver`-Aufruf in `subscribe!`. |
| **Relevanz alte UI** | ❌ REST-Controller läuft synchron (kein GraphQL-Batch). `TransactionDispatcher.commit` feuert im selben Thread. **Trotzdem im E2E-Test prüfen:** Mail kommt in Mailcatcher an? |

---

## Vue-Erkenntnisse → Alte UI (erweitert)

| Vue-Bug/Mechanismus | Relevant für alte UI? | Begründung |
|-----|:---:|-----|
| `emit('show')` fehlt | ❌ | `App.TicketZoomSidebar` iteriert über `sidebarItems` und zeigt alle an. Kein Show/Hide-Mechanismus nötig. |
| `ticket.policy` undefined (ComputedRef-Wrapping) | ❌ | CoffeeScript, kein Vue Reactivity. Policy wird serverseitig geprüft. |
| Setting `frontend:true` | ✅ | **Pflicht!** Ohne `frontend: true` in der Settings-Migration erscheint das Setting nicht in `App.Setting`. Wurde im Vue-Setup als Bug #1 gefunden. |
| Apollo Error 88 (`graphql-tag`) | ❌ | Alte UI nutzt KEIN GraphQL. Nur `$.ajax` + REST + WebSocket. |
| REST-Suche (`/api/v1/users/search`) | ✅ | **REST ist der Normalfall.** Die Vue-REST-Workaround ist der natürliche Weg hier — kein Workaround nötig. |
| `convertToGraphQLId` | ❌ | Alte UI nutzt numerische IDs (`user.id`), keine GraphQL Global IDs (`gid://...`). |
| Icon `users` → `user` | ✅ | Gleicher SVG-Sprite. Icon-Name: `user` (nicht `users`). |
| **Cap 50 UI-Check** | ✅ | Vor Add-Button-Klick prüfen: `mentions.length >= 50` → Button disablen + "Maximum 50 participants" anzeigen. |
| **Error-Handling im UI** | ✅ | Siehe B2 oben. Jeder `$.ajax`-Call braucht `.done()` + `.fail()` mit Body-Inspektion. |
| **Feature-Flag Sichtbarkeit** | ✅ | `App.Setting.get('ticket_participants_enabled')` → Sidebar-Backend nur registrieren wenn `true`. |
| **Nur Agenten** | ✅ | `App.Session.get('permissions')` enthält `ticket.agent`? Sonst Tab nicht anzeigen. |

---

## Grobentwurf CoffeeScript-Backend (komplett überarbeitet)

```coffeescript
class App.TicketZoomSidebarParticipants extends App.Controller
  # Maximale Teilnehmerzahl (Hard-Cap D4)
  @MAX_PARTICIPANTS = 50

  events:
    'click .js-add-participant':    'showSearch'
    'click .js-remove-participant': 'remove'
    'keyup .js-search-input':       'onSearchInput'

  constructor: ->
    super

    # Feature-Flag prüfen (gleiches Setting wie Vue)
    return if !App.Setting.get('ticket_participants_enabled')

    # Nur Agenten (D2)
    permissions = App.Session.get('permissions') || []
    return if 'ticket.agent' not in permissions

    # Mentions-Daten holen (wird von TicketZoomSidebar über @ticket bereitgestellt)
    @ticket = @parent.ticket  # oder via Konstruktor-Parameter
    @mentions = @ticket.mentions || []
    @render()

  render: =>
    # Template rendern (JST/ECO)
    @html App.view('ticket_zoom/sidebar_participants')(
      mentions: @participantMentions()
      canAdd:   @participantMentions().length < App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS
      cap:      App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS
    )

  # Nur Kunden-Teilnehmer filtern (keine Agent-Mentions anzeigen)
  participantMentions: =>
    @mentions.filter (m) -> !m.user.permissions?.includes('ticket.agent')

  showSearch: (e) =>
    e.preventDefault()
    # Nochmal Cap prüfen (Race-Condition-Schutz)
    if @participantMentions().length >= App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS
      @notify(
        type: 'error'
        msg:  App.i18n.translateContent('Maximum of %s participants per ticket reached',
                                        App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS)
      )
      return
    # Such-UI einblenden
    @$('.js-participant-search').show()
    @$('.js-search-input').focus()

  onSearchInput: (e) =>
    query = $(e.target).val()
    return if query.length < 2

    # REST-Suche (ist der Normalfall in alter UI, kein Workaround!)
    @ajax(
      id:    'participant_search'
      type:  'GET'
      url:   '/api/v1/users/search'
      data:  { query: query, limit: 10 }
      processData: true
      success: (data, status, xhr) =>
        @showSearchResults(data)
      error: (xhr, status, error) =>
        # B2-Lehre: Fehler NIEMALS verschlucken
        @notify(type: 'error', msg: 'Search failed. Please try again.')
    )

  showSearchResults: (users) =>
    # Bereits vorhandene Teilnehmer ausfiltern
    existingIds = @participantMentions().map (m) -> m.user.id
    available = users.filter (u) -> u.id not in existingIds
    # Ergebnisliste rendern
    @$('.js-search-results').html(
      App.view('ticket_zoom/sidebar_participants_results')(users: available)
    )

  add: (e) =>
    e.preventDefault()
    userId = $(e.target).closest('[data-user-id]').data('user-id')

    # Cap-Check (D4)
    if @participantMentions().length >= App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS
      @notify(
        type: 'error'
        msg:  App.i18n.translateContent('Maximum of %s participants per ticket reached',
                                        App.TicketZoomSidebarParticipants.MAX_PARTICIPANTS)
      )
      return

    @ajax(
      id:    'participant_add'
      type:  'POST'
      url:   "/api/v1/tickets/#{@ticket.id}/mentions"
      data:  JSON.stringify(user_id: userId)
      processData: true
      success: (data, status, xhr) =>
        # Teilnehmer zur lokalen Liste hinzufügen & neu rendern
        @mentions.push(data)
        @render()
        @notify(type: 'success', msg: 'Participant added.')
      error: (xhr, status, error) =>
        # B2-Lehre: Response-Body auswerten
        try
          body = JSON.parse(xhr.responseText)
          msg = body.error || body.message || 'Failed to add participant.'
        catch
          msg = 'Failed to add participant.'
        @notify(type: 'error', msg: msg)
    )

  remove: (e) =>
    e.preventDefault()
    userId = $(e.target).closest('[data-user-id]').data('user-id')

    @ajax(
      id:    'participant_remove'
      type:  'DELETE'
      url:   "/api/v1/tickets/#{@ticket.id}/mentions/#{userId}"
      processData: true
      success: (data, status, xhr) =>
        # Teilnehmer aus lokaler Liste entfernen & neu rendern
        @mentions = @mentions.filter (m) -> m.user.id != userId
        @render()
        @notify(type: 'success', msg: 'Participant removed.')
      error: (xhr, status, error) =>
        # B2-Lehre
        try
          body = JSON.parse(xhr.responseText)
          msg = body.error || body.message || 'Failed to remove participant.'
        catch
          msg = 'Failed to remove participant.'
        @notify(type: 'error', msg: msg)
    )
```

---

## Verwendete APIs (alte UI)

| Funktion | Endpoint | Status |
|----------|----------|:---:|
| User-Suche | `GET /api/v1/users/search?query=...&limit=10` | ✅ Existiert |
| Teilnehmer hinzufügen | `POST /api/v1/tickets/:id/mentions` | ❓ Prüfen! |
| Teilnehmer entfernen | `DELETE /api/v1/tickets/:id/mentions/:user_id` | ❓ Prüfen! |
| Setting lesen | `App.Setting.get('ticket_participants_enabled')` | ✅ Existiert (nach Seed) |
| Permissions lesen | `App.Session.get('permissions')` | ✅ Existiert |

---

## Vor dem Start zu klären

### 1. REST-Endpoints: Existieren sie?

Die GraphQL-Mutationen `ticketParticipantAdd` / `ticketParticipantRemove` sind neu gebaut.
Frage: Gibt es korrespondierende REST-`MentionsController`-Actions?

- `POST /api/v1/tickets/:id/mentions` → `MentionsController#create`?
- `DELETE /api/v1/tickets/:id/mentions/:user_id` → `MentionsController#destroy`?

**Falls nicht:** Entweder REST-Endpoints neu bauen, oder — falls technisch möglich —
GraphQL-Mutationen aus CoffeeScript per `$.ajax` auf `/graphql` aufrufen (ungewöhnlich
für alte UI, aber machbar).

### 2. `App.WidgetMention` erweitern oder separates Widget?

Das existierende Mention-Widget (`app/assets/javascripts/app/controllers/widget/mention.coffee`)
zeigt Mentions an und hat Subscribe/Unsubscribe-Logik. Optionen:

| Option | Vorteil | Nachteil |
|--------|---------|----------|
| **A: WidgetMention erweitern** | Weniger Code, bestehende UI | Mention-Logik ist Agent-zentriert, Subscribe/Unsubscribe passt nicht 1:1 auf Participants |
| **B: Separates Widget** | Saubere Trennung, keine Seiteneffekte | Mehr Code, eigenes Template nötig |

**Empfehlung:** Option B (separates Widget). `WidgetMention` ist für Agent-internes
@-Mentioning gebaut. Participants sind ein anderes Konzept (Kunden-Teilnehmer, andere
Berechtigungen). Das separate Widget kann aber `WidgetMention` als **Referenz** nutzen
(API-Patterns, Template-Struktur, Error-Handling).

### 3. Permission-Check in CoffeeScript

Im Vue-Plugin: `permissions: ['ticket.agent']` im Plugin-Manifest.
In CoffeeScript: Manuell prüfen via `App.Session.get('permissions')`.

```coffeescript
# Standard-Pattern in Zammad CoffeeScript:
permissions = App.Session.get('permissions') || []
return if 'ticket.agent' not in permissions
```

### 4. WebSocket-Live-Update?

Die alte UI nutzt WebSocket für Live-Updates (Ticket-Änderungen). Frage:
- Soll das Participants-Widget auf Mention-Änderungen per WebSocket reagieren?
- Oder reicht Neu-Laden beim Tab-Wechsel?

**Empfehlung:** MVP ohne WebSocket. Neu-Laden beim Tab-Wechsel.
WebSocket kann als Folgephase ergänzt werden.

---

## Security-/GDPR-Checkliste für alte UI

Die Backend-Checks (Policy, Scope) gelten automatisch. Zusätzlich UI-seitig:

```
□ Feature-Flag `ticket_participants_enabled` wird vor Widget-Registrierung geprüft
□ Nur Agenten sehen den Participants-Tab (App.Session.get('permissions'))
□ Teilnehmer-Liste zeigt nur Kunden (keine Agent-Mentions)
□ Cap-50 wird VOR Add-Request clientseitig geprüft
□ Error-Handling zeigt Backend-Fehlermeldungen an (niemals silent fail)
□ Opt-out (Selbst-Entfernen) funktioniert für Teilnehmer
  → REST-Endpoint muss auch für Kunden-Teilnehmer erreichbar sein (Policy beachten!)
```

---

## Aufwandsschätzung (nur alte UI)

| Bereich | Aufwand |
|---------|:------:|
| REST-Endpoints bauen/prüfen (falls fehlend) | 0,5 Tage |
| CoffeeScript-Widget (Participants-Tab) | 1,5 Tage |
| Template (JST/ECO) + CSS | 0,5 Tage |
| Search-UI + Autocomplete | 0,5 Tage |
| Error-Handling, Cap, Edge-Cases | 0,5 Tage |
| Manueller E2E-Durchlauf (Mailcatcher, Flag, Cap) | 0,5 Tage |
| **Gesamt** | **~4 Tage** |

> Basis: Backend ist fertig, Vue-Feature dient als Vorlage, REST-Suche existiert bereits.
