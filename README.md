# English Coach — Supabase Setup

## Dateien
- `supabase_schema.sql`: vollständiges Schema, RLS, Review-Funktion und Seed-Wörter
- `CONTEXT.md`: Produkt- und Lernkontext
- `LEARNING_PROFILE.md`: aktuelles Lernprofil
- `LEARNINGS.md`: bestätigte Coach-Regeln

## Installation
1. Neues Supabase-Projekt erstellen.
2. Im SQL Editor `supabase_schema.sql` vollständig ausführen.
3. Einen Benutzer über Supabase Auth anlegen oder anmelden.
4. Im Abschnitt `OPTIONAL INITIALIZATION` die User-ID einsetzen und die beiden Inserts ausführen.
5. Danach kann der Voice-Agent vor jeder Session `review_queue`, `coach_learnings`, `sentences` und `learning_profiles` laden.

## Minimaler Agent-Ablauf
1. Benutzer authentifizieren.
2. Fällige Wörter aus `review_queue` laden.
3. Session-Plan erstellen und in `session_plans` speichern.
4. Genau eine Aufgabe stellen.
5. Antwort als `attempt` speichern.
6. `apply_review_result(...)` aufrufen.
7. Nächste Aufgabe aus dem bestehenden Plan wählen.
8. Nach der Session `learning_sessions` zusammenfassen.
9. Nutzerkorrekturen als `learning_cases` speichern.
10. Bestätigte Regeln in `coach_learnings` übernehmen.

## Empfohlener Start
Zuerst nur:
- Englisch → Deutsch
- Deutsch → Englisch
- kurze Satzbildung
- Review-Termine

Dialoge, Geschichten und freie Sprechphasen erst ergänzen, sobald der persistente Grundloop zuverlässig funktioniert.
