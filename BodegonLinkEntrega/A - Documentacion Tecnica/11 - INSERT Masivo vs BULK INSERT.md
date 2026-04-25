# INSERT MASIVO T-SQL vs BULK INSERT CON CSV — ANÁLISIS COMPARATIVO

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**     | **Descripción**                                      |
|---------------|------------------------------------------------------|
| **Documento** | Comparativa: INSERT Masivo T-SQL vs BULK INSERT CSV  |
| **Proyecto**  | Sistema de Gestión de Pedidos EsbirrosDB             |
| **Cliente**   | Bodegón Los Esbirros de Claudio                      |
| **Instituto** | ISTEA                                                |
| **Versión**   | 1.0                                                  |
| **Fecha**     | Abril 2026                                           |
| **Estado**    | Documentación Técnica de Referencia                  |

---

## **RESUMEN EJECUTIVO**

Existen dos enfoques principales para insertar grandes volúmenes de datos en SQL Server. Este documento analiza ambos, explicando cuándo usar cada uno, sus ventajas, limitaciones y cómo se aplican en el proyecto EsbirrosDB.

---

## **1. INSERT MASIVO CON T-SQL (LOOP / WHILE)**

### ¿Qué es?

Es la técnica de generar e insertar datos **directamente desde código T-SQL**, sin necesidad de un archivo externo. Los datos se construyen mediante lógica de programación: variables, funciones, bucles y expresiones aleatorias dentro del motor de SQL Server.

### ¿Cómo funciona?

```sql
DECLARE @i INT = 1

WHILE @i <= 10000
BEGIN
    INSERT INTO PEDIDOS (canal_id, cliente_id, empleado_id, estado_id, fecha_pedido)
    VALUES (
        (ABS(CHECKSUM(NEWID())) % 4) + 1,          -- canal aleatorio 1-4
        (ABS(CHECKSUM(NEWID())) % 3000) + 20,       -- cliente aleatorio
        (ABS(CHECKSUM(NEWID())) % 19)  + 1,         -- empleado aleatorio
        7,                                           -- estado = Cerrado
        DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365), GETDATE())  -- fecha aleatoria último año
    )
    SET @i = @i + 1
END
```

El script `Bundle_F_Carga_Masiva.sql` del proyecto utiliza **exactamente esta técnica**.

### ✅ Ventajas

| Ventaja | Detalle |
|--------|---------|
| **Sin archivos externos** | No requiere CSV, Excel ni ningún archivo fuera del motor |
| **Datos coherentes** | La lógica T-SQL puede respetar claves foráneas, rangos válidos y relaciones entre tablas |
| **Portabilidad total** | El script funciona en cualquier instancia SQL Server sin configuraciones adicionales |
| **Datos dinámicos** | Usa `NEWID()`, `CHECKSUM()`, `DATEADD()`, `GETDATE()` para variedad realista |
| **Control granular** | Se puede ajustar la distribución estadística (ej: 50% canal Mostrador, 30% Delivery) |
| **Sin permisos especiales** | No requiere permisos de administrador de servidor (`ADMINISTER BULK OPERATIONS`) |

### ❌ Limitaciones

| Limitación | Detalle |
|-----------|---------|
| **Performance** | Un `WHILE` row-by-row es más lento que BULK INSERT para volúmenes muy grandes (>1M filas) |
| **No hay archivo entregable** | Los datos existen solo dentro de la base de datos; no hay un archivo para compartir |
| **Datos artificiales** | Los datos son pseudoaleatorios, no provienen de fuentes reales del negocio |

---

## **2. BULK INSERT CON ARCHIVO CSV**

### ¿Qué es?

`BULK INSERT` es un comando T-SQL específico que **carga datos desde un archivo externo** (CSV, TXT u otros formatos delimitados) directamente a una tabla de SQL Server. Es la forma más rápida de cargar grandes volúmenes de datos reales o pre-generados.

### ¿Cómo funciona?

El proceso tiene **dos etapas separadas**:

#### Etapa 1 — Preparar el archivo CSV

```csv
canal_id,cliente_id,empleado_id,estado_id,fecha_pedido
1,25,3,7,2025-03-15
2,87,11,7,2025-06-22
3,142,5,7,2025-09-01
...
```

#### Etapa 2 — Ejecutar el comando BULK INSERT

```sql
BULK INSERT PEDIDOS
FROM 'C:\Datos\pedidos_10000.csv'
WITH (
    FIELDTERMINATOR = ',',      -- separador de columnas
    ROWTERMINATOR   = '\n',     -- separador de filas
    FIRSTROW        = 2,        -- saltar encabezado
    TABLOCK                     -- bloqueo de tabla para mayor velocidad
);
```

### ✅ Ventajas

| Ventaja | Detalle |
|--------|---------|
| **Altísima performance** | Carga mínimamente logueada (minimal logging); hasta 10x más rápido para millones de filas |
| **Archivo entregable** | El CSV es un artefacto concreto, auditable y compartible |
| **Datos reales** | Ideal para migrar datos desde sistemas externos, Excel o fuentes reales |
| **Estándar industrial** | Es la técnica usada en procesos ETL y migraciones de datos reales |

### ❌ Limitaciones

| Limitación | Detalle |
|-----------|---------|
| **Requiere archivo externo** | El archivo CSV debe existir en una ruta accesible desde el servidor SQL |
| **Permisos especiales** | Requiere el permiso `ADMINISTER BULK OPERATIONS` (nivel administrador de servidor) |
| **Ruta fija del servidor** | La ruta del archivo es relativa al **servidor SQL**, no al cliente; complica entornos remotos |
| **No valida FK automáticamente** | Si los datos del CSV referencian IDs inexistentes, el INSERT falla con error de clave foránea |
| **Formato estricto** | Cualquier inconsistencia en el CSV (comillas, encoding, saltos de línea) causa errores |
| **No genera datos** | Alguien debe **generar primero** el CSV con datos válidos (con Python, Excel, Mockaroo, etc.) |

---

## **3. COMPARATIVA DIRECTA**

| Criterio | INSERT Masivo T-SQL | BULK INSERT + CSV |
|----------|--------------------|--------------------|
| **Requiere archivo externo** | ❌ No | ✅ Sí (obligatorio) |
| **Velocidad (10.000 filas)** | Adecuada (3-7 min) | Muy rápida (<30 seg) |
| **Velocidad (1.000.000 filas)** | Lenta (horas) | Rápida (minutos) |
| **Validación de FK** | ✅ Automática (en tiempo real) | ⚠️ Manual (deben ser IDs válidos en el CSV) |
| **Permisos requeridos** | Usuario normal con `INSERT` | `ADMINISTER BULK OPERATIONS` |
| **Datos dinámicos/aleatorios** | ✅ Sí (NEWID, CHECKSUM) | ❌ No (datos fijos del archivo) |
| **Portabilidad entre entornos** | ✅ Total (solo el .sql) | ⚠️ Depende de la ruta del archivo en el servidor |
| **Archivo entregable separado** | ❌ No genera archivo | ✅ El CSV es el archivo entregable |
| **Uso en proyectos educativos** | ✅ Recomendado | ✅ Recomendado (si hay CSV) |
| **Uso en producción/ETL real** | ⚠️ Para volúmenes moderados | ✅ Estándar de la industria |

---

## **4. DECISIÓN DEL PROYECTO ESBIRROSDB**

### Técnica Elegida: **INSERT Masivo T-SQL**

Para el proyecto EsbirrosDB se adoptó la técnica de **INSERT masivo mediante T-SQL** por las siguientes razones:

#### 4.1 Contexto educativo y portabilidad
El proyecto debe poder ejecutarse en cualquier PC de los alumnos o en el entorno del laboratorio, sin depender de rutas de archivos específicas del servidor. Un script `.sql` autocontenido garantiza que cualquier evaluador puede reproducirlo en un solo paso.

#### 4.2 Integridad referencial garantizada
El script genera los IDs de clientes, empleados y canales **consultando los rangos válidos existentes en la base de datos** al momento de la ejecución, eliminando el riesgo de violar claves foráneas —problema frecuente al cargar un CSV con datos estáticos en una BD con datos preexistentes.

#### 4.3 Datos con distribución controlada
La lógica T-SQL permite definir explícitamente que el 50% de los pedidos sean de canal Mostrador, el 30% Delivery, etc., reflejando el comportamiento real del negocio, algo imposible de garantizar con un CSV genérico.

#### 4.4 Volumen adecuado al contexto
Con 10.000 pedidos + ~43.000 registros totales, el tiempo de ejecución de 3-7 minutos es perfectamente aceptable para un entorno de evaluación educativa. BULK INSERT sería necesario a partir de cientos de miles de filas.

---

## **5. ¿CUÁNDO USAR CADA TÉCNICA?**

```
¿Tenés datos REALES de un sistema externo?
    → BULK INSERT + CSV

¿Necesás cargar MILLONES de filas rápidamente?
    → BULK INSERT + CSV

¿Necesás datos de PRUEBA coherentes con tu esquema?
    → INSERT Masivo T-SQL

¿El script debe ser PORTABLE y autocontenido?
    → INSERT Masivo T-SQL

¿Estás en un entorno EDUCATIVO sin rutas de servidor fijas?
    → INSERT Masivo T-SQL  ← caso EsbirrosDB
```

---

## **6. EJEMPLO: CÓMO SERÍA LA ALTERNATIVA CON BULK INSERT EN ESBIRROSDB**

Si se hubiera elegido BULK INSERT, el flujo completo hubiera sido:

**Paso 1 — Generar el CSV con Python (o Mockaroo/ChatGPT)**
```python
import csv, random
from datetime import datetime, timedelta

with open('pedidos_10000.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['canal_id','cliente_id','empleado_id','estado_id','fecha_pedido'])
    for _ in range(10000):
        writer.writerow([
            random.randint(1, 4),
            random.randint(20, 3019),
            random.randint(1, 19),
            7,
            (datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d')
        ])
```

**Paso 2 — Copiar el CSV al servidor SQL**
```
C:\SQLData\pedidos_10000.csv
```

**Paso 3 — Ejecutar BULK INSERT**
```sql
BULK INSERT PEDIDOS
FROM 'C:\SQLData\pedidos_10000.csv'
WITH (FIELDTERMINATOR=',', ROWTERMINATOR='\n', FIRSTROW=2, TABLOCK);
```

**Problemas que hubiera generado en este proyecto:**
- Los `cliente_id` del CSV hubieran sido IDs fijos, pero los clientes se insertan con `IDENTITY` → desincronización.
- Se necesitaría primero insertar los 3.000 clientes, obtener sus IDs reales, y recién ahí generar el CSV de pedidos.
- La ruta `C:\SQLData\` debe existir **en el servidor SQL**, no en la PC del alumno.

---

## **CONCLUSIÓN**

Ambas técnicas son válidas y complementarias. **No existe una "mejor" en absoluto** — la elección depende del contexto:

- **BULK INSERT** es el estándar cuando se trabaja con datos reales, migraciones o volúmenes masivos (>100K filas).
- **INSERT Masivo T-SQL** es la elección correcta cuando se necesita portabilidad, coherencia referencial automática y datos de prueba controlados —exactamente el caso de EsbirrosDB.

La decisión tomada en este proyecto es técnicamente justificada, documentada y consistente con las buenas prácticas para el contexto educativo y el volumen de datos requerido.

---

**Documento generado por SQLeaders S.A. — 2026**
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**
