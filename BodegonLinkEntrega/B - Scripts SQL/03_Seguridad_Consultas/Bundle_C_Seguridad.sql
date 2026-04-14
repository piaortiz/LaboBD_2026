-- =============================================
-- BUNDLE C - SEGURIDAD
-- EsbirrosDB - Sistema de Gestión de Bodegón Porteño
-- Negocio: Bodegón Los Esbirros de Claudio
-- Descripción: Roles de aplicación, permisos y usuarios de BD
-- Proyecto Educativo ISTEA - Uso académico exclusivo
-- PROHIBIDA LA COMERCIALIZACIÓN
-- =============================================

USE EsbirrosDB
GO

PRINT 'INICIANDO BUNDLE C - SEGURIDAD'
PRINT '================================='
PRINT 'Sistema: EsbirrosDB - Bodegon Los Esbirros de Claudio'
PRINT ''

-- =============================================
-- PASO 1: CREAR ROLES DE APLICACIÓN
-- =============================================

PRINT 'Paso 1/3: Creando roles de seguridad...'

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_administrador')
BEGIN CREATE ROLE [rol_administrador]; PRINT 'Rol rol_administrador creado'; END
ELSE PRINT 'Rol rol_administrador ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_empleado')
BEGIN CREATE ROLE [rol_empleado]; PRINT 'Rol rol_empleado creado'; END
ELSE PRINT 'Rol rol_empleado ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_cajero')
BEGIN CREATE ROLE [rol_cajero]; PRINT 'Rol rol_cajero creado'; END
ELSE PRINT 'Rol rol_cajero ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_delivery')
BEGIN CREATE ROLE [rol_delivery]; PRINT 'Rol rol_delivery creado'; END
ELSE PRINT 'Rol rol_delivery ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_cliente')
BEGIN CREATE ROLE [rol_cliente]; PRINT 'Rol rol_cliente creado'; END
ELSE PRINT 'Rol rol_cliente ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_reportes')
BEGIN CREATE ROLE [rol_reportes]; PRINT 'Rol rol_reportes creado'; END
ELSE PRINT 'Rol rol_reportes ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_aplicacion_web')
BEGIN CREATE ROLE [rol_aplicacion_web]; PRINT 'Rol rol_aplicacion_web creado'; END
ELSE PRINT 'Rol rol_aplicacion_web ya existe';

-- HM-10: Rol cocinero
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_cocinero')
BEGIN CREATE ROLE [rol_cocinero]; PRINT 'Rol rol_cocinero creado'; END
ELSE PRINT 'Rol rol_cocinero ya existe';
GO

-- =============================================
-- PASO 2: ASIGNAR PERMISOS POR ROL
-- =============================================

PRINT 'Paso 2/3: Configurando permisos por rol...'

-- ROL ADMINISTRADOR: acceso completo
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [rol_administrador];
GRANT EXECUTE ON SCHEMA::dbo TO [rol_administrador];
PRINT 'Permisos rol_administrador configurados';

-- ROL EMPLEADO: operaciones básicas (mozo, cocinero)
GRANT SELECT ON SCHEMA::dbo TO [rol_empleado];
GRANT EXECUTE ON dbo.sp_CrearPedido        TO [rol_empleado];
GRANT EXECUTE ON dbo.sp_AgregarItemPedido  TO [rol_empleado];
GRANT EXECUTE ON dbo.sp_CalcularTotalPedido TO [rol_empleado];
GRANT INSERT, UPDATE ON PEDIDO         TO [rol_empleado];
GRANT INSERT, UPDATE ON DETALLE_PEDIDO TO [rol_empleado];
PRINT 'Permisos rol_empleado configurados';

-- ROL CAJERO: operaciones + cierre de caja
GRANT SELECT ON SCHEMA::dbo TO [rol_cajero];
GRANT EXECUTE ON dbo.sp_CrearPedido        TO [rol_cajero];
GRANT EXECUTE ON dbo.sp_AgregarItemPedido  TO [rol_cajero];
GRANT EXECUTE ON dbo.sp_CalcularTotalPedido TO [rol_cajero];
GRANT EXECUTE ON dbo.sp_CerrarPedido       TO [rol_cajero];
GRANT INSERT, UPDATE ON PEDIDO         TO [rol_cajero];
GRANT INSERT, UPDATE ON DETALLE_PEDIDO TO [rol_cajero];
PRINT 'Permisos rol_cajero configurados';

-- ROL DELIVERY: lectura de pedidos + actualización de estado
GRANT SELECT ON PEDIDO         TO [rol_delivery];
GRANT SELECT ON DETALLE_PEDIDO TO [rol_delivery];
GRANT SELECT ON PLATO          TO [rol_delivery];
GRANT SELECT ON CLIENTE        TO [rol_delivery];
GRANT UPDATE ON PEDIDO         TO [rol_delivery];
PRINT 'Permisos rol_delivery configurados';

-- ROL CLIENTE: lectura de menú y sus propios pedidos
GRANT SELECT ON PEDIDO         TO [rol_cliente];
GRANT SELECT ON DETALLE_PEDIDO TO [rol_cliente];
GRANT SELECT ON PLATO          TO [rol_cliente];
GRANT SELECT ON PRECIO         TO [rol_cliente];
PRINT 'Permisos rol_cliente configurados';

-- ROL REPORTES: solo lectura (gerencia, BI)
GRANT SELECT ON SCHEMA::dbo TO [rol_reportes];
PRINT 'Permisos rol_reportes configurados';

-- ROL APLICACION WEB: permisos granulares (HM-09)
GRANT SELECT ON dbo.SUCURSAL       TO [rol_aplicacion_web];
GRANT SELECT ON dbo.CANAL_VENTA    TO [rol_aplicacion_web];
GRANT SELECT ON dbo.ESTADO_PEDIDO  TO [rol_aplicacion_web];
GRANT SELECT ON dbo.ROL            TO [rol_aplicacion_web];
GRANT SELECT ON dbo.MESA           TO [rol_aplicacion_web];
GRANT SELECT ON dbo.EMPLEADO       TO [rol_aplicacion_web];
GRANT SELECT ON dbo.CLIENTE        TO [rol_aplicacion_web];
GRANT SELECT ON dbo.DOMICILIO      TO [rol_aplicacion_web];
GRANT SELECT ON dbo.PLATO          TO [rol_aplicacion_web];
GRANT SELECT ON dbo.PRECIO         TO [rol_aplicacion_web];
GRANT SELECT, INSERT, UPDATE ON dbo.PEDIDO          TO [rol_aplicacion_web];
GRANT SELECT, INSERT, UPDATE ON dbo.DETALLE_PEDIDO  TO [rol_aplicacion_web];
GRANT SELECT, INSERT         ON dbo.CLIENTE         TO [rol_aplicacion_web];
GRANT SELECT, INSERT         ON dbo.DOMICILIO       TO [rol_aplicacion_web];
GRANT SELECT ON dbo.NOTIFICACIONES    TO [rol_aplicacion_web];
GRANT SELECT ON dbo.STOCK_SIMULADO    TO [rol_aplicacion_web];
GRANT SELECT ON dbo.REPORTES_GENERADOS TO [rol_aplicacion_web];
GRANT EXECUTE ON SCHEMA::dbo TO [rol_aplicacion_web];
-- Denegar escritura en tablas de auditoría
DENY INSERT, UPDATE, DELETE ON dbo.AUDITORIA_SIMPLE TO [rol_aplicacion_web];
PRINT 'Permisos rol_aplicacion_web configurados (granular, HM-09)';

-- ROL COCINERO: consulta de pedidos + marcar estado (HM-10)
GRANT SELECT ON dbo.PEDIDO          TO [rol_cocinero];
GRANT SELECT ON dbo.DETALLE_PEDIDO  TO [rol_cocinero];
GRANT SELECT ON dbo.PLATO           TO [rol_cocinero];
GRANT SELECT ON dbo.ESTADO_PEDIDO   TO [rol_cocinero];
GRANT SELECT ON dbo.STOCK_SIMULADO  TO [rol_cocinero];
GRANT SELECT ON dbo.NOTIFICACIONES  TO [rol_cocinero];
GRANT EXECUTE ON dbo.sp_ActualizarEstadoPedido   TO [rol_cocinero];
GRANT EXECUTE ON dbo.sp_ConsultarNotificaciones  TO [rol_cocinero];
GRANT EXECUTE ON dbo.sp_MarcarNotificacionLeida  TO [rol_cocinero];
GRANT EXECUTE ON dbo.sp_ConsultarStock           TO [rol_cocinero];
PRINT 'Permisos rol_cocinero configurados';
GO

-- =============================================
-- PASO 3: CREAR USUARIOS DE APLICACIÓN
-- =============================================

PRINT 'Paso 3/3: Creando usuarios de aplicacion...'

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app_esbirros_web')
BEGIN
    CREATE USER [app_esbirros_web] WITHOUT LOGIN;
    ALTER ROLE [rol_aplicacion_web] ADD MEMBER [app_esbirros_web];
    PRINT 'Usuario app_esbirros_web creado y asignado a rol_aplicacion_web';
END
ELSE PRINT 'Usuario app_esbirros_web ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app_esbirros_reportes')
BEGIN
    CREATE USER [app_esbirros_reportes] WITHOUT LOGIN;
    ALTER ROLE [rol_reportes] ADD MEMBER [app_esbirros_reportes];
    PRINT 'Usuario app_esbirros_reportes creado y asignado a rol_reportes';
END
ELSE PRINT 'Usuario app_esbirros_reportes ya existe';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app_esbirros_delivery')
BEGIN
    CREATE USER [app_esbirros_delivery] WITHOUT LOGIN;
    ALTER ROLE [rol_delivery] ADD MEMBER [app_esbirros_delivery];
    PRINT 'Usuario app_esbirros_delivery creado y asignado a rol_delivery';
END
ELSE PRINT 'Usuario app_esbirros_delivery ya existe';
GO

-- =============================================
-- FUNCIÓN: VALIDAR PERMISO DE USUARIO
-- =============================================

IF OBJECT_ID('fn_ValidarPermisoUsuario', 'FN') IS NOT NULL
    DROP FUNCTION fn_ValidarPermisoUsuario
GO

CREATE FUNCTION fn_ValidarPermisoUsuario(
    @usuario NVARCHAR(128),
    @objeto  NVARCHAR(128),
    @permiso NVARCHAR(128)
)
RETURNS BIT
AS
BEGIN
    DECLARE @tiene_permiso BIT = 0

    IF EXISTS (
        SELECT 1
        FROM sys.database_permissions dp
        INNER JOIN sys.objects o            ON dp.major_id             = o.object_id
        INNER JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id
        WHERE p.name             = @usuario
          AND o.name             = @objeto
          AND dp.permission_name = @permiso
          AND dp.state           = 'G'
    )
        SET @tiene_permiso = 1

    RETURN @tiene_permiso
END
GO

-- =============================================
-- SP: AUDITORÍA DE SEGURIDAD
-- =============================================

IF OBJECT_ID('sp_AuditoriaSeguridad', 'P') IS NOT NULL
    DROP PROCEDURE sp_AuditoriaSeguridad
GO

CREATE PROCEDURE sp_AuditoriaSeguridad
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'AUDITORIA DE SEGURIDAD - ESBIRROSDB'
    PRINT '====================================='
    PRINT ''

    PRINT 'ROLES DE BASE DE DATOS:'
    SELECT
        name        AS [Rol],
        create_date AS [Fecha Creacion],
        type_desc   AS [Tipo]
    FROM sys.database_principals
    WHERE type = 'R' AND name LIKE 'rol_%'
    ORDER BY name

    PRINT ''

    PRINT 'USUARIOS DE APLICACION:'
    SELECT
        u.name        AS [Usuario],
        r.name        AS [Rol Asignado],
        u.create_date AS [Fecha Creacion]
    FROM sys.database_principals u
    INNER JOIN sys.database_role_members rm ON u.principal_id        = rm.member_principal_id
    INNER JOIN sys.database_principals r   ON rm.role_principal_id  = r.principal_id
    WHERE u.name LIKE 'app_%'
    ORDER BY u.name, r.name

    PRINT ''
    PRINT 'Auditoria completada'
END
GO

-- =============================================
-- VALIDACIÓN FINAL
-- =============================================

PRINT ''
PRINT 'Ejecutando auditoria de seguridad...'
EXEC sp_AuditoriaSeguridad

DECLARE @roles_count    INT = (SELECT COUNT(*) FROM sys.database_principals WHERE type = 'R' AND name LIKE 'rol_%')
DECLARE @usuarios_count INT = (SELECT COUNT(*) FROM sys.database_principals WHERE name LIKE 'app_%')
DECLARE @permisos_count INT = (SELECT COUNT(*) FROM sys.database_permissions
                                WHERE grantee_principal_id IN
                                    (SELECT principal_id FROM sys.database_principals WHERE name LIKE 'rol_%'))

PRINT ''
PRINT 'Roles creados    : ' + CAST(@roles_count    AS VARCHAR)
PRINT 'Usuarios creados : ' + CAST(@usuarios_count AS VARCHAR)
PRINT 'Permisos asignados: ' + CAST(@permisos_count AS VARCHAR)

PRINT ''
PRINT 'BUNDLE C COMPLETADO!'
PRINT '================================================='
PRINT 'Roles   : 8 roles de aplicacion'
PRINT 'Usuarios: 3 usuarios sin login (app_esbirros_*)'
PRINT 'Funcion : fn_ValidarPermisoUsuario'
PRINT 'SP      : sp_AuditoriaSeguridad'
PRINT ''
PRINT 'SIGUIENTE PASO: Ejecutar Bundle_D_Consultas_Basicas.sql'
PRINT '================================================='
GO
