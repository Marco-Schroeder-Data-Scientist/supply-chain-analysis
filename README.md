# Análisis de cadena de suministro: nivel de servicio y rentabilidad

Proyecto de análisis de datos end-to-end orientado a evaluar el desempeño operativo, el nivel de servicio logístico y la rentabilidad de una cadena de suministro. A partir de 180.519 líneas de pedido del período 2015–2018, se investigan dos preguntas de negocio: **¿dónde fallamos en las entregas y qué factores están asociados a los retrasos?** y **¿dónde se genera o se pierde rentabilidad?**

**Herramientas:** Python (pandas) · SQLAlchemy · PostgreSQL · SQL · Power BI · DAX

## Hallazgos clave

1. **El 57,3% de los pedidos elegibles presenta retrasos.** Se identifican 36.048 pedidos tardíos de un total de 62.897 pedidos elegibles, excluyendo cancelaciones y sospechas de fraude.
2. **El modo de envío está asociado a diferencias importantes en el nivel de servicio.** First Class presenta un 100% de retrasos y Second Class, aproximadamente un 80%. Standard Class registra un 39,85% y Same Day un 48,37%. Estos resultados deben interpretarse considerando los plazos programados en los datos.
3. **First Class requiere una revisión prioritaria.** Los 9.602 pedidos elegibles de esta modalidad presentan un día real de entrega frente a un día programado. La clasificación como tardío es consistente con la regla aplicada: días reales superiores a los programados.
4. **La rentabilidad y el nivel de servicio deben analizarse conjuntamente.** El informe permite comparar el margen y el desempeño de las entregas, sin asumir que una asociación descriptiva demuestra una relación causal.
5. **Los descuentos deben evaluarse por su aporte comercial.** El análisis compara el volumen vendido y la rentabilidad según la aplicación o intensidad del descuento; los resultados deben interpretarse como asociaciones observadas en los datos.
6. **La rentabilidad está concentrada en un grupo reducido de categorías.** El análisis de Pareto permite identificar las categorías que más contribuyen a la ganancia y priorizar su seguimiento.
7. **La tendencia temporal presenta una limitación estructural.** A partir de noviembre de 2017 cambia la cantidad de líneas por pedido, por lo que la evolución de las ventas por línea no debe interpretarse directamente como una variación equivalente de la demanda.

**Indicadores operativos principales:** 65.752 pedidos distintos en el conjunto de datos; 62.897 pedidos elegibles para el análisis de entregas; 36.048 pedidos tardíos; 26.849 pedidos entregados a tiempo; tasa de retraso del 57,31% sobre los pedidos elegibles.

## Recomendaciones de negocio

1. **Revisar la promesa de servicio de First Class.** Contrastar los plazos programados con los compromisos comerciales reales y la capacidad operativa.
2. **Comparar las modalidades de envío.** Investigar por qué First Class y Second Class presentan tasas de retraso superiores a las de Standard Class y Same Day.
3. **Proteger las categorías que concentran la ganancia.** Priorizar su seguimiento operativo y comercial, teniendo en cuenta su contribución a la rentabilidad total.
4. **Evaluar la efectividad de los descuentos.** Comparar volumen, ventas netas y margen entre los distintos niveles de descuento antes de modificar la política comercial.
5. **Investigar el efecto de los retrasos en el comportamiento del cliente.** La recompra y la retención requieren datos adicionales o una integración con información de transacciones posteriores.

Estas recomendaciones se basan en análisis descriptivos. No demuestran causalidad ni sustituyen la validación de las reglas de negocio con información operativa.

## Dashboard de Power BI

El archivo del informe está disponible en [`powerbi/supply_chain_analysis.pbix`](powerbi/supply_chain_analysis.pbix).

El reporte está organizado en cinco páginas:

1. **Resumen ejecutivo:** indicadores principales de ventas, rentabilidad y desempeño operativo.
2. **Análisis temporal y estacionalidad:** evolución de los indicadores y comparación de períodos.
3. **Productos y rentabilidad:** contribución de las categorías, distribución de la ganancia y análisis de descuentos.
4. **Clientes y geografía:** distribución y comparación del desempeño comercial por segmentos geográficos y de clientes.
5. **Operaciones, envíos y estados:** nivel de servicio, retrasos por modalidad de envío y análisis de los estados de los pedidos.

Las páginas permiten explorar los resultados mediante filtros y segmentadores. Para interpretar correctamente las tasas de retraso, debe distinguirse entre líneas de pedido y pedidos únicos.

## Datos

- **Fuente:** [DataCo Smart Supply Chain for Big Data Analysis — Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis).
- **Período de los datos:** enero de 2015 a enero de 2018.
- **Tamaño original:** 180.519 filas y 53 columnas.
- **Grano original:** una fila representa una línea de pedido.
- **Volumen:** 65.752 pedidos distintos y 20.652 clientes.
- **Moneda de análisis:** USD, según la convención adoptada para el proyecto.
- **Licencia:** consultar las condiciones vigentes del conjunto de datos en Kaggle antes de redistribuir los datos originales.

## Arquitectura y método

El proyecto sigue un flujo de trabajo analítico reproducible:

1. **Extracción y exploración:** carga del CSV, revisión de estructura, tipos de datos, valores faltantes y calidad de los datos con Python y pandas.
2. **Limpieza y preparación:** tratamiento de columnas redundantes o incompletas, normalización de fechas y textos, y preparación de los datos para su carga.
3. **Carga a PostgreSQL:** persistencia de los datos mediante Python y SQLAlchemy.
4. **Modelado dimensional:** organización de los datos en un esquema estrella en PostgreSQL, bajo el esquema `dw`.
5. **Validación:** comprobación de relaciones, integridad del modelo y consistencia de los indicadores utilizados.
6. **Análisis de negocio:** consultas SQL y medidas DAX para estudiar ventas, rentabilidad, comportamiento temporal y nivel de servicio.
7. **Visualización:** construcción del reporte interactivo en Power BI.

### Modelo de datos

El esquema `dw` incluye la tabla de hechos `fact_pedidos` y las dimensiones:

- `dim_cliente`
- `dim_producto`
- `dim_geografia`
- `dim_envio`
- `dim_fecha`

La tabla de hechos contiene información de pedidos, cantidades, ventas, descuentos, ganancias, fechas y variables relacionadas con la entrega. Las dimensiones permiten analizar los indicadores desde diferentes perspectivas comerciales y operativas.

## Decisiones de limpieza y modelado

- Se eliminaron columnas vacías o con escaso valor analítico.
- Se retiraron datos personales que no eran necesarios para el análisis.
- Se eliminaron columnas redundantes y se normalizaron textos y fechas.
- Los importes se redondearon a dos decimales para mantener una presentación monetaria consistente.
- Los pedidos cancelados y los identificados como sospechosos de fraude se excluyeron del cálculo del nivel de servicio.
- Las pérdidas se conservaron, ya que forman parte del desempeño económico observado.
- Las dimensiones se implementaron con una estrategia de tipo 1, conservando el valor vigente de los atributos en el modelo.
- La condición de retraso se define como **días reales de entrega > días programados**.

## Definición de los indicadores de entrega

Para evitar distorsiones, el nivel de servicio se calcula por **pedido único**, no por línea de pedido. Se excluyen los pedidos cancelados y los identificados como fraude.

| Indicador | Resultado |
|---|---:|
| Pedidos distintos en el conjunto de datos | 65.752 |
| Pedidos elegibles para el análisis de entrega | 62.897 |
| Pedidos tardíos | 36.048 |
| Pedidos a tiempo | 26.849 |
| Tasa de retraso | 57,31% |

### Retrasos por modalidad de envío

| Modalidad | Pedidos elegibles | Pedidos tardíos | Tasa de retraso |
|---|---:|---:|---:|
| First Class | 9.602 | 9.602 | 100,00% |
| Second Class | 12.256 | 9.803 | 79,99% |
| Same Day | 3.407 | 1.648 | 48,37% |
| Standard Class | 37.632 | 14.995 | 39,85% |
| **Total** | **62.897** | **36.048** | **57,31%** |

Los resultados son consistentes con la regla de retraso definida y validada sobre los datos elegibles. En particular, el 100% de retrasos de First Class refleja que los días reales registrados superan los días programados para esos pedidos. Esto no demuestra por sí solo que la modalidad incumpla un compromiso comercial real: ese compromiso debe contrastarse con las reglas operativas de la fuente.

## Limitaciones

- **Cambio estructural desde noviembre de 2017:** disminuye la cantidad de líneas por pedido. Por ello, la tendencia de ventas por línea se analiza con cautela y no debe confundirse con la evolución del número de pedidos.
- **Estados inconsistentes:** algunos pedidos en estados como `PENDING`, `PROCESSING` y `PENDING_PAYMENT` presentan información de entrega que puede no ser coherente con su estado. Se debe tener en cuenta esta limitación al interpretar las tasas.
- **Dimensiones tipo 1:** los cambios históricos en atributos de clientes o productos no se conservan como versiones independientes.
- **Categorías con pocas observaciones:** los resultados de grupos pequeños pueden ser inestables y no deben generalizarse sin análisis adicional.
- **Reglas de servicio:** los días programados son la referencia para clasificar un retraso. Deben validarse contra los compromisos comerciales reales.
- **Análisis descriptivo:** las asociaciones observadas no demuestran causalidad.
- **Datos externos:** no se dispone de información suficiente para concluir si los retrasos afectan la recompra o la retención de clientes.

## Cómo reproducir el proyecto

### Requisitos

- Python
- PostgreSQL
- Power BI Desktop
- Dependencias indicadas en `requirements.txt`
- Acceso al conjunto de datos de Kaggle

### Preparación de Python

Clonar el repositorio y crear el entorno virtual:

```bash
git clone https://github.com/Marco-Schroeder-Data-Scientist/supply-chain-analysis.git
cd supply-chain-analysis
python -m venv .venv
```

Activar el entorno virtual en PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

### Configuración de PostgreSQL

1. Descargar el conjunto de datos desde Kaggle y colocarlo en la ruta esperada por los scripts de extracción y limpieza.
2. Crear la base de datos PostgreSQL correspondiente.
3. Copiar `.env.example` como `.env` y completar las variables de conexión con las credenciales locales.
4. No publicar el archivo `.env` ni credenciales en el repositorio.
5. Revisar los scripts disponibles en `scripts/` y ejecutarlos en el orden previsto por el flujo de carga.
6. Ejecutar los scripts SQL de `sql/` respetando sus dependencias: primero el modelo dimensional y después las validaciones y consultas aplicables.

Los nombres exactos de los scripts y sus parámetros deben comprobarse en el repositorio antes de ejecutarlos. El archivo `.env.example` y la configuración local deben corresponder con el entorno PostgreSQL utilizado.

### Ejecución del reporte Power BI

1. Abrir `powerbi/supply_chain_analysis.pbix` con Power BI Desktop.
2. Configurar el acceso a PostgreSQL con las credenciales de la instancia local.
3. Verificar que el origen de datos apunte a la base de datos y al esquema correctos.
4. Actualizar el modelo desde Power BI.
5. Comprobar los indicadores principales y utilizar los filtros de cada página para explorar los resultados.

Los pasos de configuración pueden variar según la instalación local de PostgreSQL y la versión de Power BI Desktop.

## Estructura del repositorio

```text
supply-chain-analysis/
├── data/
├── notebooks/
├── powerbi/
│   └── supply_chain_analysis.pbix
├── scripts/
├── sql/
├── .env.example
├── .gitignore
├── requirements.txt
├── LICENSE
├── README.md
└── README_EN.md
```

## Autor

Proyecto de portafolio enfocado en análisis de datos, SQL, modelado dimensional, Power BI y comunicación de hallazgos de negocio.


# Supply Chain Analysis: Service Level and Profitability

An end-to-end analytics project designed to evaluate operational performance, delivery service levels, and profitability across a supply chain. Using 180,519 order-line records from 2015–2018, the project investigates two business questions: **Where do delivery delays occur, and which factors are associated with them?** and **Where is profit generated or lost?**

**Tools:** Python (pandas) · SQLAlchemy · PostgreSQL · SQL · Power BI · DAX

## Key findings

1. **57.3% of eligible orders are classified as late.** The analysis identifies 36,048 late orders out of 62,897 eligible orders, excluding cancellations and suspected fraud.
2. **Shipping mode is associated with substantial differences in service levels.** First Class has a 100% late rate, followed by Second Class at approximately 80%. Standard Class records 39.85%, while Same Day records 48.37%. These results must be interpreted against the scheduled delivery times recorded in the dataset.
3. **First Class requires priority review.** All 9,602 eligible orders in this mode show one actual delivery day against one scheduled day. The late classification is consistent with the rule applied: actual delivery days greater than scheduled days.
4. **Profitability and service levels should be assessed together.** The report supports comparisons of margins and delivery performance without assuming that descriptive associations prove causation.
5. **Discounts should be evaluated based on commercial contribution.** The analysis compares sales volume and profitability across discount conditions. Results should be interpreted as observed associations in the data.
6. **Profitability is concentrated in a limited number of product categories.** Pareto analysis helps identify the categories contributing most to profit and prioritize their monitoring.
7. **The time-series analysis has a structural limitation.** The number of order lines per order changes from November 2017 onward, so changes in line-level sales should not be interpreted directly as equivalent changes in demand.

**Main operational indicators:** 65,752 distinct orders in the dataset; 62,897 orders eligible for delivery analysis; 36,048 late orders; 26,849 on-time orders; and a 57.31% late rate among eligible orders.

## Business recommendations

1. **Review the First Class service promise.** Compare scheduled delivery times with actual commercial commitments and operational capacity.
2. **Compare shipping modes.** Investigate why First Class and Second Class have higher late rates than Standard Class and Same Day.
3. **Protect the categories driving profit.** Prioritize operational and commercial monitoring based on their contribution to overall profitability.
4. **Evaluate discount effectiveness.** Compare volume, net sales, and margin across discount levels before changing commercial policy.
5. **Investigate the impact of delays on customer behavior.** Repeat purchases and retention require additional data or integration with subsequent transactions.

These recommendations are based on descriptive analysis. They do not establish causality and do not replace validation of business rules against operational information.

## Power BI dashboard

The report file is available at [`powerbi/supply_chain_analysis.pbix`](powerbi/supply_chain_analysis.pbix).

The report contains five pages:

1. **Executive Summary:** headline sales, profitability, and operational performance indicators.
2. **Time Analysis and Seasonality:** indicator trends and period comparisons.
3. **Products and Profitability:** category contribution, profit distribution, and discount analysis.
4. **Customers and Geography:** commercial performance across geographic and customer segments.
5. **Operations, Shipping, and Order Statuses:** service levels, delays by shipping mode, and order-status analysis.

The pages support interactive exploration through filters and slicers. To interpret delivery rates correctly, order lines must be distinguished from unique orders.

## Data

- **Source:** [DataCo Smart Supply Chain for Big Data Analysis — Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis).
- **Data period:** January 2015 to January 2018.
- **Original size:** 180,519 rows and 53 columns.
- **Original grain:** one row represents one order line.
- **Volume:** 65,752 distinct orders and 20,652 customers.
- **Analysis currency:** USD, following the convention adopted for this project.
- **License:** check the current dataset terms on Kaggle before redistributing the original data.

## Architecture and methodology

The project follows a reproducible analytics workflow:

1. **Extraction and exploration:** load the CSV and inspect structure, data types, missing values, and data quality with Python and pandas.
2. **Cleaning and preparation:** handle redundant or incomplete columns, normalize dates and text, and prepare the data for loading.
3. **PostgreSQL loading:** persist the prepared data using Python and SQLAlchemy.
4. **Dimensional modeling:** organize the data into a star schema in PostgreSQL under the `dw` schema.
5. **Validation:** check relationships, model integrity, and the consistency of the indicators used.
6. **Business analysis:** use SQL queries and DAX measures to examine sales, profitability, time trends, and service levels.
7. **Visualization:** build the interactive Power BI report.

### Data model

The `dw` schema contains the `fact_pedidos` fact table and the following dimensions:

- `dim_cliente`
- `dim_producto`
- `dim_geografia`
- `dim_envio`
- `dim_fecha`

The fact table contains order, quantity, sales, discount, profit, date, and delivery-related fields. The dimensions support commercial and operational analysis from multiple perspectives.

## Data-cleaning and modeling decisions

- Removed empty columns or columns with limited analytical value.
- Removed personal data that was not required for the analysis.
- Removed redundant columns and normalized text and dates.
- Rounded monetary amounts to two decimal places for consistent reporting.
- Excluded cancelled orders and orders flagged as suspected fraud from service-level calculations.
- Retained losses because they are part of observed financial performance.
- Implemented Type 1 dimensions, retaining the current attribute values in the model.
- Defined a late delivery as **actual delivery days > scheduled delivery days**.

## Delivery indicator definitions

To avoid distortions, service level is calculated using **unique orders**, not order lines. Cancelled orders and orders flagged as fraud are excluded.

| Indicator | Result |
|---|---:|
| Distinct orders in the dataset | 65,752 |
| Orders eligible for delivery analysis | 62,897 |
| Late orders | 36,048 |
| On-time orders | 26,849 |
| Late rate | 57.31% |

### Late deliveries by shipping mode

| Shipping mode | Eligible orders | Late orders | Late rate |
|---|---:|---:|---:|
| First Class | 9,602 | 9,602 | 100.00% |
| Second Class | 12,256 | 9,803 | 79.99% |
| Same Day | 3,407 | 1,648 | 48.37% |
| Standard Class | 37,632 | 14,995 | 39.85% |
| **Total** | **62,897** | **36,048** | **57.31%** |

The results are consistent with the defined late-delivery rule as validated against eligible orders. In particular, First Class's 100% late rate reflects actual delivery days exceeding scheduled delivery days for these orders. This does not, by itself, prove that the service mode fails to meet a real commercial commitment; that commitment must be checked against the operational rules underlying the source data.

## Limitations

- **Structural change from November 2017:** the number of lines per order decreases. Therefore, line-level sales trends must be interpreted cautiously and should not be confused with changes in the number of orders.
- **Inconsistent statuses:** some orders in statuses such as `PENDING`, `PROCESSING`, and `PENDING_PAYMENT` contain delivery information that may be inconsistent with their status. This should be considered when interpreting rates.
- **Type 1 dimensions:** historical changes to customer or product attributes are not retained as separate versions.
- **Categories with few observations:** results for small groups may be unstable and should not be generalized without further analysis.
- **Service rules:** scheduled delivery days are the reference used to classify delays. They should be validated against actual commercial commitments.
- **Descriptive analysis:** observed associations do not establish causality.
- **External data:** the project does not contain enough information to conclude whether delays affect repeat purchases or customer retention.

## How to reproduce the project

### Requirements

- Python
- PostgreSQL
- Power BI Desktop
- Dependencies listed in `requirements.txt`
- Access to the Kaggle dataset

### Python setup

Clone the repository and create a virtual environment:

```bash
git clone https://github.com/Marco-Schroeder-Data-Scientist/supply-chain-analysis.git
cd supply-chain-analysis
python -m venv .venv
```

Activate the environment in PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

### PostgreSQL configuration

1. Download the Kaggle dataset and place it at the path expected by the extraction and cleaning scripts.
2. Create the required PostgreSQL database.
3. Copy `.env.example` to `.env` and configure the local connection variables.
4. Do not publish `.env` or credentials to the repository.
5. Review the scripts in `scripts/` and run them in the order required by the loading workflow.
6. Execute the SQL scripts in `sql/` in dependency order: first the dimensional model, followed by the applicable validation and analysis queries.

The exact script names and parameters should be checked in the repository before execution. `.env.example` and the local configuration must match the PostgreSQL environment being used.

### Running the Power BI report

1. Open `powerbi/supply_chain_analysis.pbix` in Power BI Desktop.
2. Configure the PostgreSQL connection using the credentials for your local instance.
3. Verify that the data source points to the correct database and schema.
4. Refresh the model in Power BI.
5. Check the main indicators and use the filters on each page to explore the results.

Configuration steps may vary depending on the local PostgreSQL installation and Power BI Desktop version.

## Repository structure

```text
supply-chain-analysis/
├── data/
├── notebooks/
├── powerbi/
│   └── supply_chain_analysis.pbix
├── scripts/
├── sql/
├── .env.example
├── .gitignore
├── requirements.txt
├── LICENSE
├── README.md
└── README_EN.md
```

## Author

Portfolio project focused on data analysis, SQL, dimensional modeling, Power BI, and business insight communication.
