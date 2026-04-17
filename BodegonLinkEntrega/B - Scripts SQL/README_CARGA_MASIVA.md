# 📊 SCRIPT DE CARGA MASIVA DE DATOS - ESBIRROSDB

## 📋 Descripción

Script `07_CARGA_MASIVA_DATOS.sql` que genera **más de 47,000 registros** de datos de prueba realistas para el sistema EsbirrosDB del Bodegón Los Esbirros de Claudio.

---

## ⚠️ PREREQUISITOS

**IMPORTANTE:** Ejecutar TODOS los bundles antes de este script:

1. ✅ Bundle A1 - Estructura base de datos
2. ✅ Bundle A2 - Índices y datos iniciales
3. ✅ Bundle B1, B2, B3 - Lógica de negocio
4. ✅ Bundle C - Seguridad
5. ✅ Bundle D - Consultas básicas
6. ✅ Bundle E1 - Triggers principales
7. ✅ Bundle E2 - Control avanzado
8. ✅ Bundle R1, R2 - Reportes y dashboard

**Sin los bundles E1 y E2, el script fallará** porque necesita las tablas:
- `AUDITORIA_SIMPLE` (creada por Bundle E1)
- `STOCK_SIMULADO` (creada por Bundle E2)
- `NOTIFICACIONES` (creada por Bundle E2)

---

## 📊 DATOS GENERADOS

### Resumen de Registros

| Tipo de Dato | Cantidad | Descripción |
|--------------|----------|-------------|
| **Clientes** | 3,000 | Clientes únicos con DNI, teléfono, email |
| **Domicilios** | 4,500 | 1-2 domicilios por cliente, algunos con múltiples |
| **Pedidos** | 10,000 | Distribuidos en últimos 180 días |
| **Items de Pedidos** | ~30,000 | Promedio 3 items por pedido (1-6 items) |
| **Auditoría Histórica** | 500 | Registros de auditoría simulados |
| **Notificaciones** | 1,000 | Notificaciones históricas del sistema |
| **TOTAL** | **~49,000** | **Registros totales generados** |

---

## 🎯 DISTRIBUCIÓN DE DATOS

### 1. **Clientes (3,000)**
- **Nombres:** 20 nombres diferentes rotados (Juan, María, Carlos, Ana, etc.)
- **Apellido:** Pérez (todos)
- **Teléfonos:** Formato 11-XXXX-XXXX (únicos)
- **Emails:** cliente{N}@email.com
- **DNI:** Secuencial desde 20000001

### 2. **Domicilios (4,500)**
- **Calles:** 15 calles típicas de San Telmo y alrededores
  - Av. Caseros, Defensa, Bolívar, Piedras, Balcarce, etc.
- **Localidades:** 10 barrios porteños
  - San Telmo, La Boca, Constitución, Monserrat, Puerto Madero, etc.
- **Provincia:** Buenos Aires (todos)
- **Departamentos:** 30% tienen piso/depto
- **Principal:** Primer domicilio de cada cliente es principal

### 3. **Pedidos (10,000)**

#### Distribución Temporal (últimos 180 días):
- **30%** en última semana (0-7 días)
- **30%** en último mes (8-30 días)
- **40%** en últimos 6 meses (31-180 días)

#### Horario Comercial:
- **11:00 AM - 10:00 PM** (hora pico: 13:00-15:00 y 20:00-22:00)

#### Distribución por Canal:
- **65%** Presencial (con mesa asignada)
- **35%** Delivery (con domicilio)

#### Estados de Pedidos:
- **Pedidos antiguos (>7 días):**
  - 95% Cerrados
  - 5% Cancelados

- **Pedidos recientes (1-7 días):**
  - 85% Cerrados
  - 5% Entregados
  - 10% Otros estados

- **Pedidos de hoy:**
  - 40% Cerrados
  - 10% Entregados
  - 10% Listos
  - 15% En Preparación
  - 10% Confirmados
  - 10% Pendientes
  - 5% Cancelados

#### Características:
- **80%** tienen cliente registrado
- **20%** son anónimos
- Mesas: 1-8 (8 mesas disponibles en San Telmo)
- Comensales: 1-6 personas (solo presencial)
- Observaciones: 20% tienen observaciones especiales

### 4. **Items de Pedidos (~30,000)**

#### Distribución:
- Cada pedido tiene **1-6 items** (promedio ~3)
- 22 platos diferentes en el menú
- Distribución realista:
  - **70%** pedidos con 1 item
  - **20%** pedidos con 2 items
  - **10%** pedidos con 3+ items

#### Cantidades por Item:
- **70%** cantidad = 1
- **20%** cantidad = 2
- **10%** cantidad = 3-4

#### Precios:
- Obtiene precio vigente de tabla `PRECIO`
- Fallback a $1,500 si no hay precio definido
- **Subtotal** = cantidad × precio_unitario

### 5. **Stock Actualizado**
- Stock inicial: 100 unidades por plato
- Se descuenta automáticamente según ventas completadas
- Solo pedidos Entregados/Cerrados afectan el stock

### 6. **Auditoría Histórica (500 registros)**
- Simula actividad de auditoría pasada
- Estados registrados: INSERT de pedidos históricos
- Usuario: SYSTEM
- Fecha: coincide con fecha_pedido

### 7. **Notificaciones Históricas (1,000 registros)**
- Tipos: PEDIDO_EN_PREPARACION, PEDIDO_LISTO, PEDIDO_CERRADO, PEDIDO_CANCELADO
- Estados leídos (históricos)
- Prioridades:
  - CRITICA: Pedidos cancelados
  - ALTA: En preparación, Listos
  - NORMAL: Cerrados
- Destinatarios: COCINA, MOZOS, CAJA, GENERAL

---

## ⏱️ TIEMPO DE EJECUCIÓN

- **Estimado:** 5-10 minutos
- **Depende de:**
  - Velocidad del servidor SQL
  - Recursos de CPU/RAM disponibles
  - Índices existentes
  - Triggers activos

**Progreso mostrado cada:**
- 500 clientes
- 1,000 domicilios
- 1,000 pedidos
- 5,000 items

---

## 🚀 CÓMO EJECUTAR

### Opción 1: SQL Server Management Studio (SSMS)
```sql
-- 1. Abrir SSMS
-- 2. Conectar a localhost
-- 3. Abrir archivo: 07_CARGA_MASIVA_DATOS.sql
-- 4. Presionar F5 o botón "Execute"
-- 5. Esperar 5-10 minutos
-- 6. Verificar mensajes de progreso en panel "Messages"
```

### Opción 2: Azure Data Studio
```sql
-- 1. Abrir Azure Data Studio
-- 2. Conectar a localhost
-- 3. File > Open File > 07_CARGA_MASIVA_DATOS.sql
-- 4. Run (Ctrl+Shift+E)
-- 5. Monitorear progreso en Output
```

### Opción 3: Línea de comandos (PowerShell)
```powershell
# Desde la carpeta del script
sqlcmd -S localhost -d EsbirrosDB -i "07_CARGA_MASIVA_DATOS.sql" -o "log_carga_masiva.txt"
```

---

## 📈 ESTADÍSTICAS GENERADAS

Al finalizar, el script muestra:

### 1. Resumen de Registros
```
Clientes registrados   : 3000
Domicilios registrados : 4500
Pedidos generados      : 10000
Items de pedidos       : ~30000
Registros auditoría    : 500
Notificaciones         : 1000
TOTAL REGISTROS        : ~49000
```

### 2. Facturación Total
```
Facturación histórica  : $XXXXXXXX.XX
```

### 3. Distribución por Canal
```
Canal         | Pedidos | Completados | Facturación
--------------|---------|-------------|-------------
Presencial    | 6500    | 6175        | $XXXXXXX
Delivery      | 3500    | 3325        | $XXXXXXX
```

### 4. Distribución por Estado
```
Estado          | Cantidad | Ticket Promedio
----------------|----------|----------------
Cerrado         | 8500     | $3,500
Entregado       | 500      | $3,200
Listo           | 200      | $2,800
En Preparacion  | 300      | $2,500
Confirmado      | 200      | $2,400
Pendiente       | 200      | $2,300
Cancelado       | 100      | $2,100
```

### 5. Top 10 Platos Más Vendidos
```
Plato                    | Categoría | Cantidad | Ingresos
-------------------------|-----------|----------|----------
Bife de Chorizo          | Carnes    | 2500     | $XXXXX
Ñoquis                   | Pastas    | 2300     | $XXXXX
Milanesa Napolitana      | Carnes    | 2200     | $XXXXX
...
```

---

## ✅ VALIDACIÓN POST-CARGA

Después de ejecutar el script, verificar:

```sql
-- 1. Contar registros por tabla
SELECT 'CLIENTE' AS Tabla, COUNT(*) AS Registros FROM CLIENTE
UNION ALL
SELECT 'DOMICILIO', COUNT(*) FROM DOMICILIO
UNION ALL
SELECT 'PEDIDO', COUNT(*) FROM PEDIDO
UNION ALL
SELECT 'DETALLE_PEDIDO', COUNT(*) FROM DETALLE_PEDIDO
UNION ALL
SELECT 'AUDITORIA_SIMPLE', COUNT(*) FROM AUDITORIA_SIMPLE
UNION ALL
SELECT 'NOTIFICACIONES', COUNT(*) FROM NOTIFICACIONES

-- 2. Verificar integridad referencial
SELECT 
    'Pedidos sin items' AS Check,
    COUNT(*) AS Cantidad
FROM PEDIDO p
WHERE NOT EXISTS (SELECT 1 FROM DETALLE_PEDIDO WHERE pedido_id = p.pedido_id)

-- 3. Verificar totales calculados
SELECT 
    'Pedidos con total incorrecto' AS Check,
    COUNT(*) AS Cantidad
FROM PEDIDO p
WHERE p.total != (
    SELECT ISNULL(SUM(subtotal), 0) 
    FROM DETALLE_PEDIDO 
    WHERE pedido_id = p.pedido_id
)

-- 4. Verificar stock
SELECT 
    plato_id,
    stock_disponible,
    stock_minimo,
    CASE 
        WHEN stock_disponible <= stock_minimo THEN 'CRITICO'
        WHEN stock_disponible <= stock_minimo * 2 THEN 'BAJO'
        ELSE 'NORMAL'
    END AS Estado
FROM STOCK_SIMULADO
WHERE stock_disponible < 50
ORDER BY stock_disponible
```

---

## 🔧 TROUBLESHOOTING

### Error: "Invalid object name 'STOCK_SIMULADO'"
**Solución:** Ejecutar Bundle E2 primero
```sql
-- Ejecutar: Bundle_E2_Control_Avanzado.sql
```

### Error: "Invalid object name 'AUDITORIA_SIMPLE'"
**Solución:** Ejecutar Bundle E1 primero
```sql
-- Ejecutar: Bundle_E1_Triggers_Principales.sql
```

### Error: "Timeout expired"
**Solución:** Aumentar timeout de conexión
```sql
-- En SSMS: Tools > Options > Query Execution > SQL Server > General
-- Execution time-out: 600 segundos (10 minutos)
```

### Warning: Script muy lento
**Posibles causas:**
1. Triggers muy complejos (tr_ActualizarTotales ejecutándose 30,000 veces)
2. Índices no optimizados
3. Recursos de servidor limitados

**Soluciones:**
```sql
-- Opción 1: Deshabilitar triggers temporalmente (avanzado)
DISABLE TRIGGER tr_ActualizarTotales ON DETALLE_PEDIDO
-- ... ejecutar carga ...
ENABLE TRIGGER tr_ActualizarTotales ON DETALLE_PEDIDO

-- Opción 2: Ejecutar en lotes más pequeños
-- Modificar los WHILE loops para generar menos registros por iteración
```

---

## 📝 NOTAS IMPORTANTES

1. **Los triggers se ejecutan automáticamente:**
   - `tr_ActualizarTotales` calcula totales de pedidos
   - `tr_AuditoriaPedidos` registra cambios
   - `tr_ValidarStock` descuenta stock
   - Esto puede hacer el proceso más lento pero garantiza integridad

2. **Los datos son realistas pero ficticios:**
   - Todos los clientes se llaman "Nombre Apellido Pérez"
   - Fechas distribuidas lógicamente
   - Montos realistas para un bodegón porteño ($2,000-$5,000 por pedido)

3. **Facturación estimada:**
   - ~10,000 pedidos × $3,500 promedio = **~$35,000,000**
   - Solo pedidos Entregados/Cerrados cuentan para facturación

4. **Stock después de carga:**
   - Platos más vendidos tendrán stock bajo
   - Algunos pueden llegar a stock crítico (<10 unidades)
   - Ideal para probar alertas de stock

---

## 🎯 PROPÓSITO DEL SCRIPT

Este script permite:

✅ **Testing de rendimiento** con volumen realista de datos  
✅ **Validación de triggers** con miles de operaciones  
✅ **Pruebas de reportes** con datos históricos significativos  
✅ **Demostración del sistema** con información creíble  
✅ **Optimización de consultas** identificando cuellos de botella  
✅ **Capacitación de usuarios** con datos de ejemplo  

---

## 📌 PRÓXIMOS PASOS DESPUÉS DE LA CARGA

1. **Generar backup completo:**
   ```sql
   BACKUP DATABASE EsbirrosDB 
   TO DISK = 'C:\Backups\EsbirrosDB_ConDatos.bak'
   WITH FORMAT, COMPRESSION, STATS = 10
   ```

2. **Ejecutar reportes de prueba:**
   ```sql
   EXEC sp_ReporteVentasDiario
   EXEC sp_PlatosMasVendidosDiario @top_cantidad = 10
   EXEC sp_AnalisisVentasMensual
   ```

3. **Verificar vistas de dashboard:**
   ```sql
   SELECT * FROM vw_DashboardEjecutivo
   SELECT * FROM vw_MonitoreoTiempoReal
   ```

4. **Revisar performance de índices:**
   ```sql
   -- Analizar uso de índices
   SELECT * FROM sys.dm_db_index_usage_stats
   WHERE database_id = DB_ID('EsbirrosDB')
   ```

---

**Autor:** Sistema de carga automatizada EsbirrosDB  
**Versión:** 1.0  
**Fecha:** Abril 2026  
**Negocio:** Bodegón Los Esbirros de Claudio  

---
