# Usa un'immagine base di Python
FROM python:3.11-slim

# Installa dipendenze di sistema necessarie per psql
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Imposta la directory di lavoro
WORKDIR /app

# Copia i requisiti e installa le dipendenze
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia il codice dell'applicazione
COPY . .

# Copia lo script di entrypoint
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Espone la porta per Flask
EXPOSE ${APP_PORT:-5000}

# Definisce il comando di avvio
ENTRYPOINT ["./entrypoint.sh"]
