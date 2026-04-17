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
| ESTADOS_PEDIDO | 4 | Pendiente, En Preparación, Listo, Entregado |
| CANALES_VENTA | 2 | Presencial (65%), Delivery (35%) |
| SUCURSALES | 1 | San Telmo (Defensa 742) - Palermo eliminado |
| CATEGORIAS | 5 | Entradas, Pastas, Carnes, Postres, Bebidas |

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

## CARGA MASIVA DE TESTING (10.000+ REGISTROS)

Para pruebas de performance y validación con volumen realista, el proyecto incluye un script automatizado de carga masiva.

### **Script Disponible**
📄 **Archivo:** `B - Scripts SQL/07_CARGA_MASIVA_DATOS.sql`  
📋 **Documentación:** `B - Scripts SQL/README_CARGA_MASIVA.md`

### **Características del Script**
- **Generación automática** de datos realistas (sin archivos CSV)
- **No requiere** herramientas externas
- **Distribución realista** de canales: 65% Presencial, 35% Delivery
- **Datos coherentes** con fechas distribuidas en 6 meses

### **Volumen Generado**

| **Tabla** | **Registros** | **Descripción** |
|-----------|---------------|-----------------|
| CLIENTES | 3,000 | Clientes con DNI, email, teléfono |
| DIRECCIONES_CLIENTES | 4,500 | 1.5 direcciones promedio por cliente |
| PEDIDOS | 10,000 | Pedidos distribuidos en 6 meses |
| PEDIDOS_DETALLE | ~30,000 | 3 items promedio por pedido |
| AUDITORIA_SIMPLE | 500+ | Registros de auditoría adicionales |
| NOTIFICACIONES | 1,000+ | Notificaciones automáticas |

**Total estimado:** ~47,000 registros

### **Ejecución del Script**

```sql
-- Prerequisito: Sistema EsbirrosDB completamente instalado (Bundles A1-R2)
USE EsbirrosDB;
GO

-- Ejecutar el script completo
-- Archivo: 07_CARGA_MASIVA_DATOS.sql
-- Tiempo estimado: 5-10 minutos
```

### **Validación Post-Carga**

```sql
-- Verificar volumen cargado
SELECT 
    'CLIENTES' AS Tabla, COUNT(*) AS Total FROM CLIENTES
UNION ALL
SELECT 'DIRECCIONES_CLIENTES', COUNT(*) FROM DIRECCIONES_CLIENTES
UNION ALL
SELECT 'PEDIDOS', COUNT(*) FROM PEDIDOS
UNION ALL
SELECT 'PEDIDOS_DETALLE', COUNT(*) FROM PEDIDOS_DETALLE
UNION ALL
SELECT 'AUDITORIA_SIMPLE', COUNT(*) FROM AUDITORIA_SIMPLE
UNION ALL
SELECT 'NOTIFICACIONES', COUNT(*) FROM NOTIFICACIONES;
```

**Resultado esperado:**
```
Tabla                    | Total
-------------------------|-------
CLIENTES                 | 3,000
DIRECCIONES_CLIENTES     | 4,500
PEDIDOS                  | 10,000
PEDIDOS_DETALLE          | ~30,000
AUDITORIA_SIMPLE         | 500+
NOTIFICACIONES           | 1,000+
```

---
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
