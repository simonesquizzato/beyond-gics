library(tidyverse)  # importazione del dataset e grafici
library(pheatmap)   # grafico HeatMap 
library(mclust)     # calcolo ARI

set.seed(021102)

# Importazione e setup dataset
log_returns <- read_csv("log-returns-SP500.csv")
log_returns <- as.data.frame(log_returns)
rownames(log_returns) <- log_returns[[1]]
log_returns <- log_returns[,-1] # Rimuovere la prima colonna dal dataset

# Rimuovere colonna con informazioni sui GICS e salvarla a parte
log_returns_f <- log_returns[, -ncol(log_returns)]
GICS_sectors <- as.factor(log_returns$gics_sectors[-1]) #rimuoviamo la prima riga relativa all'indice S&P500

# Trasposta della matrice di dati
log_returns_t <- t(log_returns_f)

# Separiamo l'indice di  mercato (SP500) dai rendimenti delle singole stock
Rm <- as.numeric(log_returns_t[,1])
stock_returns  <- log_returns_t[,-1]

# Summary e densità dei rendimenti indice di mercato 
summary(Rm) 
plot(density(Rm))

# Densità dei rendimenti dei titoli e range di variazione 
plot(density(stock_returns))
range(stock_returns)  

# Calcoliamo l'ERR = 'Excess Return Rate' ad un fattore
ERR <- stock_returns
for(i in 1:ncol(stock_returns)){
  fit <- lm(stock_returns[,i] ~ 1 + Rm)
  ERR[,i] <- fit$residuals #estraiamo i residui (parte di rendimento che non dipende dal mercato)
}

# Matrice di correlazione
R <- cor((ERR)) #correlazione dei residui ossia correlazioni "reali" tra le azioni 
S <- abs(R)
pheatmap(S)



# Node degree
di <-  apply(S, 1, sum)
hist(di) #a quanti oggetti è collegato mediamente ogni nodo

# Inversa di D
Dinv <- diag(sqrt(1 / di))
L <- Dinv %*% S %*% Dinv

# Estrazione Autovalori e Autovettori
e <- eigen(L, symmetric=TRUE)
plot(e$values, t='b')
plot(e$values[1:25], t='b')

# Cerchiamo 11 communities (numero dei settori di interesse (GICS))
k <- 11
V <- e$vectors[, 1:k]
pairs(V)
km11 <- kmeans(V, centers = k)
km11

pairs(V, col = km11$cluster)
pairs(V, col = GICS_sectors)

# sovrapposizione ai settori -> normale funzionamento del mercato
# mancata sovrapposizione -> in atto meccanismo di perturbazione


# Analizziamo questi risultati analiticamente

# Prima convertiamo i cluster in fattori 
km11$cluster <- as.factor(km11$cluster)

# Creiamo la tabella di contingenza
comparison_table <- table(km11$cluster, GICS_sectors)

# Convertiamo la tabella in un dataframe
comparison_df <- as.data.frame(comparison_table)
names(comparison_df) <- c("Cluster", "Sector", "Count")

# Creazione della heatmap
ggplot(comparison_df, aes(x = Sector, y = Cluster, fill = Count)) +
  geom_tile(color = "white", linewidth = 0.5) +
  # Gradiente personalizzato
  scale_fill_gradientn(colors = c("#FFFFFF", "#FFF7EC", "#FEE8C8", "#FDD49E", 
                                  "#FDBB84", "#FC8D59", "#EF6548", "#D7301F",
                                  "#B30000", "#7F0000"),
                       name = "Frequenza di \nassegnazioni") +
  # Testo nelle celle
  geom_text(aes(label = Count), color = ifelse(comparison_df$Count > max(comparison_df$Count)/2, 
                                               "white", "black")) +
  # Tema e stile
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    panel.grid = element_blank(),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    legend.position = "right"
  ) +
  # Etichette
  labs(title = "Distribuzione delle community nei Cluster vs Settori GICS",
       x = "Settori GICS",
       y = "Cluster") +
  # Proporzioni ottimali
  coord_fixed(ratio = 1)


# Calcolo dell'Adjusted Rand Index
ARI <- adjustedRandIndex(km11$cluster, GICS_sectors)
ARI
