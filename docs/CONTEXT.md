# CONTEXT.md — Persönlicher Englisch-Coach

## Problem
Der Nutzer befindet sich aktuell ungefähr auf B-Niveau und möchte sein Englisch systematisch bis zu Advanced/C beziehungsweise Business Advanced entwickeln. Das Kernproblem ist nicht nur fehlendes Wissen, sondern der noch nicht schnelle, sichere und flüssige Abruf beim Verstehen und Sprechen.

## Persona
Einziger Nutzer ist der Lernende selbst. Das System wird ausschließlich auf seine Lernhistorie, seinen Wortschatz, seine Fehlerbilder und seine Ziele optimiert.

## Kosten heute
Das Problem kostet vor allem Zeit. Ohne klare Struktur, Wiederholungslogik und dauerhaftes Lernprofil wird bereits Gelerntes vergessen, Übungen wirken zufällig und der Fortschritt ist langsamer als nötig.

## Zielbild
Der Coach dient als persönlicher Voice-Sparringspartner für:
- flüssigeres Sprechen
- besseres Hör- und Sprachverständnis
- schnellen aktiven Wortabruf
- sichere Gespräche im Alltag
- später Business-Gespräche, Meetings, Kundengespräche und Verhandlungen

## Erfolgskriterien

### 30 Tage
- tägliche oder regelmäßige strukturierte Voice-Sessions
- sichtbarer aktiver Wortschatzaufbau
- bekannte Wörter schneller und stabiler abrufen
- 3–5 Minuten über vertraute Themen frei sprechen
- weniger wiederkehrende Verwechslungen bei bereits trainierten Wörtern

### 90 Tage
- 500–1.000 Wörter aktiv und kontextbezogen abrufbar
- 5–10 Minuten frei und verständlich sprechen
- normale Gespräche und einfache Business-Gespräche sicher verstehen
- Kundengespräche und Meetings mit deutlich weniger Suchpausen führen
- steigender Anteil an Übungen ohne menschliche Korrektur

## Scope

### Im Scope
- Voice-basiertes Lernen
- Wortschatz und aktiver Abruf
- Hörverständnis
- Sprachfluss
- Satzbildung
- alltagsnahe Grammatik im Kontext
- Small Talk
- Kundengespräche
- Meetings
- Verhandlungen
- adaptive Wiederholung
- Zeitformen und Wortformen bei relevanten Verben
- Geschichten und Dialoge auf Basis gelernter Wörter

### Nicht im Scope
- Prüfungsenglisch
- akademische Grammatik
- klassisches Schreibtraining
- Themen ohne Bezug zum Alltag oder Business-Kontext
- Optimierung für mehrere Nutzer
- externe menschliche Tester in der ersten Phase

## Priorisierte Learning Stories

### Priorität 1 — Alltag und Small Talk
1. Als Lernender möchte ich einfache Gespräche mit anderen Menschen verstehen und natürlich weiterführen.
2. Als Lernender möchte ich über Alltag, Arbeit, Ziele und Interessen mehrere Minuten frei sprechen.
3. Als Lernender möchte ich Wörter nicht nur erkennen, sondern spontan aktiv abrufen.
4. Als Lernender möchte ich typische Rückfragen verstehen und sinnvoll beantworten.

### Priorität 2 — Business
5. Als Lernender möchte ich Kundengespräche sicherer führen.
6. Als Lernender möchte ich in Meetings Meinungen, Updates und nächste Schritte ausdrücken.
7. Als Lernender möchte ich später besser verhandeln und Argumente klar formulieren.

### Ergänzende System-Stories
8. Als Lernender möchte ich, dass alte Wörter automatisch wiederholt werden, bevor ich sie vergesse.
9. Als Lernender möchte ich nur wenige passende neue Wörter erhalten, wenn die vorhandenen ausreichend stabil sind.
10. Als Lernender möchte ich, dass der Coach mich ausreden lässt und immer nur eine Aufgabe stellt.
11. Als Lernender möchte ich, dass Verwechslungen und typische Fehler gezielt wiederkommen.
12. Als Lernender möchte ich, dass Fortschritt, Reaktionssicherheit und freie Anwendung getrennt bewertet werden.

## Vorhandene Daten
- hochgeladene Vokabelliste als Ausgangsbasis
- bisherige Voice-Sessions
- bekannte und neue Wörter aus den Gesprächen
- typische Verwechslungen, zum Beispiel:
  - align / clarify / allocate
  - require / requires / required
  - undertake / delegate
  - improve / develop / optimize
- bereits produzierte Beispielsätze und Dialogfragmente
- beobachtete Sprachfluss- und Abrufprobleme

Die Ausgangsdaten werden einmal strukturiert extrahiert und vom Nutzer bestätigt.

## Lernlogik

### Wortzustände
- `new`: noch nicht geprüft
- `recognizing`: Bedeutung wird erkannt
- `learning`: Übersetzung gelingt teilweise
- `active`: Nutzung im Satz gelingt
- `conversational`: spontane Nutzung im Gespräch gelingt
- `stable`: schneller Abruf in mehreren Kontexten
- `lapsed`: zuvor stabil, aktuell wieder unsicher

### Lernstufen
1. Englisch → Deutsch erkennen
2. Deutsch → Englisch aktiv abrufen
3. Wortform und Aussprache wiederholen
4. einfachen Satz bilden
5. Zeitformen oder relevante Varianten anwenden
6. Wort in einer Geschichte erkennen
7. Wort spontan im Dialog verwenden
8. verzögerte Wiederholung in neuem Kontext

Ein Wort gilt erst als stabil, wenn es in mehreren Sitzungen, Richtungen und Kontexten sicher abgerufen wurde.

## Session-Struktur
1. Warm-up mit sicheren alten Wörtern
2. fällige Wiederholungen
3. Fokusblock mit unsicheren Wörtern
4. maximal wenige passende neue Wörter
5. Satzbildung
6. Zeitformen und Varianten
7. Mini-Geschichte oder Mini-Dialog
8. freie Sprechphase
9. kurze Session-Auswertung
10. Speicherung von Cases, Fortschritt und nächsten Wiederholungen

## Adaptive Regeln
- immer nur eine Aufgabe auf einmal
- vollständig warten, bis der Nutzer ausgesprochen hat
- Lösungen nicht vorzeitig nennen
- bei Unsicherheit zuerst Hinweis, dann Teilstück, dann vollständige Lösung
- schwierige Sätze in zwei bis drei sprechbare Teile zerlegen
- Wiederholung Deutsch → Englisch und Englisch → Deutsch
- falsche oder langsame Antworten häufiger wiederholen
- neue Wörter erst ergänzen, wenn ältere ausreichend stabil sind
- bekannte Wörter später in neuen Kontexten erneut prüfen
- nicht zufällig zwischen Übungsarten springen
- Übungen auf dem tatsächlich beobachteten Niveau aufbauen

## Feedback und Validierung
In Phase 1 wird die Qualität ausschließlich durch die KI und das eigene Feedback des Nutzers bewertet. Externe menschliche Tests sind zunächst nicht vorgesehen.

### Hauptkennzahlen
- Anteil korrekter Antworten
- Anteil Antworten ohne Hinweis
- durchschnittliche Reaktionszeit
- aktive Nutzung im Satz
- spontane Nutzung im Gespräch
- Anteil wiederkehrender Fehler
- Anteil Sessions ohne notwendige Regelkorrektur
- Anteil Cases ohne menschliche Korrektur

## Shadow Mode
Der Coach arbeitet zunächst im Shadow Mode:
- Antworten, Fehler und Lernentscheidungen werden protokolliert.
- Der Coach darf Wiederholungen und nächste Übungen dynamisch planen.
- Dauerhafte neue Regeln werden erst nach Bestätigung des Nutzers in `LEARNINGS.md` übernommen.
- Jede direkte Korrektur des Nutzers erzeugt einen Problem→Solution-Case.
- Der Coach fragt bei relevanten Korrekturen, ob daraus eine dauerhafte Regel werden soll.

## Lernspeicher

### LEARNING_PROFILE.md
Enthält:
- aktuelles Niveau
- Ziele
- Wortbestand und Status
- Fehlerbilder
- Reaktionssicherheit
- Grammatik- und Sprachflussbeobachtungen
- Session-Fortschritt
- nächste Wiederholungen

### LEARNINGS.md
Enthält:
- bestätigte Regeln für den Coach
- Problem→Solution-Muster
- bevorzugte Übungsformate
- bekannte Fehlverhalten des Coaches
- versionierte Verbesserungen der Lernlogik

### Case-Log
Jeder relevante Fall erhält:
- Datum
- Kontext
- Status: open → problem → solved → verified
- Problem
- Coach-Verhalten
- Nutzerkorrektur
- Lösung
- mögliche Regel
- Bestätigung
- Verifikation in späterer Session

## Offene Entscheidungen
1. Soll die dauerhafte Speicherung zunächst in Markdown oder direkt in Supabase erfolgen?
2. Wie viele neue Wörter dürfen pro Session maximal eingeführt werden?
3. Welche Reaktionszeit gilt je Lernstufe als „schnell“?
4. Wann steigt ein Wort von `active` zu `conversational` und zu `stable` auf?
5. Wie wird Aussprache in der ersten Version bewertet?
6. Wie werden Daten aus bestehenden Voice-Sessions importiert und bestätigt?
7. Wie oft wird das Case-Log in dauerhafte Regeln destilliert?

## Nächster kleinster Schritt
1. Dieses Dokument bestätigen.
2. Bestehende Vokabelliste und Voice-Historie in ein erstes Lernprofil überführen.
3. Einen manuellen Shadow-Mode-Lauf durchführen.
4. Erst danach das Supabase-Schema und die automatische Entscheidungslogik bauen.
