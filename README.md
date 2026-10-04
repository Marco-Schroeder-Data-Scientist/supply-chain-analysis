# Análisis de cadena de suministro: nivel de servicio y rentabilidad

Análisis de datos end-to-end de una cadena de suministro (180.519 líneas de pedido, 2015-2018).
Responde dos preguntas: **¿dónde fallamos en las entregas?** y **¿dónde se gana (o se pierde) dinero?**

**Herramientas:** Python (pandas) · PostgreSQL (SQLAlchemy) · SQL · Power BI

## Hallazgos clave

1. **El 57,3% de las entregas llega tarde** (98.977 de 172.765 líneas, sin cancelados).
2. **El problema está en el modo de envío, no en la región ni la categoría.**
   First Class llega tarde el 100% de las veces (1 día de retraso en promedio) y Second Class el 79,8%.
   Standard Class, el modo más lento, es el más cumplidor (39,8%).
   Entre regiones la diferencia es pequeña (51,6% a 60,1%).
3. **First y Second Class son el 35% de las líneas, pero concentran el 54% de las entregas tardías.**
4. **Los retrasos no afectan el margen** (12,3% a tiempo vs 11,8% tardía). El costo está en el servicio, no en la rentabilidad directa.
5. **Los descuentos no aumentan el volumen:** las líneas venden 2,13 unidades con o sin descuento.
6. **La ganancia está muy concentrada:** 8 de 50 categorías (Fishing, Cleats, Camping & Hiking,
   Cardio Equipment, Women's Apparel, Water Sports, Indoor/Outdoor Games y Men's Footwear)
   generan el 84,6% de la ganancia. Fishing sola aporta el 19,2%.
7. **Ventas y margen estables entre enero de 2015 y octubre de 2017** (margen cercano a 12%, sin crecimiento).

**Cifras generales (sin cancelados):** ventas netas 31,6 M · ganancia 3,8 M · margen 12,0% · 62.897 pedidos.

## Recomendaciones

1. **Revisar el plazo prometido de First Class:** casi nunca se cumple, lo que sugiere un plazo irreal.
   Alinear la promesa con la capacidad real o mejorar la operación.
2. **Revisar la política de descuentos:** no hay evidencia de que aumenten las unidades vendidas.
3. **Proteger el servicio en las 8 categorías que concentran la ganancia:** un retraso en ellas pesa mucho más que en el resto.
4. **Evaluar Computers:** pocas líneas (425) pero alta ganancia por línea (~163, contra 14 a 44 en las categorías grandes). Es una pista a validar, no una conclusión.

**Próximo análisis:** medir si los retrasos afectan la recompra del cliente. Con estos datos no se puede responder.

## Dashboard

[PENDIENTE: capturas de las 3 páginas en `powerbi/screenshots/`]

1. **Resumen ejecutivo:** ventas, margen, % de entregas tardías y tendencia mensual.
2. **Nivel de servicio:** retrasos por modo de envío, región y categoría.
3. **Rentabilidad y descuentos:** margen por tramo de descuento y Pareto de categorías.

## Datos

- **Fuente:** [DataCo Smart Supply Chain for Big Data Analysis (Kaggle)](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis). Verificar la licencia vigente en Kaggle.
- **Periodo:** enero 2015 a enero 2018. **Tamaño original:** 180.519 filas y 53 columnas.
- **Grano:** una fila = una línea de pedido (65.752 pedidos, 20.652 clientes). Todos los indicadores se calculan por línea.

## Método

| Etapa | Herramienta | Archivo |
|---|---|---|
| Extracción | Python (API de Kaggle o descarga manual) | `scripts/01_extraer.py` |
| Exploración (EDA) | pandas | `notebooks/eda.ipynb` |
| Limpieza y columnas nuevas | pandas | `scripts/02_limpiar.py` |
| Carga a PostgreSQL | SQLAlchemy | `scripts/03_cargar_postgres.py` |
| Modelo estrella | SQL | `sql/01_modelo_estrella.sql` |
| Consultas de negocio | SQL | `sql/02_consultas_negocio.sql` |
| Dashboard | Power BI | `powerbi/` |

**Modelo estrella (esquema `dw`):** `fact_pedidos` y las dimensiones `dim_cliente`, `dim_producto`, `dim_geografia`, `dim_envio` y `dim_fecha`.

## Decisiones de limpieza

| Problema | Decisión |
|---|---|
| Columnas vacías (`Product Description` 100%, `Order Zipcode` 86%) | Eliminadas |
| Datos personales (email, nombres, clave, calle) | Eliminados por privacidad |
| Columnas idénticas a otra | Se conserva una |
| Latitud y longitud (no representan el destino del pedido) | Eliminadas; los mapas usan país y región |
| Montos con ruido decimal (59.99000168) | Redondeados a 2 decimales |
| Fechas como texto | Convertidas a fecha |
| Espacios sobrantes en textos | Eliminados |
| Pedidos cancelados (7.754: 3.692 cancelados + 4.062 sospecha de fraude) | Marcados y excluidos de los indicadores de entrega |
| Pérdidas (18,7% de las líneas, máx. -4.274) | Conservadas y marcadas: son reales |

**Definición de entrega tardía:** días reales > días programados. Coincide al 100% con el estado de entrega original en los pedidos no cancelados.

## Limitaciones

- **Cambio de estructura desde noviembre de 2017:** cada pedido pasa de ~3 líneas a 1. Las ventas mensuales bajan por eso, no por menos pedidos (~2.100 al mes). La tendencia se analiza hasta octubre de 2017.
- **Estados inconsistentes:** pedidos en `PENDING`, `PROCESSING` y `PENDING_PAYMENT` tienen estado de entrega y días reales, lo que no es lógico. El % de retraso es similar entre estados, así que no se excluyen.
- **Dimensiones tipo 1:** si un cliente o producto cambió de atributos, se guarda el último valor.
- **Categorías pequeñas:** las que tienen pocas líneas (por ejemplo Golf Bags & Carts con 61) no permiten conclusiones.
- Los hallazgos son descriptivos: muestran asociaciones, no causas.

## Cómo reproducirlo

1. Clonar el repositorio y crear el entorno: `python -m venv .venv`, activarlo e instalar con `python -m pip install -r requirements.txt`.
2. Descargar el CSV desde Kaggle y dejarlo en `data/raw/DataCoSupplyChainDataset.csv`.
3. Crear la base `supply_chain` en PostgreSQL y copiar `.env.example` como `.env` con tus credenciales.
4. Ejecutar `python scripts/02_limpiar.py` y luego `python scripts/03_cargar_postgres.py`.
5. Ejecutar `sql/01_modelo_estrella.sql` y después `sql/02_consultas_negocio.sql` en PostgreSQL.
