-- =============================================
-- SCRIPT DE CARGA MASIVA DE DATOS - ESBIRROSDB
-- Genera 10,000+ registros de prueba para testing
-- Negocio: Bodegón Los Esbirros de Claudio
-- ADVERTENCIA: Este script puede tardar varios minutos
-- =============================================

USE EsbirrosDB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '======================================================='
PRINT 'CARGA MASIVA DE DATOS - ESBIRROSDB'
PRINT '======================================================='
PRINT 'Generando datos de prueba para testing y performance...'
PRINT 'ADVERTENCIA: Este proceso puede tardar 5-10 minutos'
PRINT ''
PRINT 'Inicio: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''

-- =============================================
-- PASO 1: GENERAR CLIENTES (3,000 clientes)
-- =============================================

PRINT '1. Generando 3,000 clientes...'

DECLARE @i INT = 1
DECLARE @nombre_cliente NVARCHAR(100)
DECLARE @telefono NVARCHAR(20)
DECLARE @email NVARCHAR(100)
DECLARE @doc_tipo NVARCHAR(10)
DECLARE @doc_nro NVARCHAR(20)

WHILE @i <= 3000
BEGIN
    SET @nombre_cliente = CASE (@i % 20)
        WHEN 0 THEN 'Juan ' + CAST(@i AS VARCHAR)
        WHEN 1 THEN 'María ' + CAST(@i AS VARCHAR)
        WHEN 2 THEN 'Carlos ' + CAST(@i AS VARCHAR)
        WHEN 3 THEN 'Ana ' + CAST(@i AS VARCHAR)
        WHEN 4 THEN 'Roberto ' + CAST(@i AS VARCHAR)
        WHEN 5 THEN 'Laura ' + CAST(@i AS VARCHAR)
        WHEN 6 THEN 'Diego ' + CAST(@i AS VARCHAR)
        WHEN 7 THEN 'Gabriela ' + CAST(@i AS VARCHAR)
        WHEN 8 THEN 'Martín ' + CAST(@i AS VARCHAR)
        WHEN 9 THEN 'Valeria ' + CAST(@i AS VARCHAR)
        WHEN 10 THEN 'Sergio ' + CAST(@i AS VARCHAR)
        WHEN 11 THEN 'Patricia ' + CAST(@i AS VARCHAR)
        WHEN 12 THEN 'Fernando ' + CAST(@i AS VARCHAR)
        WHEN 13 THEN 'Silvia ' + CAST(@i AS VARCHAR)
        WHEN 14 THEN 'Pablo ' + CAST(@i AS VARCHAR)
        WHEN 15 THEN 'Claudia ' + CAST(@i AS VARCHAR)
        WHEN 16 THEN 'Gustavo ' + CAST(@i AS VARCHAR)
        WHEN 17 THEN 'Andrea ' + CAST(@i AS VARCHAR)
        WHEN 18 THEN 'Ricardo ' + CAST(@i AS VARCHAR)
        ELSE 'Mónica ' + CAST(@i AS VARCHAR)
    END + ' Pérez'

    SET @telefono = '11' + RIGHT('0000' + CAST(@i AS VARCHAR), 4) + RIGHT('0000' + CAST(@i * 2 AS VARCHAR), 4)
    SET @email = 'cliente' + CAST(@i AS VARCHAR) + '@email.com'
    SET @doc_tipo = 'DNI'
    SET @doc_nro = CAST(20000000 + @i AS VARCHAR)

    INSERT INTO CLIENTE (nombre, telefono, email, doc_tipo, doc_nro)
    VALUES (@nombre_cliente, @telefono, @email, @doc_tipo, @doc_nro)

    SET @i = @i + 1

    -- Progress indicator cada 500 registros
    IF @i % 500 = 0
        PRINT '   Clientes creados: ' + CAST(@i AS VARCHAR)
END

PRINT '   Total clientes: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 2: GENERAR DOMICILIOS (4,500 domicilios)
-- Algunos clientes tienen múltiples domicilios
-- =============================================

PRINT '2. Generando 4,500 domicilios...'

SET @i = 1
DECLARE @cliente_id INT
DECLARE @calle NVARCHAR(100)
DECLARE @numero NVARCHAR(10)
DECLARE @localidad NVARCHAR(50)
DECLARE @es_principal BIT

WHILE @i <= 4500
BEGIN
    -- Distribuir domicilios entre los 3000 clientes
    SET @cliente_id = ((@i - 1) % 3000) + 1
    
    SET @calle = CASE ((@i % 15))
        WHEN 0 THEN 'Av. Caseros'
        WHEN 1 THEN 'Defensa'
        WHEN 2 THEN 'Bolivar'
        WHEN 3 THEN 'Piedras'
        WHEN 4 THEN 'Balcarce'
        WHEN 5 THEN 'Paseo Colón'
        WHEN 6 THEN 'Av. San Juan'
        WHEN 7 THEN 'Humberto Primo'
        WHEN 8 THEN 'Carlos Calvo'
        WHEN 9 THEN 'Av. Belgrano'
        WHEN 10 THEN 'México'
        WHEN 11 THEN 'Chile'
        WHEN 12 THEN 'Independencia'
        WHEN 13 THEN 'Estados Unidos'
        ELSE 'Brasil'
    END

    SET @numero = CAST(100 + (@i % 900) AS VARCHAR)
    
    SET @localidad = CASE (@i % 10)
        WHEN 0 THEN 'San Telmo'
        WHEN 1 THEN 'La Boca'
        WHEN 2 THEN 'Constitución'
        WHEN 3 THEN 'Monserrat'
        WHEN 4 THEN 'Puerto Madero'
        WHEN 5 THEN 'Barracas'
        WHEN 6 THEN 'Parque Patricios'
        WHEN 7 THEN 'Pompeya'
        WHEN 8 THEN 'Nueva Pompeya'
        ELSE 'Boedo'
    END

    -- El primer domicilio de cada cliente es principal
    SET @es_principal = CASE WHEN @i <= 3000 THEN 1 ELSE 0 END

    INSERT INTO DOMICILIO (cliente_id, calle, numero, piso, depto, localidad, provincia, es_principal)
    VALUES (
        @cliente_id, 
        @calle, 
        @numero,
        CASE WHEN @i % 3 = 0 THEN CAST((@i % 10) + 1 AS VARCHAR) ELSE NULL END,
        CASE WHEN @i % 3 = 0 THEN CHAR(65 + (@i % 8)) ELSE NULL END,
        @localidad,
        'Buenos Aires',
        @es_principal
    )

    SET @i = @i + 1

    IF @i % 1000 = 0
        PRINT '   Domicilios creados: ' + CAST(@i AS VARCHAR)
END

PRINT '   Total domicilios: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 3: GENERAR PEDIDOS (10,000 pedidos)
-- Distribuidos en los últimos 180 días
-- =============================================

PRINT '3. Generando 10,000 pedidos en últimos 180 días...'

SET @i = 1
DECLARE @fecha_pedido DATETIME
DECLARE @canal_id INT
DECLARE @mesa_id INT
DECLARE @cliente_id_pedido INT
DECLARE @domicilio_id INT
DECLARE @estado_id INT
DECLARE @cant_comensales INT
DECLARE @observaciones NVARCHAR(500)
DECLARE @dias_atras INT

-- Obtener IDs de estados para distribución realista
DECLARE @estado_pendiente INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Pendiente')
DECLARE @estado_confirmado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Confirmado')
DECLARE @estado_preparacion INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'En Preparacion')
DECLARE @estado_listo INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Listo')
DECLARE @estado_reparto INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'En Reparto')
DECLARE @estado_entregado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Entregado')
DECLARE @estado_cerrado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Cerrado')
DECLARE @estado_cancelado INT = (SELECT estado_id FROM ESTADO_PEDIDO WHERE nombre = 'Cancelado')

-- Obtener IDs de canales (solo los que existen)
DECLARE @canal_presencial INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Mostrador')
DECLARE @canal_delivery INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Delivery')
DECLARE @canal_mesa_qr INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Mesa QR')
DECLARE @canal_telefono INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'Telefono')
DECLARE @canal_app INT = (SELECT canal_id FROM CANAL_VENTA WHERE nombre = 'App Movil')

-- Validación de canales
IF @canal_presencial IS NULL OR @canal_delivery IS NULL
BEGIN
    PRINT 'ERROR: No se encontraron los canales necesarios (Mostrador/Delivery)'
    RETURN
END

PRINT '   Canales detectados: Mostrador=' + CAST(@canal_presencial AS VARCHAR) + ', Delivery=' + CAST(@canal_delivery AS VARCHAR)

WHILE @i <= 10000
BEGIN
    -- Distribuir pedidos en últimos 180 días (más recientes tienen más pedidos)
    SET @dias_atras = CASE 
        WHEN @i % 100 < 30 THEN @i % 7        -- 30% en última semana
        WHEN @i % 100 < 60 THEN 7 + (@i % 23) -- 30% en último mes
        ELSE 30 + (@i % 150)                   -- 40% en últimos 6 meses
    END
    
    SET @fecha_pedido = DATEADD(DAY, -@dias_atras, GETDATE())
    SET @fecha_pedido = DATEADD(HOUR, 11 + (@i % 11), @fecha_pedido) -- Horario comercial 11-22hs
    SET @fecha_pedido = DATEADD(MINUTE, @i % 60, @fecha_pedido)

    -- Distribución de canales: 50% Mostrador, 25% Delivery, 15% Mesa QR, 7% Telefono, 3% App
    SET @canal_id = CASE 
        WHEN @i % 100 < 50 THEN @canal_presencial
        WHEN @i % 100 < 75 THEN @canal_delivery
        WHEN @i % 100 < 90 AND @canal_mesa_qr IS NOT NULL THEN @canal_mesa_qr
        WHEN @i % 100 < 97 AND @canal_telefono IS NOT NULL THEN @canal_telefono
        WHEN @canal_app IS NOT NULL THEN @canal_app
        ELSE @canal_presencial -- Fallback
    END

    -- Mesa para canales presenciales (Mostrador y Mesa QR)
    SET @mesa_id = CASE 
        WHEN @canal_id IN (@canal_presencial, @canal_mesa_qr) THEN ((@i % 8) + 1)
        ELSE NULL
    END

    -- Cliente (80% tienen cliente registrado)
    SET @cliente_id_pedido = CASE 
        WHEN @i % 100 < 80 THEN ((@i % 3000) + 1)
        ELSE NULL
    END

    -- Domicilio solo para delivery
    SET @domicilio_id = CASE 
        WHEN @canal_id = @canal_delivery AND @cliente_id_pedido IS NOT NULL 
        THEN (SELECT TOP 1 domicilio_id FROM DOMICILIO WHERE cliente_id = @cliente_id_pedido ORDER BY es_principal DESC)
        ELSE NULL
    END

    -- Cantidad de comensales (1-6 personas, solo para canales con mesa)
    SET @cant_comensales = CASE 
        WHEN @canal_id IN (@canal_presencial, @canal_mesa_qr) THEN 1 + (@i % 6)
        ELSE NULL
    END

    -- Estado realista según antigüedad
    -- Pedidos antiguos: mayoría Entregado/Cerrado
    -- Pedidos recientes: mix de estados
    SET @estado_id = CASE 
        WHEN @dias_atras > 7 THEN 
            CASE WHEN @i % 100 < 95 THEN @estado_cerrado ELSE @estado_cancelado END
        WHEN @dias_atras > 1 THEN 
            CASE 
                WHEN @i % 100 < 85 THEN @estado_cerrado
                WHEN @i % 100 < 90 THEN @estado_entregado
                ELSE @estado_cancelado
            END
        ELSE -- Pedidos de hoy: variedad de estados
            CASE 
                WHEN @i % 100 < 40 THEN @estado_cerrado
                WHEN @i % 100 < 50 THEN @estado_entregado
                WHEN @i % 100 < 60 THEN @estado_listo
                WHEN @i % 100 < 75 THEN @estado_preparacion
                WHEN @i % 100 < 85 THEN @estado_confirmado
                WHEN @i % 100 < 95 THEN @estado_pendiente
                ELSE @estado_cancelado
            END
    END

    SET @observaciones = CASE 
        WHEN @i % 10 = 0 THEN 'Sin cebolla'
        WHEN @i % 15 = 0 THEN 'Bien cocido'
        WHEN @i % 20 = 0 THEN 'Sin sal'
        WHEN @i % 25 = 0 THEN 'Para llevar'
        WHEN @i % 30 = 0 THEN 'Urgente'
        ELSE NULL
    END

    INSERT INTO PEDIDO (
        fecha_pedido, fecha_entrega, canal_id, mesa_id, cliente_id, domicilio_id,
        cant_comensales, estado_id, tomado_por_empleado_id, entregado_por_empleado_id,
        total, observaciones
    )
    VALUES (
        @fecha_pedido,
        CASE 
            WHEN @estado_id IN (@estado_entregado, @estado_cerrado) 
            THEN DATEADD(MINUTE, 30 + (@i % 60), @fecha_pedido)
            ELSE NULL
        END,
        @canal_id,
        @mesa_id,
        @cliente_id_pedido,
        @domicilio_id,
        @cant_comensales,
        @estado_id,
        1, -- empleado_id fijo por ahora
        CASE WHEN @estado_id IN (@estado_entregado, @estado_cerrado) THEN 1 ELSE NULL END,
        0, -- Total se calculará con trigger al agregar items
        @observaciones
    )

    SET @i = @i + 1

    IF @i % 1000 = 0
        PRINT '   Pedidos creados: ' + CAST(@i AS VARCHAR)
END

PRINT '   Total pedidos: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 4: GENERAR DETALLES DE PEDIDOS (30,000+ items)
-- Promedio 3 items por pedido
-- =============================================

PRINT '4. Generando 30,000+ items de pedidos...'

SET @i = 1
DECLARE @pedido_id INT
DECLARE @plato_id INT
DECLARE @cantidad INT
DECLARE @precio_unitario DECIMAL(10,2)
DECLARE @subtotal DECIMAL(10,2)
DECLARE @items_por_pedido INT
DECLARE @item_num INT
DECLARE @total_items INT = 0

-- Recorrer todos los pedidos y agregar items
DECLARE cursor_pedidos CURSOR FOR
    SELECT pedido_id FROM PEDIDO ORDER BY pedido_id

OPEN cursor_pedidos
FETCH NEXT FROM cursor_pedidos INTO @pedido_id

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Cada pedido tiene entre 1 y 6 items (promedio ~3)
    SET @items_por_pedido = 1 + (@pedido_id % 6)
    SET @item_num = 1

    WHILE @item_num <= @items_por_pedido
    BEGIN
        -- Seleccionar plato aleatorio (22 platos disponibles)
        SET @plato_id = ((@pedido_id * @item_num) % 22) + 1
        
        -- Cantidad: mayoría 1-2, algunos 3-4
        SET @cantidad = CASE 
            WHEN @pedido_id % 10 < 7 THEN 1
            WHEN @pedido_id % 10 < 9 THEN 2
            WHEN @pedido_id % 10 < 10 THEN 3
            ELSE 4
        END

        -- Obtener precio vigente del plato
        SELECT @precio_unitario = precio
        FROM PRECIO
        WHERE plato_id = @plato_id
          AND vigencia_desde <= GETDATE()
          AND (vigencia_hasta IS NULL OR vigencia_hasta >= GETDATE())
        
        IF @precio_unitario IS NULL
            SET @precio_unitario = 1500.00 -- Precio por defecto

        SET @subtotal = @cantidad * @precio_unitario

        INSERT INTO DETALLE_PEDIDO (pedido_id, plato_id, cantidad, precio_unitario, subtotal)
        VALUES (@pedido_id, @plato_id, @cantidad, @precio_unitario, @subtotal)

        SET @item_num = @item_num + 1
        SET @total_items = @total_items + 1
    END

    FETCH NEXT FROM cursor_pedidos INTO @pedido_id

    IF @total_items % 5000 = 0
        PRINT '   Items creados: ' + CAST(@total_items AS VARCHAR)
END

CLOSE cursor_pedidos
DEALLOCATE cursor_pedidos

PRINT '   Total items: ' + CAST(@total_items AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 5: ACTUALIZAR STOCK SIMULADO
-- Descontar del stock inicial según ventas
-- =============================================

PRINT '5. Actualizando stock simulado según ventas...'

UPDATE s
SET stock_disponible = 100 - ISNULL(vendidos.total_vendido, 0)
FROM STOCK_SIMULADO s
LEFT JOIN (
    SELECT 
        dp.plato_id,
        SUM(dp.cantidad) AS total_vendido
    FROM DETALLE_PEDIDO dp
    INNER JOIN PEDIDO p ON dp.pedido_id = p.pedido_id
    INNER JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
    WHERE ep.nombre IN ('Entregado', 'Cerrado')
    GROUP BY dp.plato_id
) vendidos ON s.plato_id = vendidos.plato_id

PRINT '   Stock actualizado - OK'
PRINT ''

-- =============================================
-- PASO 6: GENERAR DATOS DE AUDITORÍA HISTÓRICA
-- Simular actividad de auditoría
-- =============================================

PRINT '6. Generando registros de auditoría histórica...'

-- La tabla AUDITORIA_SIMPLE se llena automáticamente con triggers
-- pero podemos agregar algunas entradas históricas de ejemplo

INSERT INTO AUDITORIA_SIMPLE (tabla_afectada, registro_id, accion, fecha_auditoria, usuario_sistema, datos_resumen)
SELECT TOP 500
    'PEDIDO',
    pedido_id,
    'INSERT',
    fecha_pedido,
    'SYSTEM',
    'Pedido histórico generado por carga masiva - Total: $' + CAST(total AS VARCHAR)
FROM PEDIDO
ORDER BY NEWID() -- Orden aleatorio

PRINT '   Registros de auditoría: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- PASO 7: GENERAR NOTIFICACIONES HISTÓRICAS
-- =============================================

PRINT '7. Generando notificaciones históricas...'

INSERT INTO NOTIFICACIONES (tipo, titulo, mensaje, pedido_id, mesa_id, prioridad, fecha_creacion, leida, usuario_destino)
SELECT TOP 1000
    CASE 
        WHEN ep.nombre = 'En Preparacion' THEN 'PEDIDO_EN_PREPARACION'
        WHEN ep.nombre = 'Listo' THEN 'PEDIDO_LISTO'
        WHEN ep.nombre = 'Cerrado' THEN 'PEDIDO_CERRADO'
        WHEN ep.nombre = 'Cancelado' THEN 'PEDIDO_CANCELADO'
        ELSE 'PEDIDO_ACTUALIZADO'
    END,
    'Pedido #' + CAST(p.pedido_id AS VARCHAR) + ' - ' + ep.nombre,
    'Estado: ' + ep.nombre + ', Total: $' + CAST(p.total AS VARCHAR),
    p.pedido_id,
    p.mesa_id,
    CASE 
        WHEN ep.nombre = 'Cancelado' THEN 'CRITICA'
        WHEN ep.nombre IN ('En Preparacion', 'Listo') THEN 'ALTA'
        ELSE 'NORMAL'
    END,
    p.fecha_pedido,
    1, -- Leídas (históricas)
    CASE 
        WHEN ep.nombre IN ('En Preparacion', 'Cancelado') THEN 'COCINA'
        WHEN ep.nombre = 'Listo' THEN 'MOZOS'
        WHEN ep.nombre = 'Cerrado' THEN 'CAJA'
        ELSE 'GENERAL'
    END
FROM PEDIDO p
INNER JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
WHERE ep.nombre IN ('En Preparacion', 'Listo', 'Cerrado', 'Cancelado')
ORDER BY NEWID()

PRINT '   Notificaciones históricas: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' - OK'
PRINT ''

-- =============================================
-- RESUMEN FINAL Y ESTADÍSTICAS
-- =============================================

PRINT '======================================================='
PRINT 'CARGA MASIVA COMPLETADA'
PRINT '======================================================='
PRINT ''

DECLARE @total_clientes INT, @total_domicilios INT, @total_pedidos INT
DECLARE @total_auditoria INT, @total_notificaciones INT, @total_facturacion DECIMAL(18,2)
DECLARE @total_items_final INT

SELECT @total_clientes = COUNT(*) FROM CLIENTE
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
PRINT 'Clientes registrados   : ' + CAST(@total_clientes AS VARCHAR)
PRINT 'Domicilios registrados : ' + CAST(@total_domicilios AS VARCHAR)
PRINT 'Pedidos generados      : ' + CAST(@total_pedidos AS VARCHAR)
PRINT 'Items de pedidos       : ' + CAST(@total_items_final AS VARCHAR)
PRINT 'Registros auditoría    : ' + CAST(@total_auditoria AS VARCHAR)
PRINT 'Notificaciones         : ' + CAST(@total_notificaciones AS VARCHAR)
PRINT ''
PRINT 'TOTAL REGISTROS        : ' + CAST(
    @total_clientes + @total_domicilios + @total_pedidos + 
    @total_items_final + @total_auditoria + @total_notificaciones AS VARCHAR
) + ' registros'
PRINT ''
PRINT 'Facturación histórica  : $' + CAST(@total_facturacion AS VARCHAR)
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
    CAST(AVG(p.total) AS DECIMAL(10,2)) AS TicketPromedio
FROM ESTADO_PEDIDO ep
LEFT JOIN PEDIDO p ON ep.estado_id = p.estado_id
GROUP BY ep.nombre, ep.orden
ORDER BY ep.orden

PRINT ''

-- Top 10 platos más vendidos
PRINT 'TOP 10 PLATOS MÁS VENDIDOS:'
SELECT TOP 10
    pl.nombre AS Plato,
    pl.categoria AS Categoria,
    SUM(dp.cantidad) AS CantidadVendida,
    CAST(SUM(dp.subtotal) AS DECIMAL(18,2)) AS Ingresos
FROM PLATO pl
INNER JOIN DETALLE_PEDIDO dp ON pl.plato_id = dp.plato_id
INNER JOIN PEDIDO p ON dp.pedido_id = p.pedido_id
INNER JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
WHERE ep.nombre IN ('Entregado', 'Cerrado')
GROUP BY pl.plato_id, pl.nombre, pl.categoria
ORDER BY SUM(dp.cantidad) DESC

PRINT ''
PRINT 'Fin: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '======================================================='
PRINT 'SISTEMA LISTO PARA TESTING Y PERFORMANCE'
PRINT 'Base de datos: EsbirrosDB'
PRINT 'Negocio: Bodegon Los Esbirros de Claudio'
PRINT '======================================================='
GO
