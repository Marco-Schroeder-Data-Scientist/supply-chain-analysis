-- MODELO ESTRELLA a partir de staging.pedidos
-- Tabla de hechos: una fila por línea de pedido (order_item_id)
-- Dimensiones: cliente, producto, geografía, envío y fecha

DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

-- DIMENSIÓN CLIENTE: un registro por cliente.
-- Si un cliente aparece con datos distintos, se usa MAX() para quedarse con uno.
CREATE TABLE dw.dim_cliente AS
SELECT customer_id      AS cliente_id,
       MAX(customer_segment) AS segmento,
       MAX(customer_city)    AS ciudad,
       MAX(customer_state)   AS estado,
       MAX(customer_country) AS pais
FROM staging.pedidos
GROUP BY customer_id;

-- DIMENSIÓN PRODUCTO: un registro por producto
CREATE TABLE dw.dim_producto AS
SELECT product_card_id  AS producto_id,
       MAX(product_name)    AS producto,
       MAX(category_name)   AS categoria,
       MAX(department_name) AS departamento,
       MAX(product_price)   AS precio
FROM staging.pedidos
GROUP BY product_card_id;

-- DIMENSIÓN GEOGRAFÍA: destino del pedido. Se le asigna un número (geografia_id).
CREATE TABLE dw.dim_geografia AS
SELECT ROW_NUMBER() OVER (ORDER BY market, order_region, order_country, order_state, order_city) AS geografia_id,
       market AS mercado, order_region AS region, order_country AS pais,
       order_state AS estado, order_city AS ciudad
FROM (SELECT DISTINCT market, order_region, order_country, order_state, order_city
      FROM staging.pedidos) AS destinos;

-- DIMENSIÓN ENVÍO: un registro por modo de envío
CREATE TABLE dw.dim_envio AS
SELECT ROW_NUMBER() OVER (ORDER BY shipping_mode) AS envio_id,
       shipping_mode AS modo_envio
FROM (SELECT DISTINCT shipping_mode FROM staging.pedidos) AS modos;

-- DIMENSIÓN FECHA: un registro por día entre 2015 y 2018
CREATE TABLE dw.dim_fecha AS
SELECT d::date                      AS fecha,
       EXTRACT(YEAR FROM d)::int    AS anio,
       EXTRACT(QUARTER FROM d)::int AS trimestre,
       EXTRACT(MONTH FROM d)::int   AS mes,
       TO_CHAR(d, 'YYYY-MM')        AS anio_mes
FROM generate_series('2015-01-01'::date, '2018-12-31'::date, '1 day') AS d;

-- TABLA DE HECHOS: medidas del negocio + claves hacia las dimensiones
CREATE TABLE dw.fact_pedidos AS
SELECT p.order_item_id            AS linea_id,
       p.order_id                 AS pedido_id,
       p.customer_id              AS cliente_id,
       p.product_card_id          AS producto_id,
       g.geografia_id,
       e.envio_id,
       p.fecha_pedido::date       AS fecha_pedido,
       p.fecha_envio::date        AS fecha_envio,
       p.type                     AS tipo_pago,
       p.order_status             AS estado_pedido,
       p.delivery_status          AS estado_entrega,
       p.order_item_quantity      AS cantidad,
       ROUND(p.sales::numeric, 2)                  AS ventas_brutas,
       ROUND(p.order_item_discount::numeric, 2)    AS descuento,
       p.descuento_pct,
       ROUND(p.order_item_total::numeric, 2)       AS ventas_netas,
       ROUND(p.order_profit_per_order::numeric, 2) AS ganancia,
       p.margen,
       p.dias_reales, p.dias_programados, p.dias_retraso,
       p.es_tardio, p.es_cancelado, p.es_fraude, p.es_perdida
FROM staging.pedidos AS p
JOIN dw.dim_geografia AS g
  ON  g.mercado = p.market AND g.region = p.order_region AND g.pais = p.order_country
  AND g.estado = p.order_state AND g.ciudad = p.order_city
JOIN dw.dim_envio AS e
  ON e.modo_envio = p.shipping_mode;

-- CLAVES PRIMARIAS (identifican cada fila de forma única)
ALTER TABLE dw.dim_cliente   ADD PRIMARY KEY (cliente_id);
ALTER TABLE dw.dim_producto  ADD PRIMARY KEY (producto_id);
ALTER TABLE dw.dim_geografia ADD PRIMARY KEY (geografia_id);
ALTER TABLE dw.dim_envio     ADD PRIMARY KEY (envio_id);
ALTER TABLE dw.dim_fecha     ADD PRIMARY KEY (fecha);
ALTER TABLE dw.fact_pedidos  ADD PRIMARY KEY (linea_id);