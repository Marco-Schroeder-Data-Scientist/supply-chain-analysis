# Descarga el dataset desde Kaggle y lo guarda en data/raw
from pathlib import Path
from kaggle.api.kaggle_api_extended import KaggleApi

# Carpeta principal del proyecto (una carpeta arriba de scripts)
raiz = Path(__file__).resolve().parent.parent
carpeta_raw = raiz / "data" / "raw"

# Conectar con Kaggle (usa tu archivo kaggle.json)
api = KaggleApi()
api.authenticate()

# Descargar y descomprimir
api.dataset_download_files(
    "shashwatwork/dataco-smart-supply-chain-for-big-data-analysis",
    path=str(carpeta_raw),
    unzip=True,
)
print("Descarga lista en:", carpeta_raw)