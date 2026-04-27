# CARGA DE DATOS OPERATIVOS - BODEGÓN LOS ESBIRROS DE CLAUDIO

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Carga de Datos Operativos - Bodegón Los Esbirros de Claudio |
| **Proyecto** | Sistema de Gestión de Pedidos EsbirrosDB |
| **Cliente** | Bodegón Los Esbirros de Claudio |
| **Desarrollado por** | SQLeaders S.A. |
| **Versión** | 1.0 |
| **Estado** | Implementado y Funcional |
| **Instituto** | ISTEA |
| **Materia** | Laboratorio de Administración de Bases de Datos |
| **Profesor** | Carlos Alejandro Caraccio |

## **RESUMEN EJECUTIVO**

### **Objetivo del Documento**
Esta guía describe la estrategia de carga de datos para EsbirrosDB. Los datos de referencia y el menú del bodegón están **integrados en Bundle_A2_Indices_Datos.sql**. Para la carga masiva de 10.000+ registros se utiliza el script `Bundle_F_Carga_Masiva.sql`, que genera datos realistas mediante T-SQL sin necesidad de archivos externos.

### **Prerrequisitos**
- Sistema EsbirrosDB completamente instalado (Bundles A1 → R2)
- Base de datos EsbirrosDB operativa
- Permisos de escritura en la base de datos

---

## DATOS INCLUIDOS EN BUNDLE_A2

El Bundle A2 carga automáticamente todos los datos de referencia y el menú completo:

### **Datos de Referencia**

| **Tabla**         | **Registros** | **Descripción**                                    |
|-------------------|---------------|----------------------------------------------------|
| ESTADOS_PEDIDOS   | 8             | Pendiente, Confirmado, En Preparación, Listo, En Reparto, Entregado, Cerrado, Cancelado |
| CANALES_VENTAS    | 4             | Mostrador, Delivery, MESAS QR, Telefono            |
| SUCURSALES        | 1             | Los Esbirros de Claudio — San Telmo (Defensa 742)  |
| ROLES             | 7             | Administrador, Gerente, Mozo, Cajero, Cocinero, Repartidor, Hostess |
| MESAS             | 8             | Mesas 1 a 8 con QR tokens únicos                   |
| EMPLEADOS         | 19            | 1 Admin + 1 Gerente + 6 Mozos + 2 Cajeros + 4 Cocineros + 3 Repartidores + 2 Hostess |

### **Flujo de estados de pedido**

```
Pendiente(1) → Confirmado(2) → En Preparación(3) → Listo(4) → En Reparto(5) → Entregado(6) → Cerrado(7)
Cancelado(orden=99) — accesible desde cualquier estado activo
```

### **Menú del Bodegón (22 platos)**

| **Categoría**      | **Platos**                                                                 |
|--------------------|----------------------------------------------------------------------------|
| Entradas           | Empanadas de Carne (x6), Provoleta a la Plancha, Tabla de Fiambres         |
| Pastas             | Fideos con Tuco, Ñoquis al Pomodoro, Lasagna Casera, Sorrentinos de Ricota |
| Carnes a la Leña   | Milanesa Napolitana, Bife de Chorizo a la Leña, Asado de Tira, Pollo a la Brasa |
| Guarniciones       | Papas Fritas, Ensalada Mixta, Puré de Papa                                 |
| Postres            | Flan con Dulce de Leche, Panqueques con Dulce de Leche, Budín de Pan       |
| Bebidas            | Vino Tinto de la Casa (porrón), Vino de la Casa (copa), Cerveza Quilmes (500ml), Gaseosa (500ml), Agua Mineral |

### **Precios (vigentes desde fecha de ejecución)**
Precios cargados en tabla `PRECIOS`, columna `monto`, con `vigencia_desde = CAST(GETDATE() AS DATE)` y `vigencia_hasta = NULL` (sin vencimiento).
Rango: $1.200 (Agua Mineral) — $7.800 (Bife de Chorizo a la Leña).

### **Personal inicial**
- Usuario administrador: `claudio.admin`
- Total: 19 empleados distribuidos por rol

---

## CARGA MASIVA DE TESTING (10.000+ REGISTROS)

Para pruebas de performance y validación con volumen realista, el proyecto incluye un script automatizado de carga masiva con datos generados mediante T-SQL.

### **Script Disponible**

📄 **Archivo:** `B - Scripts SQL/07_Carga_Masiva_Datos/Bundle_F_Carga_Masiva.sql`

### **Características del Script**
- **Generación automática** de datos realistas mediante T-SQL (sin archivos CSV externos)
- **No requiere** herramientas externas (bcp, BULK INSERT, OPENROWSET)
- **Distribución realista** de canales y estados
- **Datos coherentes** (clientes con domicilios, pedidos con ítems, precios vigentes)

### **Volumen Generado y Validado**

| **Tabla**           | **Registros** | **Descripción**                                         |
|---------------------|---------------|---------------------------------------------------------|
| CLIENTES            | ~3.000        | Clientes con nombre, teléfono, email, DNI               |
| DOMICILIOS          | ~3.000        | Un domicilio por cliente delivery (con tipo_domicilio)  |
| PEDIDOS             | 10.000        | Distribuidos entre estados Cerrado, Entregado, Cancelado|
| DETALLES_PEDIDOS    | ~30.000       | ~3 ítems promedio por pedido                            |
| AUDITORIAS_SIMPLES  | ~50.000       | Generados automáticamente por triggers durante la carga |

> **Nota:** `NOTIFICACIONES` queda en 0 después de la carga masiva, ya que los INSERTs directos en PEDIDOS no pasan por los Stored Procedures que disparan notificaciones. Esto es comportamiento esperado para una carga histórica.

### **Ejecución del Script**

```powershell
sqlcmd -S localhost -E -i "B - Scripts SQL\07_Carga_Masiva_Datos\Bundle_F_Carga_Masiva.sql"
```

**Tiempo estimado:** 3-7 minutos dependiendo del hardware.

### **Validación Post-Carga**

```sql
USE EsbirrosDB;
GO

SELECT 'CLIENTES'            AS tabla, COUNT(*) AS registros FROM CLIENTES
UNION ALL SELECT 'DOMICILIOS',         COUNT(*) FROM DOMICILIOS
UNION ALL SELECT 'PEDIDOS',            COUNT(*) FROM PEDIDOS
UNION ALL SELECT 'DETALLES_PEDIDOS',   COUNT(*) FROM DETALLES_PEDIDOS
UNION ALL SELECT 'AUDITORIAS_SIMPLES', COUNT(*) FROM AUDITORIAS_SIMPLES
UNION ALL SELECT 'NOTIFICACIONES',     COUNT(*) FROM NOTIFICACIONES
ORDER BY tabla;
```

**Resultado esperado:**

| tabla               | registros            |
|---------------------|----------------------|
| AUDITORIAS_SIMPLES  | ~50.000              |
| CLIENTES            | ~3.000               |
| DETALLES_PEDIDOS    | ~30.000              |
| DOMICILIOS          | ~3.000               |
| NOTIFICACIONES      | 0 (correcto: carga histórica sin SPs) |
| PEDIDOS             | 10.000               |

---

## DATOS DE DEMOSTRACIÓN (PEDIDOS DE EJEMPLO)

Para una demostración rápida sin carga masiva, se pueden crear pedidos de prueba directamente con los Stored Procedures:

```sql
USE EsbirrosDB;
GO

DECLARE @pedido_id INT, @msg NVARCHAR(500), @det_id INT

-- Pedido de mesa (canal MESAS QR)
EXEC sp_CrearPedido
    @canal_id               = 3,   -- MESAS QR
    @mesa_id                = 1,
    @cant_comensales        = 4,
    @tomado_por_empleado_id = 3,
    @pedido_id              = @pedido_id OUTPUT,
    @mensaje                = @msg OUTPUT

PRINT 'Pedido creado: ' + CAST(@pedido_id AS VARCHAR) + ' — ' + @msg

-- Agregar ítems
EXEC sp_AgregarItemPedido
    @pedido_id  = @pedido_id,
    @plato_id   = 1,   -- Empanadas de Carne
    @cantidad   = 2,
    @detalle_id = @det_id OUTPUT,
    @mensaje    = @msg OUTPUT

EXEC sp_AgregarItemPedido
    @pedido_id  = @pedido_id,
    @plato_id   = 10,  -- Bife de Chorizo a la Leña
    @cantidad   = 1,
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
GO

SELECT 'SUCURSALES'        AS tabla, COUNT(*) AS registros FROM SUCURSALES
UNION ALL SELECT 'CANALES_VENTAS',   COUNT(*) FROM CANALES_VENTAS
UNION ALL SELECT 'ESTADOS_PEDIDOS',  COUNT(*) FROM ESTADOS_PEDIDOS
UNION ALL SELECT 'ROLES',            COUNT(*) FROM ROLES
UNION ALL SELECT 'MESAS',            COUNT(*) FROM MESAS
UNION ALL SELECT 'EMPLEADOS',        COUNT(*) FROM EMPLEADOS
UNION ALL SELECT 'PLATOS',           COUNT(*) FROM PLATOS
UNION ALL SELECT 'PRECIOS',          COUNT(*) FROM PRECIOS
UNION ALL SELECT 'CLIENTES',         COUNT(*) FROM CLIENTES
UNION ALL SELECT 'DOMICILIOS',       COUNT(*) FROM DOMICILIOS
UNION ALL SELECT 'PEDIDOS',          COUNT(*) FROM PEDIDOS
UNION ALL SELECT 'DETALLES_PEDIDOS', COUNT(*) FROM DETALLES_PEDIDOS
ORDER BY tabla;
```

**Valores esperados (sin carga masiva):**

| Tabla            | Registros |
|------------------|-----------|
| CANALES_VENTAS   | 4         |
| ESTADOS_PEDIDOS  | 8         |
| EMPLEADOS        | 19        |
| MESAS            | 8         |
| PLATOS           | 22        |
| PRECIOS          | 22        |
| ROLES            | 7         |
| SUCURSALES       | 1         |

---

**Documento generado por SQLeaders S.A. — 2026**
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**