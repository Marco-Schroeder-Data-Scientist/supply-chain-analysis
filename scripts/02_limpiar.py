# Limpia el CSV original y crea columnas nuevas
from pathlib import Path
import pandas as pd

# Carpetas del proyecto
raiz = Path(__file__).resolve().parent.parent
archivo_entrada = raiz / "data" / "raw" / "DataCoSupplyChainDataset.csv"
archivo_salida = raiz / "data" / "processed" / "pedidos_limpios.csv"

# 1. Leer el CSV (viene en formato latin-1)
df = pd.read_csv(archivo_entrada, encoding="latin-1")
print("Filas leídas:", len(df))

# 2. Eliminar columnas que no sirven
columnas_eliminar = [
    # datos personales
    "Customer Email", "Customer Fname", "Customer Lname",
    "Customer Password", "Customer Street", "Customer Zipcode",
    # vacías o sin valor para el análisis
    "Product Description", "Order Zipcode", "Product Image", "Product Status",
    # repetidas (el EDA mostró que son idénticas a otra columna)
    "Order Customer Id", "Product Category Id", "Order Item Cardprod Id",
    "Benefit per order", "Order Item Product Price", "Late_delivery_risk",
    "Sales per customer",
    # coordenadas que no corresponden al destino del pedido
    "Latitude", "Longitude",
]
df = df.drop(columns=columnas_eliminar)

# 3. Nombres de columnas simples: minúsculas y con guion bajo
df.columns = (
    df.columns.str.lower()
    .str.replace(r"[^0-9a-z]+", "_", regex=True)
    .str.strip("_")
)
df = df.rename(columns={
    "days_for_shipping_real": "dias_reales",
    "days_for_shipment_scheduled": "dias_programados",
    "order_date_dateorders": "fecha_pedido",
    "shipping_date_dateorders": "fecha_envio",
})

# 4. Redondear los montos a 2 decimales (venían con ruido, ej: 59.99000168)
columnas_monto = ["sales", "order_item_total", "order_profit_per_order",
                  "order_item_discount", "product_price"]
df[columnas_monto] = df[columnas_monto].round(2)

# 5. Convertir las fechas de texto a fecha
df["fecha_pedido"] = pd.to_datetime(df["fecha_pedido"], format="%m/%d/%Y %H:%M")
df["fecha_envio"] = pd.to_datetime(df["fecha_envio"], format="%m/%d/%Y %H:%M")

# 6. Columnas nuevas
# Pedido cancelado: cancelado o sospecha de fraude
df["es_cancelado"] = df["order_status"].isin(["CANCELED", "SUSPECTED_FRAUD"]).astype(int)
df["es_fraude"] = (df["order_status"] == "SUSPECTED_FRAUD").astype(int)

# Días de retraso y entrega tardía (1 = llegó tarde)
df["dias_retraso"] = df["dias_reales"] - df["dias_programados"]
df["es_tardio"] = (df["dias_retraso"] > 0).astype(int)

# Descuento en porcentaje y margen de ganancia
df["descuento_pct"] = (df["order_item_discount_rate"] * 100).round(1)
df["margen"] = (df["order_profit_per_order"] / df["order_item_total"]).round(4)

# Línea con pérdida (1 = la ganancia es negativa)
df["es_perdida"] = (df["order_profit_per_order"] < 0).astype(int)

# Mes del pedido (para gráficos por mes)
df["mes_pedido"] = df["fecha_pedido"].dt.to_period("M").dt.to_timestamp()

# 7. Guardar el archivo limpio
df.to_csv(archivo_salida, index=False)

# 8. Comprobaciones rápidas
sin_cancelados = df[df["es_cancelado"] == 0]
print("Filas guardadas:", len(df), "| Columnas:", df.shape[1])
print("Cancelados:", df["es_cancelado"].sum())
print("% entregas tardías (sin cancelados):", round(sin_cancelados["es_tardio"].mean() * 100, 1))
print("Archivo guardado en:", archivo_salida)