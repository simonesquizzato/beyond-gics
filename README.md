# 📈 Beyond GICS
### GICS Sectors vs Spectral Clustering sui rendimenti dell'S&P 500 (Q4 2024)

Le azioni dello stesso settore si muovono davvero insieme?
Questo progetto confronta la classificazione settoriale ufficiale **GICS** (Global Industry Classification Standard) con le "comunità" di titoli che emergono dai dati, applicando lo **spectral clustering** agli extra-rendimenti giornalieri delle azioni dell'**S&P 500** nell'ultimo trimestre del 2024.

**Autore:** Simone Squizzato

---

## 📑 Indice

- [Idea del progetto](#-idea-del-progetto)
- [Dataset](#-dataset)
- [Metodologia](#-metodologia)
- [Risultati](#-risultati)
- [Struttura del repository](#-struttura-del-repository)
- [Come riprodurre l'analisi](#-come-riprodurre-lanalisi)
- [Limiti e sviluppi futuri](#-limiti-e-sviluppi-futuri)
- [Riferimenti](#-riferimenti)

---

## 💡 Idea del progetto

Il GICS, sviluppato da S&P e MSCI, assegna ogni azienda a uno degli **11 settori** in base alla sua attività principale. È lo standard di riferimento per costruire portafogli e indici settoriali.

L'ipotesi è che, una volta **rimosso l'effetto del mercato**, i titoli dello stesso settore abbiano rendimenti fortemente correlati. Se i cluster trovati dai dati coincidono con i settori GICS, la classificazione descrive bene il comportamento reale del mercato. Se divergono, esistono dinamiche che attraversano i confini settoriali tradizionali.

---

## 🗄️ Dataset

| Caratteristica | Valore |
|---|---|
| Fonte | [Yahoo Finance](https://finance.yahoo.com/) tramite `quantmod` |
| Periodo | 30/09/2024 – 31/12/2024 |
| Titoli | 497 azioni dell'S&P 500 + l'indice (`^GSPC`) |
| Giorni di contrattazione | 63 |
| Prezzi | Chiusura aggiustata |
| Variabile aggiuntiva | Settore GICS di ciascun titolo |

I rendimenti sono calcolati come **log-rendimenti giornalieri**:

$$r_t = \ln(P_t) - \ln(P_{t-1})$$

Il file finale `log-returns-SP500.csv` ha una riga per titolo, una colonna per giorno e una colonna `gics_sectors`.

**Legenda dei settori GICS**

| Sigla | Settore | Sigla | Settore |
|---|---|---|---|
| `CD` | Consumer Discretionary | `I` | Industrials |
| `CoS` | Communication Services | `IT` | Information Technology |
| `CS` | Consumer Staples | `M` | Materials |
| `E` | Energy | `RE` | Real Estate |
| `F` | Financials | `U` | Utilities |
| `HC` | Health Care | | |

---

## 🔬 Metodologia

### 1. Excess Return Rate (ERR)
Ispirandosi al CAPM, per ogni titolo si stima un modello a un fattore rispetto al rendimento di mercato:

$$R_i = \alpha_i + \beta_i R_m + \epsilon_i$$

Il residuo $\epsilon_i$ (**ERR**) è la parte del rendimento **non spiegata dal mercato**.

### 2. Grafo e Laplaciana normalizzata
- **Matrice di adiacenza**: valore assoluto delle correlazioni tra gli ERR, $S = |R|$ (497 × 497), interpretata come grafo pesato non orientato.
- **Node degree**: $d_i = \sum_j S_{ij}$
- **Laplaciana normalizzata**: $L = I - D^{-1/2} S D^{-1/2}$

> Nel codice si lavora direttamente su $D^{-1/2} S D^{-1/2}$ e se ne prendono gli autovettori associati agli autovalori **più grandi**, che coincidono con quelli associati agli autovalori più piccoli di $L$.

### 3. Spectral clustering
- Calcolo e ordinamento degli autovalori (scree plot / elbow criterion).
- Selezione dei primi **k = 11** autovettori, quanti sono i settori GICS.
- Applicazione del **k-means** (algoritmo di Lloyd) nello spazio ridotto degli autovettori.

### 4. Confronto tra partizioni
- Tabella di contingenza **cluster × settori GICS**, visualizzata come heatmap.
- **Adjusted Rand Index (ARI)**: vale 1 per una sovrapposizione perfetta, 0 per un accordo pari al caso e meno di 0 per un accordo peggiore del caso.

---

## 📊 Risultati

| Metrica | Valore |
|---|---|
| BetweenSS / TotalSS (k-means) | **51.8%** |
| Adjusted Rand Index | **0.148** |

**Heatmap delle correlazioni tra ERR.** Mostra blocchi ("sun spot") di correlazione marcata: esistono co-movimenti tra gruppi di titoli che non dipendono dall'andamento del mercato.

**Settori con forte corrispondenza ai cluster**
- ⚡ **Energy**, 🔌 **Utilities**, 🏢 **Real Estate**: quasi tutti i titoli finiscono in un unico cluster.
- 🏦 **Financials** e 💻 **IT**: coerenti, ma ciascuno diviso in **due cluster** distinti.

**Settori con corrispondenza debole**
- Consumer Discretionary, Consumer Staples, Communication Services, Health Care, Industrials, Materials. Le cause possibili sono una maggiore diversificazione interna, sotto-settori con dinamiche diverse e interconnessioni tra settori.

**Interpretazione**
Un ARI di **0.148** indica una **divergenza significativa** tra la classificazione GICS e la struttura di correlazione reale dei rendimenti. In un trimestre segnato da forti cambiamenti macroeconomici e tecnologici (conflitti in Medio Oriente e in Ucraina, elezioni USA, boom dell'AI), i settori ufficiali spiegano solo in parte come si muovono i titoli.

**Implicazione per i portafogli.** Nei settori Energy, Utilities e Real Estate gli extra-rendimenti dei titoli sono molto simili tra loro. Un portafoglio o un indice composto da un solo di questi settori offre quindi un beneficio di diversificazione ridotto.

---

## 📁 Struttura del repository

```
beyond-gics/
├── 01_Build_Dataset.R                     # Download dei prezzi, log-rendimenti, etichette GICS
├── 02_Spectral_Clustering.R               # ERR, Laplaciana, spectral clustering, ARI
├── log-returns-SP500.csv                  # Dataset generato
├── GICS_vs_Spectral_Clustering.pdf        # Report completo del progetto
└── README.md
```

---

## ▶️ Come riprodurre l'analisi

**Requisiti:** R ≥ 4.0

1. **Clona il repository**
   ```bash
   git clone https://github.com/simonesquizzato/beyond-gics.git
   cd beyond-gics
   ```

2. **Installa i pacchetti R**
   ```r
   install.packages(c("quantmod", "tidyverse", "pheatmap", "mclust"))
   ```

3. **(Opzionale) Rigenera il dataset**
   ```r
   source("Simone-Squizzato-Dataset-Creation.R")
   ```
   Lo script scarica i prezzi da Yahoo Finance e salva `log-returns-SP500.csv`. Alcuni ticker potrebbero non essere più disponibili, ad esempio per delisting o fusioni avvenuti dopo il 2024.

4. **Esegui l'analisi**
   ```r
   source("Simone-Squizzato.R")
   ```

> Il seed è fissato con `set.seed(021102)`. I risultati del k-means dipendono comunque dall'inizializzazione, quindi ARI e composizione dei cluster possono variare leggermente cambiando seed o versione di R.

| Pacchetto | Utilizzo |
|---|---|
| `quantmod` | Download dei prezzi da Yahoo Finance |
| `tidyverse` | Import dei dati e grafici (`ggplot2`) |
| `pheatmap` | Heatmap della matrice di correlazione |
| `mclust` | Calcolo dell'Adjusted Rand Index |

---

## 🚧 Limiti e sviluppi futuri

- **Orizzonte breve**: 63 osservazioni per stimare correlazioni tra 497 titoli rendono la matrice rumorosa. Un periodo più lungo o una correlazione con shrinkage potrebbero stabilizzare i risultati.
- **Scelta di k**: k = 11 è fissato a priori per il confronto con il GICS. Si potrebbe anche scegliere k dai dati, tramite eigengap o silhouette.
- **Modello a un fattore**: modelli multi-fattore (es. Fama-French) potrebbero isolare meglio la componente idiosincratica.
- **Financials e IT divisi in due cluster**: vale la pena capire quali sotto-industrie guidano la separazione.
- **Granularità GICS**: estendere il confronto agli altri livelli gerarchici (Industry Group, Industry, Sub-Industry), come in Bhojraj et al. (2003).
- **Robustezza del k-means**: usare più inizializzazioni (`nstart`) e confrontare con altri metodi di community detection (es. Louvain).

---

## 📚 Riferimenti

1. Lloyd, S. (1982). *Least squares quantization in PCM*. IEEE Transactions on Information Theory, 28(2), 129–137. [doi:10.1109/TIT.1982.1056489](https://doi.org/10.1109/TIT.1982.1056489)
2. Bhojraj, S., Lee, C. M. C., & Oler, D. (2003). *What's My Line? A Comparison of Industry Classification Schemes for Capital Market Research*. [SSRN 356840](https://ssrn.com/abstract=356840)
3. MSCI – [Global Industry Classification Standard (GICS)](https://www.msci.com/our-solutions/indexes/gics)
4. [Yahoo Finance](https://finance.yahoo.com/)

---

## 👤 Autore

**Simone Squizzato** · [@simonesquizzato](https://github.com/simonesquizzato)
