# CARGA DE DATOS OPERATIVOS - BODEGÓN LOS ESBIRROS DE CLAUDIO

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Carga de Datos Operativos - Bodegón Los Esbirros de Claudio |
| **Proyecto** | Sistema de Gestión de Pedidos EsbirrosDB |
| **Cliente** | Bodegón Los Esbirros de Claudio |
| **Desarrollado por** | SQLeaders S.A. |
| **Versión** | 2.0 |
| **Estado** | Implementado y Funcional |

## **RESUMEN EJECUTIVO**

### **Objetivo del Documento**
Esta guía describe la estrategia de carga de datos para EsbirrosDB. Los datos de referencia y el menú del bodegón están **integrados en Bundle_A2_Indices_Datos.sql**. Para la carga masiva de 10.000+ registros se utiliza BULK INSERT desde archivos CSV generados con IA.

### **Prerrequisitos**
- Sistema EsbirrosDB debe estar completamente instalado (Bundles A1-R2)
- Base de datos EsbirrosDB operativa
- Permisos de escritura en la base de datos

---

## DATOS INCLUIDOS EN BUNDLE_A2

El Bundle A2 carga automáticamente todos los datos de referencia y el menú completo:

### **Datos de Referencia**
| **Tabla** | **Registros** | **Descripción** |
|-----------|---------------|-----------------|
| ESTADO_PEDIDO | 8 | Pendiente, Confirmado, En Preparación, Listo, En Reparto, Entregado, Cerrado, Cancelado |
| CANAL_VENTA | 5 | Mostrador, Delivery, Mesa QR, Teléfono, App Móvil |
| ROL | 7 | Administrador, Gerente, Cajero, Mesero, Cocinero, Delivery, Auditor |
| SUCURSAL | 2 | San Telmo (Defensa 742), Palermo (Thames 1850) |

### **Menú del Bodegón (22 platos)**
| **Categoría** | **Platos** |
|---------------|------------|
| Entradas | Empanadas de Carne (x6), Provoleta a la Plancha, Tabla de Fiambres |
| Pastas | Fideos con Tuco, Ñoquis al Pomodoro, Lasagna Casera, Sorrentinos de Ricota |
| Carnes | Milanesa Napolitana, Bife de Chorizo a la Leña, Asado de Tira, Pollo a la Brasa |
| Guarniciones | Papas Fritas, Ensalada Mixta, Puré de Papa |
| Postres | Flan con Dulce de Leche, Panqueques con Dulce de Leche, Budín de Pan |
| Bebidas | Vino de la Casa (copa), Cerveza Quilmes (500ml), Gaseosa (500ml), Agua Mineral |

### **Precios (vigentes desde fecha de ejecución)**
Precios cargados con `vigencia_desde = CAST(GETDATE() AS DATE)` y `vigencia_hasta = NULL` (sin vencimiento).  
Rango: $600 (Agua) — $7800 (Bife de Chorizo a la Leña).

### **Personal inicial**
- Usuario administrador: `claudio.admin`

---

## CARGA MASIVA — BULK INSERT (10.000+ REGISTROS)

Para cumplir con el requisito académico de 10.000+ registros, se debe generar y cargar un volumen mayor de datos históricos. Esto requiere archivos CSV y un script BULK INSERT.

### **Tablas candidatas para carga masiva**

| **Tabla** | **Registros sugeridos** | **Justificación** |
|-----------|------------------------|-------------------|
| CLIENTE | 500 | Clientes únicos con historial |
| DOMICILIO | 600 | Domicilios de clientes (delivery) |
| EMPLEADO | 20 | Personal de ambas sucursales |
| MESA | 60 | 30 mesas por sucursal |
| PEDIDO | 5.000 | Pedidos históricos 2026 |
| DETALLE_PEDIDO | 15.000 | 3 ítems promedio por pedido |

### **Estrategia de generación con IA**

Los archivos CSV deben generarse con IA (ChatGPT, Copilot, etc.) o Python.  
Ver documento: **09 - Generacion de Datos con IA.md** (pendiente de creación).

**Prompt de referencia para IA:**
```
Generá un archivo CSV con 5000 registros de pedidos para un restaurante bodegón porteño 
argentino llamado "Los Esbirros de Claudio" con dos sucursales (sucursal_id 1 y 2).
Columnas: pedido_id, sucursal_id, canal_id (1=Mesa, 2=Mostrador, 3=Delivery), 
mesa_id (NULL si delivery/mostrador), cliente_id (NULL si mesa/mostrador), 
estado_id (entre 1 y 8), tomado_por_empleado_id (entre 1 y 20), 
fecha_pedido (distribuido en enero-abril 2026), comensales (1-8), total (entre 800 y 15000).
Formato CSV sin encabezado, separado por coma.
```

### **Script BULK INSERT de referencia**

```sql
-- Prerequisito: Deshabilitar índices no-clustered ANTES del bulk insert
-- (ver mejorespracticas.md §3)

USE EsbirrosDB;
GO

-- 1. Deshabilitar índices no-clustered
ALTER INDEX IX_PEDIDO_fecha_pedido ON PEDIDO DISABLE;
ALTER INDEX IX_PEDIDO_estado_id    ON PEDIDO DISABLE;
ALTER INDEX IX_PEDIDO_canal_id     ON PEDIDO DISABLE;

-- 2. Cargar clientes
BULK INSERT CLIENTE
FROM 'C:\BulkData\clientes_esbirros.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    FIRSTROW        = 1,
    BATCHSIZE       = 1000,
    TABLOCK
);

-- 3. Cargar pedidos
BULK INSERT PEDIDO
FROM 'C:\BulkData\pedidos_esbirros.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    FIRSTROW        = 1,
    BATCHSIZE       = 1000,
    TABLOCK
);

-- 4. Cargar detalle de pedidos
BULK INSERT DETALLE_PEDIDO
FROM 'C:\BulkData\detalle_pedidos_esbirros.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    FIRSTROW        = 1,
    BATCHSIZE       = 1000,
    TABLOCK
);

-- 5. Reconstruir índices después del bulk insert
ALTER INDEX IX_PEDIDO_fecha_pedido ON PEDIDO REBUILD;
ALTER INDEX IX_PEDIDO_estado_id    ON PEDIDO REBUILD;
ALTER INDEX IX_PEDIDO_canal_id     ON PEDIDO REBUILD;

-- 6. Actualizar estadísticas
UPDATE STATISTICS PEDIDO;
UPDATE STATISTICS DETALLE_PEDIDO;
UPDATE STATISTICS CLIENTE;

-- 7. Verificar carga
SELECT 'PEDIDO'         AS tabla, COUNT(*) AS registros FROM PEDIDO
UNION ALL
SELECT 'DETALLE_PEDIDO' AS tabla, COUNT(*) AS registros FROM DETALLE_PEDIDO
UNION ALL
SELECT 'CLIENTE'        AS tabla, COUNT(*) AS registros FROM CLIENTE;
-- Verificar que superan los 10.000 registros en total
```

---

## DATOS DE DEMOSTRACIÓN (PEDIDOS DE EJEMPLO)

Para una demostración rápida sin bulk insert, se pueden insertar pedidos manuales:

```sql
USE EsbirrosDB;
GO

-- Pedido de mesa (salón)
DECLARE @pedido_id INT, @msg NVARCHAR(500)
EXEC sp_CrearPedido
    @canal_id                 = 1,   -- Mesa
    @mesa_id                  = 1,
    @cliente_id               = NULL,
    @tomado_por_empleado_id   = 1,
    @cant_comensales          = 4,
    @pedido_id                = @pedido_id OUTPUT,
    @mensaje                  = @msg OUTPUT
PRINT 'Pedido creado: ' + CAST(@pedido_id AS VARCHAR) + ' - ' + @msg

-- Agregar ítems
DECLARE @det_id INT
EXEC sp_AgregarItemPedido
    @pedido_id  = @pedido_id,
    @plato_id   = 1,   -- Empanadas de Carne
    @cantidad   = 2,
    @detalle_id = @det_id OUTPUT,
    @mensaje    = @msg OUTPUT

EXEC sp_AgregarItemPedido
    @pedido_id  = @pedido_id,
    @plato_id   = 9,   -- Milanesa Napolitana
    @cantidad   = 2,
    @detalle_id = @det_id OUTPUT,
    @mensaje    = @msg OUTPUT

-- Verificar
SELECT * FROM vw_DashboardEjecutivo
SELECT * FROM vw_MonitoreoTiempoReal
```

---

## VERIFICACIÓN FINAL

```sql
USE EsbirrosDB;

-- Resumen de datos cargados
SELECT 'SUCURSAL'       AS tabla, COUNT(*) AS registros FROM SUCURSAL
UNION ALL SELECT 'PLATO',          COUNT(*) FROM PLATO
UNION ALL SELECT 'PRECIO',         COUNT(*) FROM PRECIO
UNION ALL SELECT 'ROL',            COUNT(*) FROM ROL
UNION ALL SELECT 'ESTADO_PEDIDO',  COUNT(*) FROM ESTADO_PEDIDO
UNION ALL SELECT 'CANAL_VENTA',    COUNT(*) FROM CANAL_VENTA
UNION ALL SELECT 'EMPLEADO',       COUNT(*) FROM EMPLEADO
UNION ALL SELECT 'MESA',           COUNT(*) FROM MESA
UNION ALL SELECT 'PEDIDO',         COUNT(*) FROM PEDIDO
UNION ALL SELECT 'DETALLE_PEDIDO', COUNT(*) FROM DETALLE_PEDIDO
ORDER BY tabla;
```

---

**Documento generado por SQLeaders S.A. — 2026**  
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**
