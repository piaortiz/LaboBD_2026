-- =============================================
-- BUNDLE A2 - ÍNDICES Y DATOS INICIALES
-- EsbirrosDB - Sistema de Gestión de Bodegón Porteño
-- Negocio: Bodegón Los Esbirros de Claudio
-- Descripción: Índices optimizados y carga de datos iniciales
-- Proyecto Educativo ISTEA - Uso académico exclusivo
-- PROHIBIDA LA COMERCIALIZACIÓN
-- =============================================

USE EsbirrosDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT 'INICIANDO BUNDLE A2 - INDICES Y DATOS INICIALES'
PRINT '================================================='
PRINT 'Sistema: EsbirrosDB - Bodegon Los Esbirros de Claudio'
PRINT ''

-- =============================================
-- PASO 1: ÍNDICES OPTIMIZADOS
-- =============================================
-- Mejores prácticas (mejorespracticas.md §4):
--   · Non-clustered indexes sobre columnas de filtro frecuente
--   · Índices compuestos para consultas multi-campo
--   · Índices filtrados (WHERE IS NOT NULL) para FKs opcionales
-- =============================================

PRINT 'Paso 1/2: Creando indices...'

-- Consultas por fecha y estado (reporte de ventas diario)
CREATE NONCLUSTERED INDEX IX_PEDIDO_fecha_estado
    ON PEDIDO(fecha_pedido, estado_id)
GO

-- Lookup de pedidos por mesa (frecuente en servicio de salón)
CREATE NONCLUSTERED INDEX IX_PEDIDO_mesa
    ON PEDIDO(mesa_id)
    WHERE mesa_id IS NOT NULL
GO

-- Lookup de pedidos por cliente (historial, delivery)
CREATE NONCLUSTERED INDEX IX_PEDIDO_cliente
    ON PEDIDO(cliente_id)
    WHERE cliente_id IS NOT NULL
GO

-- JOIN principal: detalle → pedido
CREATE NONCLUSTERED INDEX IX_DETALLE_PEDIDO_pedido
    ON DETALLE_PEDIDO(pedido_id)
GO

-- JOIN: detalle → plato (ranking de productos populares)
CREATE NONCLUSTERED INDEX IX_DETALLE_PEDIDO_plato
    ON DETALLE_PEDIDO(plato_id)
GO

-- Mesas activas por sucursal
CREATE NONCLUSTERED INDEX IX_MESA_sucursal_activa
    ON MESA(sucursal_id, activa)
GO

-- Empleados activos por sucursal
CREATE NONCLUSTERED INDEX IX_EMPLEADO_sucursal_activo
    ON EMPLEADO(sucursal_id, activo)
GO

-- Precio vigente por plato (composite: evita table scan en sp_AgregarItemPedido)
CREATE NONCLUSTERED INDEX IX_PRECIO_plato_vigencia
    ON PRECIO(plato_id, vigencia_desde, vigencia_hasta)
GO

PRINT 'Indices creados: 8 non-clustered indexes'

-- =============================================
-- PASO 2: DATOS INICIALES
-- =============================================

PRINT 'Paso 2/2: Insertando datos iniciales...'

-- ─── SUCURSAL ────────────────────────────────
INSERT INTO SUCURSAL (nombre, direccion) VALUES
('Los Esbirros de Claudio - San Telmo', 'Defensa 742, San Telmo, CABA')
GO

-- ─── CANALES DE VENTA ────────────────────────
INSERT INTO CANAL_VENTA (nombre) VALUES
('Mostrador'),
('Delivery'),
('Mesa QR'),
('Teléfono'),
('App Móvil')
GO

-- ─── ESTADOS DE PEDIDO ───────────────────────
-- Flujo: Pendiente → Confirmado → En Preparación → Listo → En Reparto → Entregado → Cerrado
-- Cancelado tiene orden 99 (puede ocurrir en cualquier punto)
INSERT INTO ESTADO_PEDIDO (nombre, orden) VALUES
('Pendiente',       1),
('Confirmado',      2),
('En Preparación',  3),
('Listo',           4),
('En Reparto',      5),
('Entregado',       6),
('Cerrado',         7),
('Cancelado',      99)
GO

-- ─── ROLES ───────────────────────────────────
INSERT INTO ROL (nombre, descripcion) VALUES
('Administrador', 'Acceso total al sistema'),
('Gerente',       'Gestión operativa y reportes'),
('Mozo',          'Toma de pedidos y atención de mesas'),
('Cajero',        'Facturación y cobros'),
('Cocinero',      'Preparación de platos en cocina y parrilla a la leña'),
('Repartidor',    'Entregas y delivery'),
('Hostess',       'Recepción y asignación de mesas')
GO

-- ─── MESAS (Sucursal San Telmo) ──────────────
DECLARE @suc_santelmo INT = (SELECT sucursal_id FROM SUCURSAL WHERE nombre LIKE '%San Telmo%')

INSERT INTO MESA (numero, capacidad, sucursal_id, qr_token) VALUES
-- San Telmo (salón principal, mesas de madera típicas de bodegón)
(1, 2,  @suc_santelmo, 'QR_ST_001_' + CONVERT(VARCHAR(36), NEWID())),
(2, 2,  @suc_santelmo, 'QR_ST_002_' + CONVERT(VARCHAR(36), NEWID())),
(3, 4,  @suc_santelmo, 'QR_ST_003_' + CONVERT(VARCHAR(36), NEWID())),
(4, 4,  @suc_santelmo, 'QR_ST_004_' + CONVERT(VARCHAR(36), NEWID())),
(5, 6,  @suc_santelmo, 'QR_ST_005_' + CONVERT(VARCHAR(36), NEWID())),
(6, 6,  @suc_santelmo, 'QR_ST_006_' + CONVERT(VARCHAR(36), NEWID())),
(7, 8,  @suc_santelmo, 'QR_ST_007_' + CONVERT(VARCHAR(36), NEWID())),
(8, 10, @suc_santelmo, 'QR_ST_008_' + CONVERT(VARCHAR(36), NEWID()))
GO

-- ─── EMPLEADO ADMINISTRADOR ──────────────────
DECLARE @rol_admin    INT = (SELECT rol_id      FROM ROL      WHERE nombre = 'Administrador')
DECLARE @suc_santelmo INT = (SELECT sucursal_id FROM SUCURSAL WHERE nombre LIKE '%San Telmo%')

INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Claudio Administrador', 'claudio.admin',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'password_temporal_2026'), 2),
 @rol_admin, @suc_santelmo)
GO

-- ─── PLANTEL DE EMPLEADOS POR ROL ────────────────────
-- Distribución basada en horarios del bodegón:
-- Lunes a Sábado: 12:00-16:00 (almuerzo) y 20:00-00:00 (cena)
-- Domingo: 12:00-17:00 (solo almuerzo)
-- Capacidad: 8 mesas (2-10 comensales) = aprox. 50 personas simultáneas
PRINT 'Generando plantel de empleados por rol...'

DECLARE @rol_gerente     INT = (SELECT rol_id FROM ROL WHERE nombre = 'Gerente')
DECLARE @rol_mozo        INT = (SELECT rol_id FROM ROL WHERE nombre = 'Mozo')
DECLARE @rol_cajero      INT = (SELECT rol_id FROM ROL WHERE nombre = 'Cajero')
DECLARE @rol_cocinero    INT = (SELECT rol_id FROM ROL WHERE nombre = 'Cocinero')
DECLARE @rol_repartidor  INT = (SELECT rol_id FROM ROL WHERE nombre = 'Repartidor')
DECLARE @rol_hostess     INT = (SELECT rol_id FROM ROL WHERE nombre = 'Hostess')
DECLARE @suc_st          INT = (SELECT sucursal_id FROM SUCURSAL WHERE nombre LIKE '%San Telmo%')

-- GERENCIA (1 persona - horario completo)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('María Fernández', 'maria.fernandez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'gerente2026'), 2),
 @rol_gerente, @suc_st)

-- MOZOS (6 personas - 3 turno almuerzo, 3 turno cena)
-- Turno almuerzo (12:00-16:00)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Carlos Ramírez', 'carlos.ramirez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st),
('Lucía Gómez', 'lucia.gomez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st),
('Diego Martínez', 'diego.martinez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st)

-- Turno cena (20:00-00:00)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Ana Torres', 'ana.torres',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st),
('Javier López', 'javier.lopez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st),
('Sofía Benítez', 'sofia.benitez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'mozo2026'), 2),
 @rol_mozo, @suc_st)

-- CAJEROS (2 personas - 1 por turno)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Roberto Sánchez', 'roberto.sanchez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cajero2026'), 2),
 @rol_cajero, @suc_st),
('Patricia Morales', 'patricia.morales',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cajero2026'), 2),
 @rol_cajero, @suc_st)

-- COCINEROS (4 personas - 2 por turno, parrilla a la leña requiere experiencia)
-- Turno almuerzo
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Eduardo "Tito" González', 'eduardo.gonzalez',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cocina2026'), 2),
 @rol_cocinero, @suc_st),
('Marta Navarro', 'marta.navarro',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cocina2026'), 2),
 @rol_cocinero, @suc_st)

-- Turno cena
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Hernán Castro', 'hernan.castro',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cocina2026'), 2),
 @rol_cocinero, @suc_st),
('Silvia Romero', 'silvia.romero',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'cocina2026'), 2),
 @rol_cocinero, @suc_st)

-- REPARTIDORES (3 personas - solo turno cena, delivery nocturno)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Matías Pereyra', 'matias.pereyra',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'delivery2026'), 2),
 @rol_repartidor, @suc_st),
('Fernando Díaz', 'fernando.diaz',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'delivery2026'), 2),
 @rol_repartidor, @suc_st),
('Rodrigo Vega', 'rodrigo.vega',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'delivery2026'), 2),
 @rol_repartidor, @suc_st)

-- HOSTESS (2 personas - 1 por turno, recepción y asignación de mesas)
INSERT INTO EMPLEADO (nombre, usuario, hash_password, rol_id, sucursal_id) VALUES
('Gabriela Paz', 'gabriela.paz',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'hostess2026'), 2),
 @rol_hostess, @suc_st),
('Valeria Ríos', 'valeria.rios',
 CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'hostess2026'), 2),
 @rol_hostess, @suc_st)

PRINT 'Plantel generado: 19 empleados (1 Admin + 1 Gerente + 6 Mozos + 2 Cajeros + 4 Cocineros + 3 Repartidores + 2 Hostess)'
GO

-- ─── MENÚ BODEGÓN PORTEÑO ────────────────────
-- Categorías: Entradas, Pastas, Carnes a la Leña, Guarniciones, Postres, Bebidas
INSERT INTO PLATO (nombre, categoria) VALUES
-- Entradas
('Empanadas de Carne (x6)',         'Entradas'),
('Provoleta a la Parrilla',         'Entradas'),
('Tabla de Fiambres y Quesos',      'Entradas'),
('Morcilla y Chorizo Criollo',      'Entradas'),
-- Pastas
('Fideos con Tuco Casero',          'Pastas'),
('Ñoquis con Estofado',             'Pastas'),
('Lasagna de Carne',                'Pastas'),
('Tallarines con Pesto',            'Pastas'),
-- Carnes a la Leña
('Milanesa Napolitana',             'Carnes a la Leña'),
('Bife de Chorizo a la Leña',       'Carnes a la Leña'),
('Asado de Tira a la Parrilla',     'Carnes a la Leña'),
('Pollo a la Brasa Entero',         'Carnes a la Leña'),
-- Guarniciones
('Papas Fritas',                    'Guarniciones'),
('Puré de Papa',                    'Guarniciones'),
('Ensalada Mixta',                  'Guarniciones'),
-- Postres
('Flan Casero con Dulce de Leche',  'Postres'),
('Panqueques con Dulce de Leche',   'Postres'),
-- Bebidas
('Vino Tinto de la Casa (porrón)',   'Bebidas'),
('Vino Blanco de la Casa (porrón)',  'Bebidas'),
('Cerveza Quilmes (porrón)',         'Bebidas'),
('Agua Mineral (500ml)',             'Bebidas'),
('Gaseosa (lata)',                   'Bebidas')
GO

-- ─── PRECIOS VIGENTES ────────────────────────
INSERT INTO PRECIO (plato_id, vigencia_desde, precio)
SELECT
    plato_id,
    CAST(GETDATE() AS DATE),
    CASE categoria
        WHEN 'Entradas'         THEN
            CASE nombre
                WHEN 'Empanadas de Carne (x6)'    THEN 3200.00
                WHEN 'Provoleta a la Parrilla'     THEN 2800.00
                WHEN 'Tabla de Fiambres y Quesos'  THEN 4500.00
                WHEN 'Morcilla y Chorizo Criollo'  THEN 2600.00
                ELSE 2500.00
            END
        WHEN 'Pastas'           THEN
            CASE nombre
                WHEN 'Fideos con Tuco Casero'  THEN 3800.00
                WHEN 'Ñoquis con Estofado'     THEN 4200.00
                WHEN 'Lasagna de Carne'        THEN 4500.00
                WHEN 'Tallarines con Pesto'    THEN 3600.00
                ELSE 3500.00
            END
        WHEN 'Carnes a la Leña' THEN
            CASE nombre
                WHEN 'Milanesa Napolitana'         THEN 5500.00
                WHEN 'Bife de Chorizo a la Leña'   THEN 7800.00
                WHEN 'Asado de Tira a la Parrilla' THEN 6500.00
                WHEN 'Pollo a la Brasa Entero'     THEN 5800.00
                ELSE 5000.00
            END
        WHEN 'Guarniciones'     THEN 1500.00
        WHEN 'Postres'          THEN 2200.00
        WHEN 'Bebidas'          THEN
            CASE nombre
                WHEN 'Vino Tinto de la Casa (porrón)'  THEN 2500.00
                WHEN 'Vino Blanco de la Casa (porrón)' THEN 2500.00
                WHEN 'Cerveza Quilmes (porrón)'        THEN 1200.00
                WHEN 'Agua Mineral (500ml)'            THEN  600.00
                WHEN 'Gaseosa (lata)'                  THEN  900.00
                ELSE 800.00
            END
        ELSE 1000.00
    END
FROM PLATO
GO

-- =============================================
-- VALIDACIÓN
-- =============================================

PRINT ''
PRINT 'Validando instalacion...'

DECLARE @sucursales INT = (SELECT COUNT(*) FROM SUCURSAL)
DECLARE @canales    INT = (SELECT COUNT(*) FROM CANAL_VENTA)
DECLARE @estados    INT = (SELECT COUNT(*) FROM ESTADO_PEDIDO)
DECLARE @roles      INT = (SELECT COUNT(*) FROM ROL)
DECLARE @mesas      INT = (SELECT COUNT(*) FROM MESA)
DECLARE @platos     INT = (SELECT COUNT(*) FROM PLATO)
DECLARE @precios    INT = (SELECT COUNT(*) FROM PRECIO)

PRINT 'Sucursales     : ' + CAST(@sucursales AS VARCHAR)
PRINT 'Canales venta  : ' + CAST(@canales    AS VARCHAR)
PRINT 'Estados pedido : ' + CAST(@estados    AS VARCHAR)
PRINT 'Roles          : ' + CAST(@roles      AS VARCHAR)
PRINT 'Mesas          : ' + CAST(@mesas      AS VARCHAR)
PRINT 'Platos (menu)  : ' + CAST(@platos     AS VARCHAR)
PRINT 'Precios cargados: ' + CAST(@precios   AS VARCHAR)

PRINT ''
PRINT 'BUNDLE A2 COMPLETADO!'
PRINT '================================================='
PRINT 'Indices: 8 non-clustered'
PRINT 'Datos  : Menu bodegon porteno cargado'
PRINT ''
PRINT 'SIGUIENTE PASO: Ejecutar Bundle_B1_Pedidos_Core.sql'
PRINT '================================================='
GO
