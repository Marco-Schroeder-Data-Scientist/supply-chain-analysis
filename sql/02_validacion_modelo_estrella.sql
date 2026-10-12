-- ============================================================
-- VALIDACIÓN DEL MODELO ESTRELLA
-- Proyecto: Supply Chain Analysis
--
-- Objetivo:
-- Validar volumen, unicidad, integridad referencial,
-- conciliación financiera y consistencia de fechas.
--
-- IMPORTANTE:
-- Este archivo contiene únicamente consultas de lectura.
-- No crea, elimina ni modifica tablas o registros.
-- Ejecutar cada bloque por separado en PostgreSQL.
-- ============================================================


-- ============================================================
-- BLOQUE 1. VOLUMEN DE TABLAS
-- Comprobar que existen las tablas y revisar sus registros.
-- ============================================================

SELECT 'staging.pedidos' AS tabla, COUNT(*) AS filas
FROM staging.pedidos

UNION ALL

SELECT 'dw.fact_pedidos', COUNT(*)
FROM dw.fact_pedidos

UNION ALL

SELECT 'dw.dim_cliente', COUNT(*)
FROM dw.dim_cliente

UNION ALL

SELECT 'dw.dim_producto', COUNT(*)
FROM dw.dim_producto

UNION ALL

SELECT 'dw.dim_geografia', COUNT(*)
FROM dw.dim_geografia

UNION ALL

SELECT 'dw.dim_envio', COUNT(*)
FROM dw.dim_envio

UNION ALL

SELECT 'dw.dim_fecha', COUNT(*)
FROM dw.dim_fecha

ORDER BY tabla;


-- ============================================================
-- BLOQUE 2. UNICIDAD DE LA CLAVE DE LA TABLA DE HECHOS
-- Verificar que linea_id identifica cada registro.
-- ============================================================

SELECT
    COUNT(*) AS filas,
    COUNT(linea_id) AS lineas_no_nulas,
    COUNT(DISTINCT linea_id) AS lineas_unicas,
    COUNT(*) - COUNT(DISTINCT linea_id) AS posibles_duplicados
FROM dw.fact_pedidos;


-- ============================================================
-- BLOQUE 3. CONCILIACIÓN FINANCIERA
-- Comparar staging con la tabla de hechos.
-- Los totales deben coincidir.
-- ============================================================

SELECT
    'staging.pedidos' AS origen,
    COUNT(*) AS filas,
    SUM(order_item_quantity) AS unidades,
    ROUND(SUM(sales)::numeric, 2) AS ventas_brutas,
    ROUND(SUM(order_item_total)::numeric, 2) AS ventas_netas,
    ROUND(SUM(order_profit_per_order)::numeric, 2) AS ganancia
FROM staging.pedidos

UNION ALL

SELECT
    'dw.fact_pedidos',
    COUNT(*),
    SUM(cantidad),
    ROUND(SUM(ventas_brutas)::numeric, 2),
    ROUND(SUM(ventas_netas)::numeric, 2),
    ROUND(SUM(ganancia)::numeric, 2)
FROM dw.fact_pedidos;


-- ============================================================
-- BLOQUE 4. INTEGRIDAD REFERENCIAL
-- Buscar líneas sin correspondencia en las dimensiones.
-- Se espera cero en todas las comprobaciones.
-- ============================================================

SELECT
    'dim_cliente' AS dimension,
    COUNT(*) AS registros_sin_correspondencia
FROM dw.fact_pedidos f
LEFT JOIN dw.dim_cliente d
    ON d.cliente_id = f.cliente_id
WHERE d.cliente_id IS NULL

UNION ALL

SELECT
    'dim_producto',
    COUNT(*)
FROM dw.fact_pedidos f
LEFT JOIN dw.dim_producto d
    ON d.producto_id = f.producto_id
WHERE d.producto_id IS NULL

UNION ALL

SELECT
    'dim_geografia',
    COUNT(*)
FROM dw.fact_pedidos f
LEFT JOIN dw.dim_geografia d
    ON d.geografia_id = f.geografia_id
WHERE d.geografia_id IS NULL

UNION ALL

SELECT
    'dim_envio',
    COUNT(*)
FROM dw.fact_pedidos f
LEFT JOIN dw.dim_envio d
    ON d.envio_id = f.envio_id
WHERE d.envio_id IS NULL

UNION ALL

SELECT
    'dim_fecha_pedido',
    COUNT(*)
FROM dw.fact_pedidos f
LEFT JOIN dw.dim_fecha d
    ON d.fecha = f.fecha_pedido
WHERE d.fecha IS NULL;


-- ============================================================
-- BLOQUE 5. CONSISTENCIA DE FECHAS
-- Revisar rango temporal, fechas ausentes y envíos anteriores
-- a la fecha del pedido.
-- ============================================================

SELECT
    MIN(fecha_pedido) AS primer_pedido,
    MAX(fecha_pedido) AS ultimo_pedido,
    COUNT(*) FILTER (
        WHERE fecha_pedido IS NULL
    ) AS pedidos_sin_fecha,
    COUNT(*) FILTER (
        WHERE fecha_envio IS NULL
    ) AS registros_sin_fecha_envio,
    COUNT(*) FILTER (
        WHERE fecha_envio < fecha_pedido
    ) AS envios_anteriores_al_pedido
FROM dw.fact_pedidos;


-- ============================================================
-- BLOQUE 6. DISTRIBUCIÓN DE ESTADOS
-- Cuantificar los estados para definir criterios de negocio.
-- No se excluye ningún estado.
-- ============================================================

SELECT
    estado_pedido,
    COUNT(*) AS lineas,
    COUNT(DISTINCT pedido_id) AS pedidos,
    ROUND(SUM(ventas_netas)::numeric, 2) AS ventas_netas,
    ROUND(SUM(ganancia)::numeric, 2) AS ganancia
FROM dw.fact_pedidos
GROUP BY estado_pedido
ORDER BY lineas DESC;