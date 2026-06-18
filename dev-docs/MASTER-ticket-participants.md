# Master-Plan: Zammad „Request Participants"

> **Single Source of Truth.** Dieses Dokument ersetzt die Schätzungen, Risiken und
> Empfehlungen der Einzeldokumente 00–14 bei Widersprüchen. Die Einzeldokumente bleiben
> als Hintergrund/Herleitung gültig, aber **dieses Dokument hat Vorrang.**
>
> **Stand:** 18.06.2026 · **HEAD:** `9f29974` (erster Squash-Commit) · Branch-HEAD: `0b41740`
> WSL2 + Mirror synchron auf `0b41740` (gesquasht, 5 Commits).
> **Branch:** `feature/ticket-participants`
> **Status:** Produkt 1 + 2 INTERN VOLLSTÄNDIG. Beide UIs (Vue + alt) funktional, browser-verifiziert.
> Internal-Mail-Guard (gefixt, Mailcatcher-verifiziert, Umgehungspfad ausgeschlossen).
> Teilnehmer-Badge beide UIs. Offen: vor-Release-Politur (FormKit, Squash, 🔴, PR-QA-1/2),
> geparkt NEU-26/27/28/29 (Overview).

---

## 1. Worum es geht

Agenten können einem Ticket zusätzliche Kunden als **Teilnehmer** hinzufügen. Ein Teilnehmer
sieht das Ticket (Customer-Ansicht, nur öffentliche Artikel) und erhält E-Mail-Benachrichtigungen –
analog zu Jiras „Request Participants". Der Ansatz nutzt **bestehende Infrastruktur** wieder
(`Mention`-Tabelle, vorhandene Frontend-Subscribe-Logik), statt ein neues Datenmodell zu bauen.

**Community-Kontext (Begründung der Priorität):** Höchstgevotetes offenes Zammad-Feature,
Issue [#1307](https://github.com/zammad/zammad/issues/1307) offen seit 2017, offizielle Position
„weder angenommen noch abgelehnt". Mehrere Firmen haben Zammad deswegen verlassen, eine hat
Sponsoring angeboten. → Gute Chance, die Core-Änderung als PR über #1307 zu platzieren.

---

## 2. Scope

**Im MVP enthalten:** Agent fügt Kunde als Teilnehmer hinzu/entfernt ihn · Teilnehmer sieht das
Ticket (nur dieses, nur öffentliche Artikel) · Teilnehmer erhält E-Mail-Notifications · Teilnehmer
kann sich selbst entfernen (Opt-out) · CC-Empfänger eingehender Mails werden optional zu Teilnehmern ·
alles hinter Feature-Flag.

**Bewusst NICHT im MVP:** Customer-Portal (separater Aufwand 10–15 T) · „Share"-Button für Kunden
zum Selbst-Einladen · Teilnehmer-Ablauf/Timeout · Digest-Benachrichtigungen.

---

## 3. Architekturentscheidung

**Reihenfolge:** Core entwickeln → als Plugin extrahieren → PR bei Zammad einreichen.

| | Core (B) | Plugin (A) |
|---|---|---|
| Rolle | Entwicklung, Verständnis, PR-Kandidat | Auslieferung & Fallback, falls PR abgelehnt |
| Wartung bei Updates | Merge nötig | Jedes Update gegen Patches prüfen |
| Risiko | Kein Plugin-Kollisionsrisiko | Monkey-Patch-Kollisionen möglich |

Begründung: In der Core-Variante sind die Stacktraces klar und das Verständnis wächst schneller;
die Plugin-Variante (Module#prepend) wird daraus extrahiert und dient als sofort ausrollbares
Artefakt, unabhängig vom PR-Schicksal.

---

## 4. Der MVP-Core (finale, integrierte Code-Änderungen)

> Dies sind die **autoritativen** Fassungen (entspricht Doku 14 §4, inkl. der Bad-Cop-Fixes #4, #5,
> #8, #9, #13, #22). Sie ersetzen frühere, einfachere Varianten aus Doku 00.

### 4.1 `app/policies/ticket_policy.rb`
```ruby
def customer_access?
  return false if !user.permissions?('ticket.customer')
  return customer_field_scope if customer?
  return customer_field_scope if participant?    # NEU
  shared_organization?
end

def participant?
  return false if !Setting.get('ticket_participants_enabled')
  return false if !user.active?                  # Bad-Cop #19
  record.respond_to?(:participant_ids) && record.participant_ids.include?(user.id)
rescue NoMethodError
  false
end

# Bad-Cop #4: Teilnehmer dürfen NICHT updaten.
# update? (Z.15) delegiert an change_access? (Z.89) — agent_update_access?
# short-circuits vor dem participant?-Block, Agent-Teilnehmer können updaten.
def change_access?
  return true if agent_update_access?
  return false if agent_read_access?
  return false if participant?
  customer_access?
end
```

### 4.2 `app/models/ticket.rb` (D1 GELÖST – cache-los, eine gemeinsame Quelle)
```ruby
# Request-scoped Memoization (KEIN Rails.cache/5-Min). Innerhalb eines Requests konsistent,
# am Request-Ende automatisch "invalidiert" → kein Stale-Access-Fenster (D1).
def participant_ids
  @participant_ids ||= mentions.joins(:user)
                               .where(users: { active: true })
                               .pluck(:user_id)
end
```
> `scope :participated_by` wurde im Entwurf skizziert, aber nie committet (keine Aufrufer).
> `participant_ids` liefert dieselbe Funktionalität.

### 4.3 `app/models/mention.rb` — Target-Check (geändert in c0a630eb54)
```ruby
def self.mentionable?(object, user)
  case object
  when Ticket
    policy = TicketPolicy.new(user, object)
    return true if policy.agent_read_access?
    return false if !Setting.get('ticket_participants_enabled')
    return false if !user.permissions?('ticket.customer')
    true                    # reiner Target-Check — kein show? mehr
  else
    false
  end
end
```
> **Commit `c0a630eb54`:** `show?` wurde bewusst entfernt (Henne-Ei-Fix für NEU-26).
> `mentionable?` ist jetzt ein **reiner Target-Check** (customer + Flag ON = valides Ziel).
> Der `show?`-Guard für Self-Subscribe wurde nach `MentionsControllerPolicy#object_accessible?`
> verschoben (siehe §4.3b). `create_mentions?` bleibt unverändert Agent-only.

### 4.3b `app/policies/controllers/mentions_controller_policy.rb` — Self-Subscribe-Guard (G1)
```ruby
def object_accessible?
  return false if !Mention.mentionable?(record.mentionable_object, user)

  # Self-subscribe guard (G1): customer may only subscribe to tickets they can see
  if user.permissions?('ticket.customer')
    return false if !TicketPolicy.new(user, record.mentionable_object).show?
  end

  true
end
```
> **Sicherheitsbaustein (G1):** Der `show?`-Check aus `mentionable?` wurde HIERHER verschoben —
> er prüft den ACTOR (darf der einloggte User sich selbst subscriben?), nicht das TARGET.
> Agenten sind nicht betroffen (kein `ticket.customer`-Permission). Dies ist die Stelle, die
> verhindert, dass ein Kunde sich selbst zu einem fremden Ticket subscribt.

### 4.4 `app/policies/ticket_policy/base_scope.rb` — Listenfilterung (Bad-Cop #5)
```ruby
# In BaseScope#resolve (base_scope.rb:33-42), im Customer-Zweig:
if Setting.get('ticket_participants_enabled')
  participant_ticket_ids = Mention.joins(:user)
                                  .where(mentionable_type: 'Ticket', user_id: user.id,
                                         users: { active: true })
                                  .pluck(:mentionable_id)
  if participant_ticket_ids.present?
    sql.push('tickets.id IN (?)')
    bind.push(participant_ticket_ids)
  end
end
```
> **Anker-Tests:** P3 (participant sees ticket in ReadScope, Flag ON) und P6 (Flag OFF → NOT
> in ReadScope) in `spec/policies/ticket_policy_baseline_spec.rb` beweisen die funktionale
> Äquivalenz zum früheren `.or`-Entwurf. Der frühere MASTER-Entwurf mit separatem
> `ReadScope#resolve`-Override entsprach nicht der realen Code-Struktur; die gesamte
> Listenfilterung läuft über `BaseScope#resolve` als SQL-Fragment-Builder, `ReadScope`
> setzt nur `ACCESS_TYPE = :read`.
> **D1 gelöst:** Beide Pfade (Detail via `participant?` und Liste via `BaseScope`) filtern jetzt
> auf `active: true` und sind cache-los → Liste und Detail sind immer konsistent, ein entfernter
> Teilnehmer verliert den Zugriff **sofort** beim nächsten Request.

### 4.5 `app/models/transaction/notification.rb` (Bad-Cop #8, #9, #13)
```ruby
mention_users.each do |mention_user|
  if mention_user.permissions?('ticket.agent')
    next if !mention_user.group_access?(ticket.group_id, 'read')
  else
    next if !Setting.get('ticket_participants_enabled')  # Defense-in-Depth
  end
  # Nicht-Agenten (Teilnehmer) ohne group_access-Check durchlassen
  possible_recipients.push mention_user
  @recipients_reason[mention_user.id] ||= __(
    'You are receiving this because you were mentioned in this ticket.'
  )
end
```
> **Defense-in-Depth:** Der `else`-Zweig gated Non-Agent-Mentions auf das Feature-Flag.
> Zwar blockt `mentionable?` bereits Non-Agent-Mentions bei Flag OFF — dieser Check
> ist eine zweite Sicherungsschicht für den Notification-Pfad.
> Limit/Spam-Schutz: siehe §7 D4 (eine konsistente Zahl festlegen, nicht 20 *und* 50).

### 4.6 `app/frontend/.../useTicketSubscribe.ts`
```typescript
const canManageSubscription = computed(() =>
  isTicketAgent.value || session.hasPermission('ticket.customer')
)
```

### 4.7 `app/models/mention.rb` – Cache-Invalidation ~~(ENTFÄLLT durch D1)~~
> **Nicht mehr nötig.** Mit dem cache-losen Design aus §4.2/§4.4 (request-scoped Memoization,
> keine `Rails.cache`) gibt es keinen Cross-Request-Cache, der invalidiert werden müsste.
> Diesen Hook **nicht implementieren** – er war nur Mitigation für den 5-Minuten-Cache, den wir
> bewusst gestrichen haben. Spart Code und schließt die Stale-Access-Lücke an der Wurzel.

---

## 5. Korrektur: der „gefundene Bug" existiert NICHT

> **Dies ist die wichtigste Bereinigung gegenüber Doku 00 und Doku 09.**

Frühere Dokumente behaupteten, im `User`-Modell fehle `has_many :mentions, dependent: :destroy`,
und führten dies als Top-Risiko und Empfehlung. **Die spätere Serena-Verifikation (Doku 13 #18,
Doku 14 §5) hat das widerlegt:** Die Assoziation **existiert bereits** in `app/models/user.rb`.
Auch `Ticket` hat `has_many :mentions, as: :mentionable, dependent: :destroy`.

➡️ **Es ist kein Bugfix nötig.** Beim Übernehmen: in allen Dokumenten als „verifiziert vorhanden"
markieren, nicht als offene Aufgabe. (Trotzdem in Phase 0 einmalig per Test bestätigen, siehe §6.)

---

## 6. Optimierter Plan: Phasen, Gates, EINE Schätzung

Reihenfolge nach **Abhängigkeit**, jede Phase mit Quality-Gate. Risikoreichste Teile (Policy)
zuerst und am stärksten abgesichert.

| Phase | Inhalt | Gate (muss grün sein) | Senior/Mid | Junior |
|---|---|---|:--:|:--:|
| **0 · Setup & Baseline** | Zammad `develop` lauffähig; **Characterization-Tests für bestehende `TicketPolicy` + Notification schreiben & grün**; `dependent: :destroy` per Test bestätigen | Bestehende Suite läuft unverändert grün | 0,5 | 1,5 |
| **1 · Doku-Reconciliation** | Dieses Master-Doc übernehmen; Phantom-Bug entfernen; Zeilennummern gegen aktuellen `develop` re-verifizieren | Ein konsistentes Dokument, keine Widersprüche | 0,5 | 0,5 |
| **2 · Policy & Scope** 🔴 | §4.1, §4.2, §4.4; **Cache/ReadScope-Konsistenz** auflösen (D1) | Baseline grün + neue Policy-Specs + Bad-Cop B1–B5 als Specs | 1,5 | 3 |
| **3 · mentionable? + Call-Site-Sweep** 🔴 | §4.3; **3 Aufrufstellen** (LSP-verifiziert) je per Test absichern: `MentionsControllerPolicy` (REST Self-Subscribe!), `MentionValidator` (@mention im Artikel), Trigger/`perform_changes` | 1 Test pro Call-Site grün | 0,5 | 1,5 |
| **4 · Notification** | §4.5; Default-Matrix; Limit (D4) | Mail-Test mit 0/1/N Teilnehmern | 1 | 2 |
| **5 · GraphQL + REST** | `participants`-Feld; `ParticipantAdd/Remove`; Schema-Registrierung prüfen | Introspektion zeigt Mutationen; 403-Tests | 1,5 | 3 |
| **6 · Frontend** | §4.6; `TicketParticipants*`-Komponenten; AddFlyout/Suche | Component-Tests + manueller Flow | 2 | 4 |
| **7 · Postmaster CC** | `ParticipantCcCheck`-PostFilter (CC→Mention) | E-Mail-Eingangstest grün | 0,5 | 1,5 |
| **8 · Security/GDPR** | Audit-Log verifizieren; „Sie wurden hinzugefügt"-Mail; Opt-out; DSGVO-Doku | Security-Checkliste §9 vollständig | 1 | 1,5 |
| **9 · Plugin + Clean-Room** | Module#prepend-Extraktion; `.zpm`-Build; Install auf frischer 8.x inkl. Precompile | Install auf sauberer Instanz erfolgreich | 1 | 2 |
| | | **Summe** | **~10 T** | **~20 T** |

**MVP-Subset = Phasen 0–7** (~8 T Senior / ~17 T Junior). Phasen 8–9 vor Produktiv-Rollout
bzw. Auslieferung. Diese **eine** Schätzung ersetzt alle früheren (5–7 / 6 / 17 / 26 h / 5 Tage).
Sie ist inkl. Review-Schleifen gerechnet; Ideal-Stunden eines Seniors lagen tiefer, sind aber für
die Planung unrealistisch.

🔴 = höchstes Regressionsrisiko (kann bestehenden Agent-Zugriff brechen).

---

## 7. Offene Entscheidungen (vor Phase 2 klären)

| # | Entscheidung | Empfehlung / Beschluss | Status |
|---|---|---|:--:|
| **D1** | Cache vs. ReadScope-Konsistenz | **BESCHLOSSEN:** cache-los. Request-scoped Memoization in `participant_ids`; `ReadScope` nutzt dieselbe `active:true`-Quelle (§4.2/§4.4). §4.7-Hook entfällt. Kein Stale-Access-Fenster. | ✅ entschieden |
| **D2** | Kunden fügen selbst Teilnehmer hinzu? (Jira „Share") | **BESCHLOSSEN: MVP Agent-only; Jira-„Share" zurückgestellt.** Grund: nicht „problemlos" – der `show?`-Target-Check aus #22 blockiert das Hinzufügen *neuer* (noch zugriffsloser) Kunden (Henne-Ei). Ein sauberer Kunden-Add-Pfad braucht eine eigene Autorisierung (Actor sieht Ticket UND Target ist gültiger Kunde, **ohne** Vorab-Zugriff zu verlangen) → eigene Folgephase. Siehe NEU-26. | ✅ entschieden |
| **D3** | Org-übergreifende Teilnehmer? | **BESCHLOSSEN: ja, realisieren (Jira-konform).** Default erlauben, keine Same-Org-Beschränkung (kostet im Plugin keine Extra-Logik). Optionales Setting `ticket_participants_same_org_only` als spätere Option für regulierte Installs. DSGVO: durch Agent-Aktion gedeckt, dokumentieren. | ✅ entschieden |
| **D4** | Notification-Limit (20 vs. 50) | **BESCHLOSSEN:** EIN Limit. Hard-Cap **50 Teilnehmer/Ticket** (Validierung beim Add); **alle** ≤50 werden benachrichtigt. Kein zweites 20er-Limit (sonst „stiller" Teilnehmer 21–50). Digest später, falls nötig. | ✅ entschieden |
| **D5** | „Sie wurden hinzugefügt"-Mail (DSGVO Art. 6) | **BESCHLOSSEN: ja, realisieren, im MVP** (Phase 8). `Mention after_create` → Notification an Kunden-Teilnehmer über bestehende Pipeline. Transparenz + Compliance + Jira-artig. | ✅ entschieden |
| **D6** | Trigger/Scheduler-Auto-Subscribe-Cap | **BESCHLOSSEN:** D4-Hard-Cap (50) im Subscribe-Pfad selbst erzwingen (nicht nur im Controller), damit Trigger ihn nicht umgehen. `mentionable?`+`show?` verhindert bereits Subscriben ohne Ticket-Zugriff. | ✅ entschieden |
| **D7** | Migrations-Rails-Version & Klassenname | **BESCHLOSSEN (verifizieren):** echte Zammad-Rails-Version aus `Gemfile.lock`/`Rails.version` lesen, Core + Plugin auf **dieselbe** `Migration[X.Y]`; Klasse `AddTicketParticipantsSettings` statt `Settings`. | ✅ entschieden |

---

## 8. Findings – konsolidierter Status (23)

| # | Finding | Schwere | im Master-Code gelöst? |
|---|---|:--:|:--:|
| 1 | `Setting.get` im Initializer vor Tabellen-Existenz | 🟡 | ✅ Table-Check |
| 2 | Package-Migration unter `db/addon/` | 🟡 | ✅ Pfad korrekt |
| 3 | `customer_field_scope` truthy | 🟢 | ✅ keine Aktion |
| 4 | Teilnehmer könnten updaten | 🔴 | ✅ §4.1 `update?` |
| 5 | ReadScope fehlt | 🔴 | ✅ §4.4 |
| 6 | `create_mentions?` zu restriktiv | 🟡 | → D2 |
| 7 | `subscribed`-Kriterium existiert | 🟢 | ✅ keine Aktion |
| 8 | `group_access?` filtert Teilnehmer | 🔴 | ✅ §4.5 |
| 9 | `notification_config` fehlt für Kunden | 🟡 | ✅ Default-Matrix |
| 10 | CC→User existiert, CC→Mention fehlt | 🟢 | ✅ Phase 7 Lesart a: bestehende Teilnehmer in CC korrekt behandelt |
| 11 | Postmaster-Reihenfolge | 🟢 | ✅ PostFilter passt |
| **NEU-27** | **Auto-CC:** Eingehende CC-Empfänger automatisch als Teilnehmer hinzufügen (Lesart b) — geparkt wegen DSGVO-Frage (Absender bestimmt Zugriff). | 🟡 | ⬜ Entscheidung steht aus |
| 12 | N+1 in `participant?` | 🟡 | ✅ `participant_ids` (cave D1) |
| 13 | Notification-Spam | 🔴 | → D4 (eine Zahl!) |
| 14 | GraphQL-Mutationen registriert | 🟡 | ⬜ in Phase 5 verifizieren |
| 15 | `id_from_internal_id` | 🟢 | ✅ korrekt |
| 16 | `import.meta.glob` = Build-time | 🟡 | ✅ Precompile in Phase 9 |
| 17 | Settings-Types generieren | 🟡 | ✅ Precompile in Phase 9 |
| 18 | `dependent: :destroy` User | 🟢 | ✅ **existiert** (s. §5) |
| 19 | Deaktivierter User bleibt Teilnehmer | 🟡 | ✅ §4.1 `active?` |
| 20 | Ticket-Löschung → Mentions | 🟢 | ✅ existiert |
| 21 | Trigger/Scheduler subscriben | 🟡 | → D6 |
| 22 | `mentionable?` prüft Ticket-Zugriff nicht | 🔴 | ✅ §4.3 `show?` |
| 23 | Online-Notification-Seen | 🟢 | ✅ keine Aktion |
| **24** | **Internal-Article-Mail-Leak (Subscriber-Pipeline).** Ohne Filter würden interne Notizen an Teilnehmer gemalt. Fix: Guard in `send_to_single_recipient` (`article.internal? && !user.permissions?('ticket.agent')` → skip). Belegt durch Specs IG1-3 (11 grün) + Mailcatcher (3 Cases). Commit `69ca91e`. | 🔴 | ✅ gefixt |
| **NEU-24** | … | 🟡 | ⬜ |
| **NEU-25** | … | 🟡 | ⬜ |
| **NEU-26** | … | 🔴 | ⬜ |
| **NEU-28** | … | 🟡 | ⬜ |
| **NEU-29** | **Overview-Lücke: Teilnehmer sieht Ticket nicht in seiner Übersicht.** Die ReadScope enthält das Ticket korrekt, aber die Overview-Filter (`customer_id = current_user`) blenden es aus. Teilnehmer erreichen das Ticket nur via Mail-Link oder direkte URL. Optionen: (a) MVP akzeptieren (0 Tage), (b) Neue Overview "Meine Teilnahmen" (1-2 Tage), (c) "Meine Tickets" um Participant-Tickets erweitern (0,5 Tage). Entscheidung hängt am Zweck (intern vs. PR). | 🟡 | ⬜ Produktentscheidung ausstehend |

---

## 9. Security-/GDPR-Checkliste vor Go-Live

```
□ TicketPolicy#customer_access? enthält participant?-Check
□ Teilnehmer sehen KEINE internal:true-Artikel im Web (ArticlePolicy, erbt Customer-Verhalten)
□ Teilnehmer erhalten KEINE Mail mit internem Artikel-Inhalt (Finding #24: internal?-Guard in Transaction::Notification, Specs IG1-3, Mailcatcher verifiziert)
□ Teilnehmer sehen KEINE anderen Tickets des Kunden
□ ReadScope filtert korrekt UND konsistent zu participant_ids (D1)
□ Mention-Löschung entzieht Zugriff SOFORT (cache-loses Design, D1 – beim nächsten Request)
□ User-Löschung löscht Mentions (dependent: :destroy – existiert)
□ Audit-Log für Add/Remove (HasHistory – existiert, verifizieren)
□ Feature-Flag an/aus getestet
□ Hard-Cap 50 Teilnehmer greift (auch via Trigger – D6)
□ „Sie wurden hinzugefügt"-Mail implementiert (D5)
□ Opt-out (Benachrichtigungen): existiert via notification_config ✅
□ Opt-out (Self-Remove): → NEU-28 (geparkt, Policy-Knoten ungelöst)
□ DSGVO-Doku/Datenschutzerklärung aktualisiert
□ Call-Site-Sweep mentionable? (NEU-24, 3 Stellen): kein Self-Subscribe zu fremden Tickets
□ Internal-Article-Mail-Guard (Finding #24): Specs IG1-3 + Mailcatcher verifiziert ✅
```

---

## 9b. Benachrichtigungs-Architektur

Teilnehmer werden über die **Transaction::Notification-Subscriber-Pipeline** benachrichtigt
(dieselbe, die Agenten nutzt). Dies ist eine bewusste Architekturentscheidung:

| Aspekt | Subscriber-Pipeline (unsere Wahl) | Trigger-System (Alternativ) |
|--------|-----------------------------------|----------------------------|
| Aktivierung | Automatisch via Mention | Admin muss Trigger konfigurieren |
| Empfänger | Alle Subscriber des Tickets | Explizit konfiguriert |
| Wartung | Keine (automatisch) | Trigger-Pflege nötig |
| Interner Artikel-Schutz | Musste nachgerüstet werden (Finding #24) | Admin muss selbst filtern (article type ≠ note) |

Der **internal?-Guard** (`transaction/notification.rb:191-197`) stellt sicher, dass
interne Notizen NUR an Agenten gemalt werden — nicht an Teilnehmer (Kunden-Level).
Commit `69ca91e`, 11 Specs (IG1-3), Mailcatcher-verifiziert (3 Cases). Siehe Finding #24.

### Bekannte MVP-Grenze: Overview-Lücke (→ NEU-29)

---

## 10. Verifikationsstatus

**Ruby-LSP-Sweep abgeschlossen.** Die Zeilennummern und Aufruf-Graphen sind jetzt **symbol-basiert**
(nicht mehr nur grep) verifiziert:

- `customer_access?` `ticket_policy.rb:103–108` · `change_access?` `:88–95` · `agent_read_access?` `:52` ·
  `create_mentions?` `:63–67` · `mentionable?` `mention.rb:110–117` · `prepare_recipients_and_reasons`
  `notification.rb:77–118`. (Hinweis: `mentionable?` beginnt bei **110**, nicht 111.)
- **Wichtige Korrektur:** `mentionable?` hat **3** Referenzen (`MentionValidator`,
  `MentionsControllerPolicy`, Trigger), **nicht 6**. Die alte „6 von 8"-Zahl vermischte die 5
  `subscribe!`-Aufrufer mit den `mentionable?`-Aufrufern. → Phase 3 / NEU-24 verkleinert.
- `create_mentions?`: außerhalb von Pundit **keine** Produktions-Referenzen → gefahrlos Agent-only zu belassen (stützt D2).

**Verbleibend:** Vor jedem `develop`-Rebase den Sweep kurz wiederholen, da Zeilennummern driften können.

---

## 11. Top-Risiken

| # | Risiko | Mitigation |
|---|---|---|
| 1 | Policy-Änderung bricht Agent-Zugriff | Phase 0 Baseline-Tests **vor** jeder Änderung; Feature-Flag |
| 2 | ~~Cache/ReadScope-Asymmetrie~~ → **gelöst (D1)**: cache-loses Design | Erledigt; in Phase 2 per Test bestätigen (entfernter Teilnehmer = sofort kein Zugriff) |
| 3 | `mentionable?` öffnet **3** Call-Sites (LSP-verifiziert, nicht 6) | NEU-24: je 1 Test, v.a. REST-Self-Subscribe |
| 4 | Upgrade-Inkompatibilität künftiger Zammad-Versionen | Änderung minimal halten; Plugin als Fallback; PR anstreben |
| 5 | Zeilennummern driften bei `develop`-Rebase | §10: LSP-Sweep vor jedem Rebase kurz wiederholen |
| **6** | **Doku-vs-Code-Drift** an sicherheitskritischen MASTER-Stellen (§4.x) | Bei jeder Symbol-Änderung MASTER mitziehen. Vor PR und Produkt-2-Start vollständig gegen Code prüfen (Drift-Check 12.06.2026 = durchgeführte Vorlage). Gleiche Fehlerklasse wie Test-vs-Code-Drift. |

---

## 12. Nächste Schritte (Stand 18.06.2026)

Produkt 1 + 2 INTERN VOLLSTÄNDIG. Verbleibend:

### Vor-Release-Politur (Risiko-Reihenfolge)

| # | Punkt | Risiko | Aufwand |
|---|-------|:---:|:---:|
| **PR-1** | **PR-QA-1 (G1 Browser-Check):** Self-Subscribe-Guard im echten Pfad (REST-API via Token-Auth) — KERN+GGEN belegt | ✅ abgeschlossen | 0,25 Tage |
| **PR-2** | **PR-QA-2 (active-Filter Spec):** 3 Pfade spec-belegt — participant? (AF1-2), ReadScope (AF3-4), participant_ids (AF5-6 + GraphQL) | ✅ abgeschlossen | 0,25 Tage |
| **PR-3** | **Apollo Error 88:** REST-Suche durch GraphQL `autocompleteSearchGeneric` ersetzt, Browser-getestet (Add-Kette, Badge, Mailcatcher) | ✅ abgeschlossen | 0,5 Tage |
| **PR-4** | **🔴-Stellen umstrukturiert:** base_scope.rb → `append_participant_scope!`, notification.rb → `mention_user_eligible?` | ✅ abgeschlossen | 0,5 Tage |
| **PR-5** | **Commit-Historie squashen** (18 → ~5 logische) + AGPL-Konventionen | 🟡 PR-Akzeptanz | 0,25 Tage |

### Customer-Self-Action-Epik (geparkt, Folgephase)
- [ ] NEU-27: Auto-CC (eingehende CC-Empfänger automatisch als Teilnehmer, mit Jira-Gates) — geparkt, Entscheidung steht aus
- [ ] Policy-Spur für Customer-Self-Actions lösen (Actor+Ticket+Target, kein Agent-Gate)
- [ ] NEU-26: Customer-Self-Add (Kunden fügen selbst Teilnehmer hinzu) — 🔴
- [ ] NEU-28: Customer-Self-Remove (Kunden entfernen sich selbst) — 🟡 (niedrigeres Risiko)

---

## 13. Wiederaufnahme / Übergabe

> **Stand:** 18.06.2026 · Produkt 1 + 2 intern vollständig · Vor-Release-Politur ist nächster Schritt.

### Wo das Projekt steht
- **Produkt 1 (Vue-Desktop):** Backend 56/56 Tests grün, Frontend QA 10/10 bestanden, Phase 7a+8 abgeschlossen. Teilnehmer-Badge.
- **Produkt 2 (alte jQuery-UI):** Browser-verifiziert. Add/Remove, Badge, Flag-Gate, Nicht-Agent-Gate.
- **Geparkt:** NEU-26 (Self-Add), NEU-27 (Auto-CC), NEU-28 (Self-Remove), NEU-29 (Overview-Lücke).

### Nächster Schritt: PR-5 (Commits squashen + AGPL-Konventionen)
- base_scope.rb, notification.rb, MutationHandler.ts strukturieren
- Aufwand: 0,5 Tage
- REST-Workaround ersetzen durch native FormKit-Integration
- Aufwand: 0,5 Tage

### Wiedereinstieg
```bash
cd C:\AI\zammad-jira-participants-analysis
# Git Mirror sync: cd C:\AI\zammad && git fetch wsl2 && git merge --ff-only wsl2/feature/ticket-participants
# Devcontainer: docker exec -u vscode zammad-devcontainer-devcontainer-1 bash -lc "..."
# Serena: serena_activate_project C:\AI\zammad
```
