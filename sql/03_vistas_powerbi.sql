-- VISTAS PARA POWER BI (esquema dw)
-- Cada vista responde preguntas del dashboard. Todas excluyen cancelados (es_cancelado = 0),
-- porque esas entregas no se realizaron (ver EDA, celda 7).

-- 1. Base de líneas de pedido con todos los datos descriptivos.
-- Alimenta las tarjetas de resumen y las segmentaciones.
CREATE OR REPLACE VIEW dw.v_pedidos AS
SELECT f.linea_id,
       f.pedido_id,
       f.fecha_pedido,
       d.anio_mes,
       e.modo_envio,
       g.mercado,
       g.region,
       g.pais,
       p.categoria,
       p.departamento,
       f.cantidad,
       f.ventas_netas,
       f.ganancia,
       f.descuento_pct,
       f.es_tardio,
       f.es_perdida,
       CASE
         WHEN f.descuento_pct = 0   THEN '1. Sin descuento'
         WHEN f.descuento_pct <= 5  THEN '2. Hasta 5%'
         WHEN f.descuento_pct <= 10 THEN '3. 5% a 10%'
         WHEN f.descuento_pct <= 20 THEN '4. 10% a 20%'
         ELSE '5. Más de 20%'
       END AS tramo_descuento
FROM dw.fact_pedidos AS f
JOIN dw.dim_fecha     AS d ON d.fecha = f.fecha_pedido
JOIN dw.dim_envio     AS e ON e.envio_id = f.envio_id
JOIN dw.dim_geografia AS g ON g.geografia_id = f.geografia_id
JOIN dw.dim_producto  AS p ON p.producto_id = f.producto_id
WHERE f.es_cancelado = 0;


-- 2. Tendencia mensual, limitada a ene-2015 / oct-2017.
-- Desde nov-2017 cada pedido tiene 1 línea (antes ~3), por eso esos meses no se comparan.
CREATE OR REPLACE VIEW dw.v_tendencia_mensual AS
SELECT anio_mes,
       ROUND(SUM(ventas_netas))                          AS ventas_netas,
       ROUND(SUM(ganancia) / SUM(ventas_netas) * 100, 1) AS margen_pct,
       ROUND(AVG(es_tardio) * 100, 1)                    AS pct_tardias
FROM dw.v_pedidos
WHERE anio_mes <= '2017-10'
GROUP BY anio_mes;


-- 3. Pareto de ganancia por categoría, con porcentaje acumulado.
CREATE OR REPLACE VIEW dw.v_pareto_categoria AS
WITH por_categoria AS (
    SELECT categoria,
           SUM(ganancia) AS ganancia
    FROM dw.v_pedidos
    GROUP BY categoria
)
SELECT categoria,
       ROUND(ganancia) AS ganancia,
       ROUND(SUM(ganancia) OVER (ORDER BY ganancia DESC)
             / SUM(ganancia) OVER () * 100, 1) AS pct_acumulado
FROM por_categoria;