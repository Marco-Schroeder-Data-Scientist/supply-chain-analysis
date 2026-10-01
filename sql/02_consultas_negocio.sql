-- CONSULTAS DE NEGOCIO sobre el modelo estrella (esquema dw)
-- Regla: los indicadores de entrega excluyen los pedidos cancelados (es_cancelado = 0),
-- porque esas entregas no se realizaron (ver EDA, celda 7).
-- Todos los indicadores se calculan por línea de pedido.


-- 1. ¿Cómo está el negocio en general?
SELECT COUNT(*) AS lineas,
       COUNT(DISTINCT pedido_id) AS pedidos,
       ROUND(SUM(ventas_netas)) AS ventas_netas,
       ROUND(SUM(ganancia)) AS ganancia,
       ROUND(SUM(ganancia) / SUM(ventas_netas) * 100, 1) AS margen_pct,
       ROUND(AVG(es_tardio) * 100, 1) AS pct_tardias
FROM dw.fact_pedidos
WHERE es_cancelado = 0;


-- 2. ¿Qué modo de envío tiene más entregas tardías?
SELECT e.modo_envio,
       COUNT(*) AS lineas,
       ROUND(AVG(f.es_tardio) * 100, 1) AS pct_tardias,
       ROUND(AVG(f.dias_retraso), 2) AS retraso_promedio_dias
FROM dw.fact_pedidos AS f
JOIN dw.dim_envio AS e ON e.envio_id = f.envio_id
WHERE f.es_cancelado = 0
GROUP BY e.modo_envio
ORDER BY pct_tardias DESC;


-- 3. ¿Qué regiones tienen más entregas tardías?
SELECT g.mercado,
       g.region,
       COUNT(*) AS lineas,
       ROUND(AVG(f.es_tardio) * 100, 1) AS pct_tardias
FROM dw.fact_pedidos AS f
JOIN dw.dim_geografia AS g ON g.geografia_id = f.geografia_id
WHERE f.es_cancelado = 0
GROUP BY g.mercado, g.region
ORDER BY pct_tardias DESC;


-- 4. ¿Qué categorías de producto tienen más entregas tardías?
SELECT p.categoria,
       COUNT(*) AS lineas,
       ROUND(AVG(f.es_tardio) * 100, 1) AS pct_tardias
FROM dw.fact_pedidos AS f
JOIN dw.dim_producto AS p ON p.producto_id = f.producto_id
WHERE f.es_cancelado = 0
GROUP BY p.categoria
ORDER BY pct_tardias DESC;


-- 5. ¿Cómo evolucionan ventas, margen y retrasos mes a mes?
SELECT d.anio_mes,
       ROUND(SUM(f.ventas_netas)) AS ventas_netas,
       ROUND(SUM(f.ganancia) / SUM(f.ventas_netas) * 100, 1) AS margen_pct,
       ROUND(AVG(f.es_tardio) * 100, 1) AS pct_tardias
FROM dw.fact_pedidos AS f
JOIN dw.dim_fecha AS d ON d.fecha = f.fecha_pedido
WHERE f.es_cancelado = 0
GROUP BY d.anio_mes
ORDER BY d.anio_mes;


-- 6. ¿Los retrasos afectan la rentabilidad?
-- Se compara el margen de las entregas a tiempo contra las tardías.
SELECT CASE WHEN es_tardio = 1 THEN 'Tardía' ELSE 'A tiempo' END AS entrega,
       COUNT(*) AS lineas,
       ROUND(SUM(ganancia) / SUM(ventas_netas) * 100, 1) AS margen_pct,
       ROUND(AVG(es_perdida) * 100, 1) AS pct_lineas_con_perdida
FROM dw.fact_pedidos
WHERE es_cancelado = 0
GROUP BY es_tardio;


-- 7. ¿Los descuentos altos destruyen margen sin vender más?
-- Se agrupan las líneas por tramo de descuento.
WITH tramos AS (
    SELECT CASE
             WHEN descuento_pct = 0  THEN '1. Sin descuento'
             WHEN descuento_pct <= 5 THEN '2. Hasta 5%'
             WHEN descuento_pct <= 10 THEN '3. 5% a 10%'
             WHEN descuento_pct <= 20 THEN '4. 10% a 20%'
             ELSE '5. Más de 20%'
           END AS tramo_descuento,
           cantidad, ventas_netas, ganancia
    FROM dw.fact_pedidos
    WHERE es_cancelado = 0
)
SELECT tramo_descuento,
       COUNT(*) AS lineas,
       ROUND(AVG(cantidad), 2) AS unidades_por_linea,
       ROUND(SUM(ganancia) / SUM(ventas_netas) * 100, 1) AS margen_pct
FROM tramos
GROUP BY tramo_descuento
ORDER BY tramo_descuento;


-- 8. Pareto: ¿qué categorías concentran el 80% de la ganancia?
WITH ganancia_categoria AS (
    SELECT p.categoria, SUM(f.ganancia) AS ganancia
    FROM dw.fact_pedidos AS f
    JOIN dw.dim_producto AS p ON p.producto_id = f.producto_id
    WHERE f.es_cancelado = 0
    GROUP BY p.categoria
),
acumulado AS (
    -- SUM() OVER (ORDER BY ...) va sumando de la categoría más rentable hacia abajo
    SELECT categoria,
           ganancia,
           SUM(ganancia) OVER (ORDER BY ganancia DESC) AS ganancia_acumulada,
           SUM(ganancia) OVER () AS ganancia_total
    FROM ganancia_categoria
)
SELECT categoria,
       ROUND(ganancia) AS ganancia,
       ROUND(ganancia_acumulada / ganancia_total * 100, 1)  AS pct_acumulado
FROM acumulado
ORDER BY ganancia DESC;