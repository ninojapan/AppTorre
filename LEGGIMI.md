# Cronologia Guzzi Twr

Web app locale per registrare la **cronologia degli eventi della Torre di
Controllo** con pochi clic e quasi senza scrivere. Nessuna installazione e
nessuna libreria esterna: usa solo **PowerShell** integrato di Windows più un
browser. Funziona anche **offline**. Si avvia come *Gestione O.S.L. Nave TRIESTE*.

## File della cartella

| File | Descrizione |
|------|-------------|
| `APRI_APP.bat` | **Avvio quotidiano**: doppio clic. Chiude solo il server di questa app se era rimasto aperto, avvia il server minimizzato e apre il browser. |
| `start-server.bat` | Avvio manuale del solo server (utile per debug o percorsi di rete UNC). |
| `server.ps1` | Server HTTP in PowerShell puro su `http://localhost:5040`. |
| `Cronologia Guzzi Twr.html` | L'app in un unico file (HTML, CSS e JS). |
| `logo.png` | Stemma di Nave TRIESTE (L9890) mostrato in alto a sinistra e nelle stampe. Per cambiarlo basta sostituire il file (va bene anche `logo.jpg`); se manca, l'app usa una versione vettoriale dello stemma inclusa nel codice. |
| `DATI/` | **Database locale, creato in automatico** (vedi sotto). |

### Database locale (`DATI/`)

| Percorso | Contenuto |
|----------|-----------|
| `DATI/config.json` | Archivio aeromobili, elenco eventi personalizzati, impostazioni. |
| `DATI/cronologia/AAAA-MM-GG.json` | Un file per ogni giorno con cronologia. |
| `DATI/backup/` | Copia della versione precedente, creata a ogni salvataggio. |

I salvataggi sono **atomici**: il file viene scritto su un file temporaneo e poi
sostituito, così non resta mai scritto a metà (es. mancanza di corrente).
Per spostare l'app su un altro PC basta copiare l'intera cartella, `DATI`
compresa. La cartella `DATI/` non viene caricata su GitHub (`.gitignore`).

## Come si avvia

1. Copia l'intera cartella su un PC **Windows**.
2. Doppio clic su **`APRI_APP.bat`**.
3. Si apre Microsoft Edge su `http://localhost:5040`. Se non si apre da solo,
   vai a quell'indirizzo con qualunque browser.
4. Per chiudere: chiudi la finestra PowerShell minimizzata.

> La porta è la **5040**: diversa da OSL TRIESTE (5030), quindi le due app
> possono girare insieme sullo stesso PC. Per cambiarla modifica `$Port` in
> `server.ps1` e l'indirizzo in `APRI_APP.bat`.

## Come si usa

Il **menu laterale** si apre e si chiude con il pulsante ☰ in alto a sinistra:
**Cronologia**, **A/C in Volo**, **Storico**, **Statistiche**. Sugli schermi
più stretti di 1500 px (es. portatili 1366×768) il menu si apre sopra il
contenuto e si chiude scegliendo una sezione o con un clic sul velo scuro.
In alto a destra ci sono data,
ora **locale** e ora **Zulu**, e lo stato del server. Ogni salvataggio riuscito
è confermato da un piccolo avviso in alto a destra.

### Cronologia (giorno in corso)

A sinistra le righe della cronologia di oggi; a destra il pannello comandi
in tre aree. I pulsanti di A/C ed Eventi sono tasselli tutti della stessa
misura. I pulsanti selezionati **restano premuti** fino alla registrazione.

1. **A/C**: il pulsante **+** apre la finestra *Aeromobili*:
   - **Nuovo A/C**: Callsign, Side Number, Gruppo Volo, Tipo. Resta in archivio
     per sempre, non va più riscritto.
   - **Archivio**: filtra per **Tipo**, cerca, e con l'interruttore decidi quali
     aeromobili sono **in gestione** (visibili come pulsanti in Cronologia).
     "Tutti / Nessuno in gestione" agisce sul filtro corrente.
   - Sul pulsante di un A/C, la **×** (al passaggio del mouse) lo toglie dalla
     gestione: resta in archivio. Il badge in alto mostra l'ultima posizione
     nota (`S3`, `HGR`, `VOLO`).
   - Puoi selezionare **più A/C insieme**: viene registrata una riga per ciascuno.
2. **Eventi**: pulsanti minimal personalizzabili (**+** per aggiungere, matita
   per modificare, ordinare, nascondere o eliminare).
   - **Abbinati a un A/C**: **Move, Tacchi, Rizze, Fuel, HotRef, APU/IPP, MIM,
     Ingaggio, Decollo, Normal OPS, Appontaggio, Personale, Norco Lock, Fold,
     Unfold** richiedono un A/C selezionato: senza A/C compare un errore, l'area
     A/C si evidenzia in rosso e **non viene salvato nulla**.
   - **Salvataggio immediato**: se l'A/C selezionato ha **già uno spot assegnato**
     (1–9, Hangar, Isole: lo vedi nel badge sul pulsante dell'A/C) l'evento viene
     registrato **subito su quello spot**, alla conferma della finestra per Fuel,
     HotRef e Personale. Con più A/C selezionati, ogni riga prende lo spot del suo
     A/C. Se l'A/C non ha uno spot (es. **in volo**), l'evento resta selezionato e
     si tocca lo spot (es. l'Appontaggio) oppure si preme **SALVA**.
   - **Tacchi + Rizze**: se premi Rizze (o Tacchi) sullo stesso A/C entro 2 minuti
     dall'altro, viene aggiunto alla stessa riga ("Tacchi + Rizze").
   - **Decollo** solo per A/C a terra: se l'A/C risulta già in volo compare
     l'errore "Decollo: … è già in volo" e non si salva nulla (vale anche nella
     modifica di una riga). Per farlo ripartire serve prima l'**Appontaggio**.
   - **Un clic** (icona ⚡): **Ops di volo, FodWalk, Deck Ready, Prova Semaforo,
     Giallo, Rosso, Verde** vengono registrati subito, senza A/C né spot.
     Gli A/C eventualmente selezionati restano selezionati.
   - Alcuni eventi aprono una piccola finestra (icona …):
   - **Move**: da / a (Hangar, Spot 1–9, Isole). La conferma registra subito il movimento.
     **Serve almeno un A/C selezionato**: senza A/C compare l'errore "Move: seleziona prima
     l'A/C da movimentare", l'area A/C si evidenzia in rosso e la finestra non si apre.
   - **Fuel**, **HotRef**: Inizio / Fine; su Fine anche i **litri**. Se l'ultima
     registrazione dello stesso A/C era "Inizio", propone già "Fine".
   - **Normal OPS**: **Endurance** con un orologio per impostare l'**ora di
     termine dell'autonomia** (frecce ore e minuti, oppure +30′, +1h, +1h30… da
     adesso), **POB** e **Weapon** (testo libero; gli armamenti già usati vengono
     riproposti). L'autonomia residua appare subito in verde, giallo o rosso.
     **Solo per A/C in volo** (dopo il **Decollo**): con un A/C a terra compare
     l'errore "Normal OPS: … non è in volo — registra prima il Decollo" e non si
     salva nulla. Per un A/C in volo si registra **subito alla conferma** della
     finestra (senza spot né Salva).
   - **Personale**: Imbarco o Sbarco e numero di persone.
   - **Elev. Sx / Dx / Mun. Prora / Mun. Poppa**: cosa trasporta (i carichi
     già usati vengono riproposti con un clic). **Registra** nella finestra
     scrive subito la riga, senza premere Salva.
   - **Testo**: testo libero per gli eventi fuori norma.
   - **Tacchi** e **Rizze** si possono selezionare **insieme** (eventi
     "combinabili", impostabili anche per gli eventi nuovi).
   - Nella finestra di modifica di ogni evento, la voce **Registrazione** sceglie
     come si registra: *standard* (spot o Salva), *subito* (al clic o alla
     conferma, con gli A/C selezionati) oppure *un clic* (subito, senza A/C né spot).
     Le opzioni **Solo per A/C in volo** (Normal OPS) e **Solo per A/C a terra**
     (Decollo) si possono attivare anche su altri eventi.
     L'opzione **Richiede un A/C selezionato** blocca l'evento con un errore se
     nessun A/C è selezionato e lo registra subito se l'A/C è già su uno spot;
     puoi attivarla o disattivarla per ogni evento.
3. **Spot**: 1–9, Hangar, Isole. **Toccando uno spot l'evento viene registrato
   subito** con data e ora. Se l'evento non ha spot premi **SALVA** in basso a
   destra (oppure **F2**).

Sequenza tipica: **A/C → Evento** (registrato subito se l'A/C è già su uno spot),
altrimenti **A/C → Evento → Spot**.
`Esc` annulla la selezione. Su ogni riga: **matita** per modificare (ora,
A/C, evento, dettagli, spot, note) e **cestino** per eliminare (con conferma).

**Colonna Note** (dopo *Evento · dettagli*): **clic sulla cella** per scrivere o
modificare la nota direttamente nella riga. **Invio** salva, **Maiusc+Invio** va a
capo, **Esc** annulla; anche cliccando altrove la nota viene salvata. Le note
compaiono anche nella stampa e nel CSV, e si possono modificare pure dallo Storico.
Il pulsante con le frecce inverte l'ordine (più recenti in alto o in basso).
**Stampa** produce il registro del giorno in A4 orizzontale, con lo spazio
per la firma dell'AUCV.

### A/C in Volo

Un riquadro per ogni aeromobile in volo con **Callsign**, **Side**, **POB**,
**Weapon** e **autonomia residua** in ore e minuti, aggiornata ogni secondo.
Il bordo è **verde** con 1 ora o più, **giallo** da 30 a 59 minuti, **rosso**
sotto i 30 minuti (lampeggia se l'autonomia è scaduta). Un A/C compare dopo il
**Decollo** e sparisce con l'**Appontaggio** o con uno spot.
POB, Weapon e ora di termine vengono dall'ultimo **Normal OPS** di quel volo.

- **Normal OPS** sul riquadro: aggiorna i dati (finestra già compilata) e lo registra in cronologia.
- **Appontaggio** sul riquadro: torna alla Cronologia con A/C ed evento già
  selezionati; basta toccare lo spot.
- Nel menu, accanto ad *A/C in Volo*, il numero di A/C in volo è colorato con lo
  stato più critico.

**Avviso autonomia**: in qualunque sezione ti trovi, quando un A/C in volo scende
**sotto i 60 minuti** (giallo) si apre una finestra di avviso; una seconda quando
scende **sotto i 30 minuti** (rosso, bordo lampeggiante). La finestra mostra
Callsign, Side, tipo, autonomia residua aggiornata al secondo, ora di termine e
POB; più A/C insieme compaiono nella stessa finestra. Si chiude solo con
**Preso visione** (o **Vai ad A/C in Volo**), non cliccando fuori. Ogni avviso
compare una sola volta per soglia, anche dopo aver ricaricato la pagina; con un
nuovo **Normal OPS** (nuova ora di termine) gli avvisi ripartono.

### Storico

Calendario mensile in cui sono **evidenziati solo i giorni con cronologia
salvata** (con il numero di eventi). Clic su un giorno per caricarlo; frecce
per passare al giorno precedente o successivo con cronologia. Le righe si
possono modificare ed eliminare e le note si scrivono con un clic sulla cella;
**Stampa** e **CSV** (apribile con Excel)
per il giorno selezionato.

### Statistiche

Periodo: Oggi, 7 giorni, 30 giorni, Questo mese, Quest'anno, Tutto oppure
date a scelta. Mostra:

- **decolli e appontaggi** per tipo di aeromobile e per spot;
- **movimentazioni elevatori** Sx, Dx, munizioni Prora e Poppa;
- **litri di carburante** (Fuel e HotRef, registrati alla Fine) per tipo A/C;
- **persone imbarcate e sbarcate**;
- conteggio di tutti gli eventi registrati.

Per gli eventi personalizzati puoi scegliere, dalla finestra di modifica,
se e come contarli nelle statistiche (es. un nuovo evento conteggiato come
"Decollo").

### Backup

Nel menu laterale, **Esporta backup completo** scarica un unico file `.json`
con archivio, eventi e tutte le cronologie.
