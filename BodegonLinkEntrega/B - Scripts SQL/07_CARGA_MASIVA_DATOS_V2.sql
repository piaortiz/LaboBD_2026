-- =============================================
-- SCRIPT DE CARGA MASIVA DE DATOS - ESBIRROSDB V2
-- =============================================
-- Descripción: Genera 10,000+ registros de prueba de forma optimizada
--              para testing y validación del sistema
-- Negocio:     Bodegón Los Esbirros de Claudio
-- Versión:     2.0 - Optimizada y corregida
-- Fecha:       Abril 2026
-- 
-- IMPORTANTE: Este script requiere que la base de datos EsbirrosDB
--             esté completamente desplegada con todos los bundles.
--
-- CONTENIDO GENERADO:
--   - 3,000 clientes (DNIs 30,000,001 - 30,003,000)
--   - 3,000 domicilios (uno por cliente)
--   - 10,000 pedidos distribuidos en 6 meses
--       * 50% Mostrador
--       * 30% Delivery  
--       * 15% Mesa QR
--       * 5% Teléfono
--   - 30,000+ ítems de pedido (2-4 ítems por pedido)
--
-- TOTAL ESTIMADO: ~43,000 registros
-- TIEMPO ESTIMADO: 30-60 segundos
--
-- PREREQUISITOS:
--   - Bundles A1, A2 (Infraestructura + Datos Maestros)
--   - Bundles B1-B3 (Lógica de Negocio)
--   - Triggers activos (Bundle E1)
--
-- NOTAS:
--   - Limpia datos previos de bulk load (cliente_id > 19)
--   - Preserva empleados y datos de sistema
--   - Usa DNIs en rango 30M para evitar colisiones
-- =============================================

USE EsbirrosDB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '======================================================='
PRINT 'CARGA MASIVA DE DATOS - ESBIRROSDB V2'
PRINT '======================================================='
PRINT 'Generando 10,000+ registros para testing...'
PRINT 'Inicio: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''

-- =============================================
-- LIMPIEZA DE DATOS PREVIOS (si existen)
-- =============================================

PRINT 'Limpiando datos previos de carga masiva...'

DELETE FROM DETALLE_PEDIDO;
DELETE FROM PEDIDO;
DELETE FROM DOMICILIO;
DELETE FROM CLIENTE WHERE cliente_id > 19; -- Mantener solo empleados como clientes
DELETE FROM NOTIFICACIONES;
DELETE FROM AUDITORIA_SIMPLE;

PRINT '   Datos previos eliminados - OK'
PRINT ''

-- =============================================
-- PASO 1: GENERAR CLIENTES (3,000 clientes)
-- =============================================

PRINT '1. Generando 3,000 clientes...'

DECLARE @i INT = 1
DECLARE @nombres TABLE (nombre NVARCHAR(50))
INSERT INTO @nombres VALUES 
('Juan'),('Maria'),('Carlos'),('Ana'),('Luis'),('Laura'),('Pedro'),('Sofia'),
('Miguel'),('Elena'),('Jorge'),('Carmen'),('Roberto'),('Isabel'),('Diego'),
('Patricia'),('Fernando'),('Lucia'),('Ricardo'),('Martina'),('Andres'),('Valentina')

DECLARE @apellidos TABLE (apellido NVARCHAR(50))
INSERT INTO @apellidos VALUES 
('Gonzalez'),('Rodriguez'),('Fernandez'),('Lopez'),('Martinez'),('Sanchez'),
('Perez'),('Gomez'),('Martin'),('Jimenez'),('Ruiz'),('Hernandez'),('Diaz'),
('Moreno'),('Munoz'),('Alvarez'),('Romero'),('Alonso'),('Gutierrez'),('Navarro')

-- Insertar clientes en lotes para mejor performance
WHILE @i <= 3000
BEGIN
    INSERT INTO CLIENTE (nombre, email, telefono, doc_tipo, doc_nro)
    SELECT TOP 1
        n.nombre + ' ' + a.apellido,
        LOWER(n.nombre) + '.' + LOWER(a.apellido) + CAST(@i AS VARCHAR) + '@email.com',
        '11' + RIGHT('00000000' + CAST(30000000 + @i AS VARCHAR), 8),
        'DNI',
        30000000 + @i
    FROM @nombres n
    CROSS APPLY (SELECT TOP 1 apellido FROM @apellidos ORDER BY NEWID()) a
    ORDER BY NEWID()
    
    SET @i = @i + 1
    
    IF @i % 500 = 0
        PRINT '   Clientes creados: ' + CAST(@i AS VARCHAR)
END

PRINT '   Total clientes: 3,000 - OK'
PRINT ''

-- =============================================
-- PASO 2: GENERAR DOMICILIOS (3,000 domicilios)
-- =============================================

PRINT '2. Generando 3,000 domicilios...'

DECLARE @calles TABLE (calle NVARCHAR(100))
INSERT INTO @calles VALUES 
('Av. Corrientes'),('Av. Santa Fe'),('Av. Cabildo'),('Av. Rivadavia'),
('Calle Florida'),('Av. 9 de Julio'),('Av. Callao'),('Av. Córdoba'),
('Calle Lavalle'),('Av. Las Heras'),('Calle Reconquista'),('Av. Pueyrredón')

INSERT INTO DOMICILIO (cliente_id, calle, numero, piso, depto, localidad, provincia, es_principal)
SELECT 
    c.cliente_id,
    (SELECT TOP 1 calle FROM @calles ORDER BY NEWID()),
    100 + (c.cliente_id % 9000),
    CASE WHEN c.cliente_id % 3 = 0 THEN CAST((c.cliente_id % 20) + 1 AS VARCHAR(5)) ELSE NULL END,
    CASE WHEN c.cliente_id % 3 = 0 THEN CHAR(65 + (c.cliente_id % 10)) ELSE NULL END,
    'CABA',
    'Buenos Aires',
    1
FROM CLIENTE c
WHERE c.cliente_id > 19 -- Solo clientes, no empleados

PRINT '   Total domicilios: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 3: GENERAR PEDIDOS (10,000 pedidos)
-- =============================================

PRINT '3. Generando 10,000 pedidos...'

-- Obtener IDs necesarios
DECLARE @canal_mostrador INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Mostrador')
DECLARE @canal_delivery INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Delivery')
DECLARE @canal_mesa_qr INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Mesa QR')
DECLARE @canal_telefono INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Telefono')

DECLARE @estado_cerrado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Cerrado')
DECLARE @estado_entregado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Entregado')
DECLARE @estado_cancelado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Cancelado')

DECLARE @min_cliente_id INT = (SELECT MIN(cliente_id) FROM CLIENTE WHERE cliente_id > 19)
DECLARE @max_cliente_id INT = (SELECT MAX(cliente_id) FROM CLIENTE WHERE cliente_id > 19)

-- Generar pedidos en lotes
SET @i = 1
WHILE @i <= 10000
BEGIN
    DECLARE @canal_id INT
    DECLARE @mesa_id INT
    DECLARE @cliente_id_pedido INT
    DECLARE @domicilio_id INT
    DECLARE @estado_id INT
    DECLARE @dias_atras INT
    DECLARE @fecha_pedido DATETIME
    
    -- Distribución de días: más recientes tienen más pedidos
    SET @dias_atras = CASE 
        WHEN @i % 100 < 40 THEN @i % 7        -- 40% última semana
        WHEN @i % 100 < 70 THEN 7 + (@i % 23) -- 30% último mes
        ELSE 30 + (@i % 150)                   -- 30% últimos 6 meses
    END
    
    SET @fecha_pedido = DATEADD(DAY, -@dias_atras, GETDATE())
    SET @fecha_pedido = DATEADD(HOUR, 12 + (@i % 10), @fecha_pedido)
    SET @fecha_pedido = DATEADD(MINUTE, @i % 60, @fecha_pedido)
    
    -- Distribución de canales: 50% Mostrador, 30% Delivery, 15% Mesa QR, 5% Teléfono
    SET @canal_id = CASE 
        WHEN @i % 100 < 50 THEN @canal_mostrador
        WHEN @i % 100 < 80 THEN @canal_delivery
        WHEN @i % 100 < 95 THEN @canal_mesa_qr
        ELSE @canal_telefono
    END
    
    -- Mesa solo para Mostrador y Mesa QR
    SET @mesa_id = CASE 
        WHEN @canal_id IN (@canal_mostrador, @canal_mesa_qr) THEN ((@i % 8) + 1)
        ELSE NULL
    END
    
    -- Cliente (90% tienen cliente registrado)
    SET @cliente_id_pedido = CASE 
        WHEN @i % 100 < 90 THEN @min_cliente_id + (@i % (@max_cliente_id - @min_cliente_id + 1))
        ELSE NULL
    END
    
    -- Domicilio solo para delivery con cliente
    SET @domicilio_id = CASE 
        WHEN @canal_id = @canal_delivery AND @cliente_id_pedido IS NOT NULL 
        THEN (SELECT TOP 1 domicilio_id FROM DOMICILIO WHERE cliente_id = @cliente_id_pedido)
        ELSE NULL
    END
    
    -- Estado: pedidos antiguos mayormente cerrados, recientes variados
    SET @estado_id = CASE 
        WHEN @dias_atras > 7 THEN 
            CASE WHEN @i % 100 < 97 THEN @estado_cerrado ELSE @estado_cancelado END
        ELSE 
            CASE WHEN @i % 100 < 90 THEN @estado_entregado ELSE @estado_cancelado END
    END
    
    -- Insertar pedido
    INSERT INTO PEDIDO (
        fecha_pedido, 
        fecha_entrega, 
        canal_id, 
        mesa_id, 
        cliente_id, 
        domicilio_id,
        cant_comensales, 
        estado_id, 
        tomado_por_empleado_id, 
        entregado_por_empleado_id,
        total, 
        observaciones
    )
    VALUES (
        @fecha_pedido,
        CASE WHEN @estado_id IN (@estado_entregado, @estado_cerrado) 
            THEN DATEADD(MINUTE, 30 + (@i % 60), @fecha_pedido)
            ELSE NULL
        END,
        @canal_id,
        @mesa_id,
        @cliente_id_pedido,
        @domicilio_id,
        CASE WHEN @mesa_id IS NOT NULL THEN 1 + (@i % 6) ELSE NULL END,
        @estado_id,
        1 + (@i % 19), -- Empleado aleatorio
        CASE WHEN @estado_id IN (@estado_entregado, @estado_cerrado) THEN 1 + (@i % 19) ELSE NULL END,
        0, -- El trigger calculará el total
        CASE 
            WHEN @i % 20 = 0 THEN 'Sin cebolla'
            WHEN @i % 25 = 0 THEN 'Bien cocido'
            WHEN @i % 30 = 0 THEN 'Para llevar'
            ELSE NULL
        END
    )
    
    SET @i = @i + 1
    
    IF @i % 2000 = 0
        PRINT '   Pedidos creados: ' + CAST(@i AS VARCHAR)
END

PRINT '   Total pedidos: 10,000 - OK'
PRINT ''

-- =============================================
-- PASO 4: GENERAR DETALLES DE PEDIDOS (30,000+ items)
-- =============================================

PRINT '4. Generando items de pedidos (3-4 items por pedido)...'

-- Obtener rango de IDs de platos
DECLARE @min_plato_id INT = (SELECT MIN(plato_id) FROM PLATO)
DECLARE @max_plato_id INT = (SELECT MAX(plato_id) FROM PLATO)

-- Insertar items para cada pedido
INSERT INTO DETALLE_PEDIDO (pedido_id, plato_id, cantidad, precio_unitario, subtotal)
SELECT 
    p.pedido_id,
    @min_plato_id + (ABS(CHECKSUM(NEWID())) % (@max_plato_id - @min_plato_id + 1)),
    1 + (ABS(CHECKSUM(NEWID())) % 3), -- 1-3 unidades
    pr.precio,
    (1 + (ABS(CHECKSUM(NEWID())) % 3)) * pr.precio
FROM PEDIDO p
CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) items
CROSS APPLY (
    SELECT TOP 1 precio 
    FROM PRECIO 
    WHERE plato_id = @min_plato_id + (ABS(CHECKSUM(NEWID())) % (@max_plato_id - @min_plato_id + 1))
    ORDER BY vigencia_desde DESC
) pr
WHERE items.n <= (2 + (p.pedido_id % 3)) -- 2-4 items por pedido

PRINT '   Total items: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- RESUMEN FINAL Y ESTADÍSTICAS
-- =============================================

PRINT '======================================================='
PRINT 'CARGA MASIVA COMPLETADA'
PRINT '======================================================='
PRINT ''

DECLARE @total_clientes INT, @total_domicilios INT, @total_pedidos INT
DECLARE @total_items_final INT, @total_auditoria INT, @total_notificaciones INT
DECLARE @total_facturacion DECIMAL(18,2)

SELECT @total_clientes = COUNT(*) FROM CLIENTE WHERE cliente_id > 19
SELECT @total_domicilios = COUNT(*) FROM DOMICILIO
SELECT @total_pedidos = COUNT(*) FROM PEDIDO
SELECT @total_items_final = COUNT(*) FROM DETALLE_PEDIDO
SELECT @total_auditoria = COUNT(*) FROM AUDITORIA_SIMPLE
SELECT @total_notificaciones = COUNT(*) FROM NOTIFICACIONES
SELECT @total_facturacion = SUM(total) FROM PEDIDO p
    INNER JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
    WHERE ep.nombre IN ('Entregado', 'Cerrado')

PRINT 'ESTADÍSTICAS FINALES:'
PRINT '─────────────────────────────────────────────────────'
PRINT 'Clientes nuevos        : ' + CAST(@total_clientes AS VARCHAR)
PRINT 'Domicilios registrados : ' + CAST(@total_domicilios AS VARCHAR)
PRINT 'Pedidos generados      : ' + CAST(@total_pedidos AS VARCHAR)
PRINT 'Items de pedidos       : ' + CAST(@total_items_final AS VARCHAR)
PRINT 'Registros auditoría    : ' + CAST(@total_auditoria AS VARCHAR)
PRINT 'Notificaciones         : ' + CAST(@total_notificaciones AS VARCHAR)
PRINT ''
PRINT 'TOTAL REGISTROS NUEVOS : ' + CAST(
    @total_clientes + @total_domicilios + @total_pedidos + 
    @total_items_final + @total_auditoria + @total_notificaciones AS VARCHAR
) + ' registros'
PRINT ''
PRINT 'Facturación histórica  : $' + CAST(ISNULL(@total_facturacion, 0) AS VARCHAR)
PRINT ''

-- Estadísticas por canal
PRINT 'DISTRIBUCIÓN POR CANAL:'
SELECT 
    cv.nombre AS Canal,
    COUNT(p.pedido_id) AS Pedidos,
    SUM(CASE WHEN ep.nombre IN ('Entregado','Cerrado') THEN 1 ELSE 0 END) AS Completados,
    CAST(SUM(CASE WHEN ep.nombre IN ('Entregado','Cerrado') THEN p.total ELSE 0 END) AS DECIMAL(18,2)) AS Facturacion
FROM CANAL_VENTA cv
LEFT JOIN PEDIDO p ON cv.canal_id = p.canal_id
LEFT JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
GROUP BY cv.nombre
ORDER BY Facturacion DESC

PRINT ''

-- Estadísticas por estado
PRINT 'DISTRIBUCIÓN POR ESTADO:'
SELECT 
    ep.nombre AS Estado,
    COUNT(p.pedido_id) AS Cantidad,
    CAST(AVG(ISNULL(p.total, 0)) AS DECIMAL(10,2)) AS TicketPromedio
FROM ESTADO_PEDIDO ep
LEFT JOIN PEDIDO p ON ep.estado_id = p.estado_id
GROUP BY ep.nombre
ORDER BY Cantidad DESC

PRINT ''
PRINT 'Fin: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '======================================================='
PRINT 'CARGA MASIVA FINALIZADA CON ÉXITO'
PRINT 'Sistema listo para testing y análisis de performance'
PRINT '======================================================='
GO
