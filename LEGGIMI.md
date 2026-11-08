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
| `logo.png` | **Da aggiungere tu**: lo stemma mostrato in alto a sinistra e nelle stampe (va bene anche `logo.jpg`). Se manca, l'app mostra uno stemma di riserva. |
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
2. Salva lo stemma come **`logo.png`** in questa cartella (stesso nome, tutto minuscolo).
3. Doppio clic su **`APRI_APP.bat`**.
4. Si apre Microsoft Edge su `http://localhost:5040`. Se non si apre da solo,
   vai a quell'indirizzo con qualunque browser.
5. Per chiudere: chiudi la finestra PowerShell minimizzata.

> La porta è la **5040**: diversa da OSL TRIESTE (5030), quindi le due app
> possono girare insieme sullo stesso PC. Per cambiarla modifica `$Port` in
> `server.ps1` e l'indirizzo in `APRI_APP.bat`.

## Come si usa

Il **menu laterale** si apre e si chiude con il pulsante ☰ in alto a sinistra:
**Cronologia**, **Storico**, **Statistiche**. In alto a destra ci sono data,
ora **locale** e ora **Zulu**, e lo stato del server. Ogni salvataggio riuscito
è confermato da un piccolo avviso in alto a destra.

### Cronologia (giorno in corso)

A sinistra le righe della cronologia di oggi; a destra il pannello comandi
in tre aree. I pulsanti selezionati **restano premuti** fino alla registrazione.

1. **A/C**: il pulsante **+** apre la finestra *Aeromobili*:
   - **Nuovo A/C**: Callsign, Side Number, Gruppo Volo, Tipo. Resta in archivio
     per sempre, non va più riscritto.
   - **Archivio**: filtra per **Tipo**, cerca, e con l'interruttore decidi quali
     aeromobili sono **in gestione** (visibili come pulsanti in Cronologia).
     "Tutti / Nessuno in gestione" agisce sul filtro corrente.
   - Sul pulsante di un A/C, la **×** (al passaggio del mouse) lo toglie dalla
     gestione: resta in archivio. Il badge in alto mostra l'ultima posizione
     nota oggi (`S3`, `HGR`, `VOLO`).
   - Puoi selezionare **più A/C insieme**: viene registrata una riga per ciascuno.
2. **Eventi**: pulsanti minimal personalizzabili (**+** per aggiungere, matita
   per modificare, ordinare, nascondere o eliminare). Alcuni aprono una piccola
   finestra:
   - **Move**: da / a (Hangar, Spot 1–9). La conferma registra subito il movimento.
   - **Fuel**, **HotRef**: Inizio / Fine; su Fine anche i **litri**. Se l'ultima
     registrazione dello stesso A/C era "Inizio", propone già "Fine".
   - **Normal OPS**: Endurance e POB.
   - **Personale**: Imbarco o Sbarco e numero di persone.
   - **Elev. Sx / Dx / Mun. Prora / Mun. Poppa**: cosa trasporta (i carichi
     già usati vengono riproposti con un clic).
   - **Testo**: testo libero per gli eventi fuori norma.
   - **Tacchi** e **Rizze** si possono selezionare **insieme** (eventi
     "combinabili", impostabili anche per gli eventi nuovi).
3. **Spot**: 1–9, Hangar, Isole. **Toccando uno spot l'evento viene registrato
   subito** con data e ora. Se l'evento non ha spot premi **SALVA** in basso a
   destra (oppure **F2**).

Sequenza tipica: **A/C → Evento → Spot** (registrato).
`Esc` annulla la selezione. Su ogni riga: **matita** per modificare (ora,
A/C, evento, dettagli, spot) e **cestino** per eliminare (con conferma).
Il pulsante con le frecce inverte l'ordine (più recenti in alto o in basso).
**Stampa** produce il registro del giorno in A4 orizzontale, con lo spazio
per la firma del Controllore di Torre.

### Storico

Calendario mensile in cui sono **evidenziati solo i giorni con cronologia
salvata** (con il numero di eventi). Clic su un giorno per caricarlo; frecce
per passare al giorno precedente o successivo con cronologia. Le righe si
possono modificare ed eliminare; **Stampa** e **CSV** (apribile con Excel)
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
