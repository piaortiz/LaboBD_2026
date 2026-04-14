-- =============================================
-- BUNDLE B1 - PEDIDOS CORE
-- EsbirrosDB - Sistema de Gestión de Bodegón Porteño
-- Negocio: Bodegón Los Esbirros de Claudio
-- Descripción: Stored Procedure para creación de pedidos
-- Proyecto Educativo ISTEA - Uso académico exclusivo
-- PROHIBIDA LA COMERCIALIZACIÓN
-- =============================================

USE EsbirrosDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT 'INICIANDO BUNDLE B1 - PEDIDOS CORE'
PRINT '===================================='
PRINT 'Sistema: EsbirrosDB - Bodegon Los Esbirros de Claudio'
PRINT ''

-- =============================================
-- SP: CREAR PEDIDO
-- =============================================

PRINT 'Creando SP: sp_CrearPedido...'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CrearPedido]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_CrearPedido]
GO

CREATE PROCEDURE [dbo].[sp_CrearPedido]
    @canal_id                INT,
    @mesa_id                 INT = NULL,
    @cliente_id              INT = NULL,
    @domicilio_id            INT = NULL,
    @cant_comensales         INT = NULL,
    @tomado_por_empleado_id  INT,
    @pedido_id               INT           OUTPUT,
    @mensaje                 NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION

        -- Variables locales
        DECLARE @estado_pendiente_id INT
        DECLARE @empleado_activo     INT = 0
        DECLARE @sucursal_empleado   INT
        DECLARE @sucursal_mesa       INT

        -- Inicializar salidas
        SET @pedido_id = 0
        SET @mensaje   = ''

        -- 1. VALIDAR CANAL DE VENTA
        IF NOT EXISTS (SELECT 1 FROM CANAL_VENTA WHERE canal_id = @canal_id)
        BEGIN
            SET @mensaje = 'Error: Canal de venta no válido'
            ROLLBACK TRANSACTION
            RETURN -1
        END

        -- 2. OBTENER ESTADO "PENDIENTE"
        SELECT @estado_pendiente_id = estado_id
        FROM ESTADO_PEDIDO
        WHERE nombre = 'Pendiente'

        IF @estado_pendiente_id IS NULL
        BEGIN
            SET @mensaje = 'Error: No se encontró el estado "Pendiente"'
            ROLLBACK TRANSACTION
            RETURN -2
        END

        -- 3. VALIDAR EMPLEADO
        SELECT
            @empleado_activo   = COUNT(*),
            @sucursal_empleado = MAX(sucursal_id)
        FROM EMPLEADO
        WHERE empleado_id = @tomado_por_empleado_id
          AND activo = 1

        IF @empleado_activo = 0
        BEGIN
            SET @mensaje = 'Error: Empleado no existe o está inactivo'
            ROLLBACK TRANSACTION
            RETURN -3
        END

        -- 4. VALIDACIONES POR CANAL (mesa / delivery)
        IF @mesa_id IS NOT NULL
        BEGIN
            -- Verificar que la mesa exista y esté activa
            IF NOT EXISTS (SELECT 1 FROM MESA WHERE mesa_id = @mesa_id AND activa = 1)
            BEGIN
                SET @mensaje = 'Error: Mesa no existe o está inactiva'
                ROLLBACK TRANSACTION
                RETURN -4
            END

            -- Verificar que empleado y mesa pertenezcan a la misma sucursal
            SELECT @sucursal_mesa = sucursal_id FROM MESA WHERE mesa_id = @mesa_id

            IF @sucursal_empleado != @sucursal_mesa
            BEGIN
                SET @mensaje = 'Error: El empleado no pertenece a la sucursal de la mesa'
                ROLLBACK TRANSACTION
                RETURN -5
            END
        END

        -- 5. CREAR EL PEDIDO
        INSERT INTO PEDIDO (
            fecha_pedido,
            canal_id,
            estado_id,
            mesa_id,
            cliente_id,
            domicilio_id,
            cant_comensales,
            tomado_por_empleado_id
        )
        VALUES (
            GETDATE(),
            @canal_id,
            @estado_pendiente_id,
            @mesa_id,
            @cliente_id,
            @domicilio_id,
            @cant_comensales,
            @tomado_por_empleado_id
        )

        SET @pedido_id = SCOPE_IDENTITY()
        SET @mensaje   = 'Pedido creado exitosamente. pedido_id=' + CAST(@pedido_id AS VARCHAR)

        COMMIT TRANSACTION
        RETURN 0

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        SET @mensaje = 'Error inesperado: ' + ERROR_MESSAGE()
        RETURN -99
    END CATCH
END
GO

-- =============================================
-- VALIDACIÓN
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CrearPedido]') AND type in (N'P', N'PC'))
    PRINT 'sp_CrearPedido: Creado correctamente'
ELSE
    PRINT 'sp_CrearPedido: ERROR'

PRINT ''
PRINT 'BUNDLE B1 COMPLETADO!'
PRINT '======================================='
PRINT 'Funciones disponibles:'
PRINT '   sp_CrearPedido - Crea pedidos con validaciones completas'
PRINT ''
PRINT 'Ejemplo de uso:'
PRINT '   DECLARE @pid INT, @msg NVARCHAR(500)'
PRINT '   EXEC sp_CrearPedido @canal_id=3, @mesa_id=1, @tomado_por_empleado_id=1,'
PRINT '        @pedido_id=@pid OUTPUT, @mensaje=@msg OUTPUT'
PRINT ''
PRINT 'SIGUIENTE PASO: Ejecutar Bundle_B2_Items_Calculos.sql'
PRINT '================================================='
GO
