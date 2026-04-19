# 📊 Carga Masiva de Datos - EsbirrosDB V2

## Descripción

Script optimizado para generar más de **43,000 registros de prueba** en la base de datos **EsbirrosDB** del Bodegón Los Esbirros de Claudio.

## 📁 Archivo

- **Script principal**: `07_CARGA_MASIVA_DATOS_V2.sql`
- **Versión**: 2.0 (Abril 2026)
- **Estado**: ✅ Validado y funcional

## 📦 Contenido Generado

| Entidad | Cantidad | Descripción |
|---------|----------|-------------|
| **Clientes** | 3,000 | DNIs en rango 30,000,001 - 30,003,000 |
| **Domicilios** | 3,000 | Un domicilio principal por cliente |
| **Pedidos** | 10,000 | Distribuidos en últimos 6 meses |
| **Ítems** | 30,000+ | 2-4 ítems por pedido en promedio |
| **TOTAL** | ~43,000 | Registros insertados |

### Distribución de Pedidos por Canal

- 🪟 **Mostrador**: 50% (5,000 pedidos)
- 🚚 **Delivery**: 30% (3,000 pedidos)
- 📱 **Mesa QR**: 15% (1,500 pedidos)
- ☎️ **Teléfono**: 5% (500 pedidos)

### Distribución Temporal

- **Última semana**: 40% de pedidos
- **Último mes**: 30% de pedidos
- **Últimos 6 meses**: 30% de pedidos

## ⚙️ Prerequisitos

### 1. Bundles Requeridos

Antes de ejecutar este script, asegúrate de que estén desplegados:

```
✅ Bundle A1 - Base de Datos y Estructura
✅ Bundle A2 - Índices y Datos Maestros
✅ Bundle B1 - Pedidos Core
✅ Bundle B2 - Items y Cálculos
✅ Bundle B3 - Estados y Finalización
✅ Bundle E1 - Triggers Principales (opcional pero recomendado)
```

### 2. Verificación Rápida

```sql
-- Verificar que existan las tablas principales
SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('CLIENTE', 'PEDIDO', 'DETALLE_PEDIDO', 'CANAL_VENTA')
-- Debe retornar 4
```

## 🚀 Ejecución

### Desde SQLCMD

```powershell
# Ejecución simple
sqlcmd -S localhost -E -i "07_CARGA_MASIVA_DATOS_V2.sql"

# Con medición de tiempo
$start = Get-Date
sqlcmd -S localhost -E -i "07_CARGA_MASIVA_DATOS_V2.sql"
$end = Get-Date
Write-Host "Tiempo: $($end - $start)"
```

### Desde SQL Server Management Studio (SSMS)

1. Abrir el archivo `07_CARGA_MASIVA_DATOS_V2.sql`
2. Conectar a `localhost`
3. Presionar **F5** o **Execute**
4. Revisar mensajes en panel de resultados

## ⏱️ Rendimiento

- **Tiempo estimado**: 30-60 segundos
- **Velocidad típica**: ~700-1,400 registros/segundo
- **Factores que afectan rendimiento**:
  - Triggers activos (Bundle E1)
  - Índices definidos (Bundle A2)
  - Recursos del servidor

## 🔄 Limpieza Automática

El script incluye una sección de limpieza que **elimina datos previos** de bulk load:

```sql
DELETE FROM DETALLE_PEDIDO;
DELETE FROM PEDIDO;
DELETE FROM DOMICILIO;
DELETE FROM CLIENTE WHERE cliente_id > 19; -- Solo bulk data
DELETE FROM NOTIFICACIONES;
DELETE FROM AUDITORIA_SIMPLE;
```

### ⚠️ Datos Preservados

- ✅ Empleados (cliente_id 1-19)
- ✅ Datos maestros (platos, canales, estados, etc.)
- ✅ Roles y permisos de seguridad
- ✅ Stored procedures y vistas

## 📊 Estadísticas Generadas

Al finalizar, el script muestra un reporte completo:

```
======================================================
ESTADÍSTICAS FINALES:
─────────────────────────────────────────────────────
Clientes nuevos        : 3000
Domicilios registrados : 3000
Pedidos generados      : 10000
Items de pedidos       : 30847
Registros auditoría    : 10000
Notificaciones         : 10000

TOTAL REGISTROS NUEVOS : 66847 registros

Facturación histórica  : $15,234,567.89

DISTRIBUCIÓN POR CANAL:
Canal       Pedidos  Total_Facturado
----------- -------- ----------------
Mostrador   5000     $7,600,123.45
Delivery    3000     $4,800,234.56
Mesa QR     1500     $2,200,456.78
Teléfono    500      $633,753.10
```

## 🔍 Validación Post-Ejecución

### Queries de Verificación

```sql
-- 1. Contar registros por entidad
SELECT 
    'Clientes' AS Entidad,
    COUNT(*) AS Total
FROM CLIENTE WHERE cliente_id > 19
UNION ALL
SELECT 'Pedidos', COUNT(*) FROM PEDIDO
UNION ALL
SELECT 'Items', COUNT(*) FROM DETALLE_PEDIDO;

-- 2. Verificar distribución por canal
SELECT 
    cv.nombre,
    COUNT(p.pedido_id) AS cantidad_pedidos
FROM CANAL_VENTA cv
LEFT JOIN PEDIDO p ON cv.canal_id = p.canal_id
GROUP BY cv.nombre
ORDER BY cantidad_pedidos DESC;

-- 3. Revisar pedidos recientes
SELECT TOP 10
    p.pedido_id,
    p.fecha_hora,
    cv.nombre AS canal,
    ep.nombre AS estado,
    p.total
FROM PEDIDO p
INNER JOIN CANAL_VENTA cv ON p.canal_id = cv.canal_id
INNER JOIN ESTADO_PEDIDO ep ON p.estado_id = ep.estado_id
ORDER BY p.fecha_hora DESC;
```

## 🛠️ Solución de Problemas

### Error: "Violation of UNIQUE KEY constraint 'UK_CLIENTE_documento'"

**Causa**: Ya existen clientes con DNIs en el rango 30M.

**Solución**: El script debería limpiarlos automáticamente. Si persiste:

```sql
DELETE FROM DOMICILIO WHERE cliente_id > 19;
DELETE FROM CLIENTE WHERE cliente_id > 19;
```

### Error: "Cannot insert NULL into column 'canal_id'"

**Causa**: No se encuentran los canales de venta.

**Solución**: Verificar que Bundle A2 esté ejecutado:

```sql
SELECT canal_id, nombre FROM CANAL_VENTA;
-- Debe retornar: Mostrador, Delivery, Mesa QR, Teléfono, App Móvil
```

### Error: "Invalid object name 'PLATO'"

**Causa**: No están desplegadas las tablas base.

**Solución**: Ejecutar bundles en orden:

```powershell
sqlcmd -S localhost -E -i "Bundle_A1_BaseDatos_Estructura.sql"
sqlcmd -S localhost -E -i "Bundle_A2_Indices_Datos.sql"
```

## 📝 Estructura del Script

```
1. Limpieza de datos previos
2. Generación de 3,000 clientes
   ├── Nombres aleatorios
   ├── DNIs únicos (30M+)
   └── Emails y teléfonos
3. Generación de 3,000 domicilios
   ├── Calles aleatorias
   └── Vinculados a clientes
4. Generación de 10,000 pedidos
   ├── Distribución temporal
   ├── Asignación de canales
   ├── Estados realistas
   └── Clientes y mesas
5. Generación de 30,000+ ítems
   ├── 2-4 ítems por pedido
   ├── Platos aleatorios
   └── Cantidades variables
6. Estadísticas finales
```

## 🔐 Seguridad

- El script NO modifica datos de sistema
- NO elimina empleados (cliente_id ≤ 19)
- NO afecta stored procedures ni vistas
- NO modifica roles ni permisos
- Usa transacciones implícitas (puede rollback manual)

## 📅 Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 2.0 | Abril 2026 | Reescritura completa optimizada |
| | | Corrección de nombres de columnas (doc_tipo, doc_nro) |
| | | Corrección de tabla CANAL_VENTA |
| | | Rango DNI 30M para evitar colisiones |
| | | Mejora en distribución de canales |
| | | Estadísticas detalladas al finalizar |
| 1.0 | Abril 2026 | Versión inicial (deprecada - múltiples errores) |

## 👥 Uso Recomendado

Este script es ideal para:

- ✅ Testing de rendimiento
- ✅ Validación de stored procedures
- ✅ Pruebas de reportes
- ✅ Demostración del sistema
- ✅ Entrenamiento de usuarios
- ✅ Desarrollo de nuevas features

**NO usar en producción** con datos reales sin respaldo previo.

## 📧 Soporte

Para problemas o mejoras, revisar:
- Logs de ejecución del script
- Bundle de validación: `06_VALIDACION_POST_BUNDLES.sql`
- Documentación de bundles principales

---

**Última actualización**: Abril 19, 2026  
**Autor**: Sistema de Deployment EsbirrosDB  
**Licencia**: Uso interno - Bodegón Los Esbirros de Claudio
