var Config = {};
Config.Routes = {};
Config.NavBar = {};
Config.NavBarRight = {};
Config.product_name = 'Zammad'
Config.requested_url = ''
var Store = {};
var Session = {};
var Trans = {
  'New': 'Neu',
  'Create': 'Erstellen',
  'Cancel': 'Abbrechen',
  'Submit': 'Übermitteln',
  'Sign out': 'Abmelden',
  'Profile': 'Profil',
  'Settings': 'Einstellungen',
  'Overviews': 'Übersichten',
  'Manage': 'Verwalten',
  'Users': 'Benutzer',
  'Groups': 'Gruppen',
  'Group': 'Gruppe',
  'Organizations': 'Organisationen',
  'Organization': 'Organisation',
  'Recent Viewed': 'Zuletzt angesehen',
  'Security': 'Sicherheit',
  'From': 'Von',
  'Title': 'Titel',
  'Customer': 'Kunde',
  'State': 'Status',
  'Created': 'Erstellt',
  'Attributes': 'Attribute',
  'Direction': 'Richtung',
  'Owner': 'Besitzer',
  'Subject': 'Betreff',
  'Priority': 'Priorität',
  'Select the customer of the Ticket or create one.': 'Wähle den Kunden eine Tickets oder erstell einen neuen.',
  'New Ticket': 'Neues Ticket',
  'Firstname': 'Vorname',
  'Lastname': 'Nachname',
  'Phone': 'Telefon',
  'Street': 'Straße',
  'Zip': 'PLZ',
  'City': 'Stadt',
  'Note': 'Notiz',
  'New User': 'Neuer Benutzer',
  'new': 'neu',
  'closed': 'geschlossen',
  'open': 'offen',
  'pending': 'warten',
  'Activity Stream': 'Aktivitäts-Stream',
  'updated': 'aktuallisierte',
  'My assigned Tickets': 'Meine zugewisenen Tickets',
  'Unassigned Tickets': 'Nicht zugewisene/freie Tickets',
  'All Tickets': 'Alle Tickets',
  'Escalated Tickets': 'Eskallierte Tickets',
  'My pending reached Tickets': 'Meine warten erreicht Tickets',
  'Password': 'Passwort',
  'Password (confirm)': 'Passwort (bestätigen)',
  'Roles': 'Rollen',
  'Active': 'Aktiv',
  'Edit': 'Bearbeiten',
  'Base': 'Basis',
  'Number': 'Nummer',
  'Sender Format': 'Absender Format',
  'Authentication': 'Authorisierung',
  'Product Name': 'Produkt Name',
  'To': 'An',
  'Customer': 'Kunde',
  'Linked Accounts': 'Verknüpfte Accounts',
}
var T = function(string) {
  if ( Trans[string] !== undefined ) {
    return Trans[string];
  }
  return string;
}
