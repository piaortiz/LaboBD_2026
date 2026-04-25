# 13 - Documentación Técnica: Script Generador + BULK INSERT
## EsbirrosDB — Bodegón Los Esbirros de Claudio
**Proyecto académico ISTEA | Laboratorio de Bases de Datos 2026**
**Fecha de ejecución:** 25/04/2026

---

## 1. Visión General

La carga masiva de CLIENTES y DOMICILIOS se implementó en dos componentes complementarios:

| Componente | Archivo | Rol |
|---|---|---|
| Generador Python | `genera_csv_clientes_domicilios.py` | Produce el CSV con datos sintéticos |
| Script SQL | `Bundle_H_BulkInsert_Clientes_Domicilios.sql` | Carga el CSV en EsbirrosDB vía BULK INSERT |

**Carpeta:** `B - Scripts SQL/08_BulkInsert_Clientes_Domicilios/`

---

## 2. Script Generador de CSV (`genera_csv_clientes_domicilios.py`)

### 2.1 Propósito

Generar un archivo CSV único desnormalizado con 10.000 clientes y sus domicilios asociados, listo para ser consumido por `BULK INSERT` de SQL Server.

### 2.2 Tecnología

- **Lenguaje:** Python 3.12.9
- **Librerías:** `csv`, `random`, `os` (todas de la librería estándar — sin dependencias externas)

### 2.3 Parámetros de Configuración

```python
TOTAL_CLIENTES = 10000       # Cantidad de clientes a generar
DNI_BASE       = 40000001    # Primer DNI (evita colisión con Bundle F: 30000001-30003000)
OUTPUT_DIR     = r'C:\SQLData'
OUTPUT_FILE    = 'C:\SQLData\clientes_domicilios.csv'
```

### 2.4 Distribución de Domicilios

| Segmento | Condición | Domicilios | Clientes aprox. |
|---|---|---|---|
| Mayoría | `i % 100 < 80` | 1 | ~8.000 (80%) |
| Intermedio | `i % 100 < 95` | 2 | ~1.500 (15%) |
| Minoría | resto | 3 | ~500 (5%) |

**Resultado:** ~12.500 filas totales en el CSV (una fila por domicilio, datos del cliente repetidos).

### 2.5 Estructura del CSV

El CSV es **desnormalizado**: los datos del cliente se repiten en cada fila de domicilio.

```
doc_nro, nombre, telefono, email, doc_tipo,
calle, numero, piso, depto, localidad, provincia,
es_principal, tipo_domicilio, observaciones
```

**14 columnas** — sin espacios extra para compatibilidad con BULK INSERT.

### 2.6 Reglas de Generación

- **Primer domicilio** de cada cliente: `tipo_domicilio = 'Particular'`, `es_principal = 1`
- **Domicilios adicionales:** tipo aleatorio entre `['Laboral', 'Temporal', 'Otro']`, `es_principal = 0`
- **Piso/Depto:** presentes en 1 de cada 3 domicilios (columnas vacías en el resto)
- **DNI range:** `40000001` a `40010000` — sin colisión con cargas previas
- **Encoding:** UTF-8 sin BOM, saltos de línea LF (`\n`)
- **Sin tildes:** para compatibilidad garantizada con SQL Server ANSI

### 2.7 Ejecución

```powershell
# Recargar PATH si Python fue instalado en la misma sesión
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + `
            [System.Environment]::GetEnvironmentVariable("Path","User")

python "B - Scripts SQL\08_BulkInsert_Clientes_Domicilios\genera_csv_clientes_domicilios.py"
```

**Salida esperada:**
```
Archivo generado: C:\SQLData\clientes_domicilios.csv
Total de filas (sin encabezado): 12500
  - Clientes únicos: 10000
  - Clientes con 1 domicilio:  ~  8000
  - Clientes con 2 domicilios: ~  1500
  - Clientes con 3 domicilios: ~    500
```

---

## 3. Script BULK INSERT (`Bundle_H_BulkInsert_Clientes_Domicilios.sql`)

### 3.1 Propósito

Cargar el CSV generado en las tablas reales `CLIENTES` y `DOMICILIOS` de EsbirrosDB, respetando la normalización y las restricciones del modelo relacional (FK con IDENTITY, CHECK constraints).

### 3.2 Problema de Diseño Resuelto: FK con IDENTITY

`DOMICILIOS.cliente_id` es FK de `CLIENTES.cliente_id`, que es un campo `IDENTITY` generado automáticamente por SQL Server. El CSV no puede contener este ID porque no se conoce de antemano.

**Solución — Patrón Staging + JOIN por clave natural:**

```
CSV desnormalizado
      ↓
  #STAGING (tabla temporal sin FK ni IDENTITY)
      ↓
  INSERT CLIENTES (SQL Server genera cliente_id automáticamente)
      ↓
  INSERT DOMICILIOS (JOIN staging ⟷ CLIENTES por doc_nro → resuelve cliente_id)
```

### 3.3 Flujo Completo del Script

```
1. USE EsbirrosDB + SET QUOTED_IDENTIFIER ON / ANSI_NULLS ON
2. Pre-validación: xp_fileexist verifica que el CSV existe
3. CREATE TABLE #STAGING  (14 columnas, es_principal como TINYINT)
4. BULK INSERT #STAGING FROM 'C:\SQLData\clientes_domicilios.csv'
5. INSERT INTO CLIENTES ... WHERE NOT EXISTS (guard anti-duplicados)
6. INSERT INTO DOMICILIOS ... INNER JOIN CLIENTES ON doc_nro
7. DROP TABLE #STAGING
8. Validación final con conteos y muestra de datos
```

### 3.4 Opciones del BULK INSERT

```sql
BULK INSERT #STAGING
FROM 'C:\SQLData\clientes_domicilios.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',   -- LF: compatible Windows y Linux
    FIRSTROW        = 2,         -- saltar encabezado
    TABLOCK,                     -- bloqueo tabla = mayor rendimiento
    MAXERRORS       = 10,        -- abortar si hay más de 10 errores
    ERRORFILE       = 'C:\SQLData\errores_bulkinsert.log'
)
```

| Opción | Valor | Justificación |
|---|---|---|
| `FIELDTERMINATOR` | `,` | Estándar CSV |
| `ROWTERMINATOR` | `0x0a` | LF puro — más robusto que `\n` en sqlcmd |
| `FIRSTROW` | `2` | Evitar que el encabezado se interprete como dato |
| `TABLOCK` | — | Bloqueo a nivel tabla para inserción más veloz |
| `MAXERRORS` | `10` | Tolerancia controlada antes de abortar |
| `ERRORFILE` | ruta log | Registro de filas rechazadas para diagnóstico |

### 3.5 Protección contra Duplicados

Ambos `INSERT` incluyen guards `WHERE NOT EXISTS` para que el script sea **idempotente** (se puede correr múltiples veces sin generar duplicados):

```sql
-- CLIENTES: omite doc_nro ya existente
WHERE NOT EXISTS (
    SELECT 1 FROM CLIENTES c WHERE c.doc_nro = LTRIM(RTRIM(s.doc_nro))
)

-- DOMICILIOS: omite clientes que ya tienen domicilios cargados
WHERE NOT EXISTS (
    SELECT 1 FROM DOMICILIOS d WHERE d.cliente_id = c.cliente_id
)
```

### 3.6 Requerimientos de Ejecución

| Requerimiento | Detalle |
|---|---|
| SQL Server | 2016 o superior |
| Instancia | `localhost` con autenticación Windows |
| CSV en disco | `C:\SQLData\clientes_domicilios.csv` (generado por el script Python) |
| SET options | `QUOTED_IDENTIFIER ON`, `ANSI_NULLS ON` (requerido por índices filtrados) |
| Permiso SQL | `ADMINISTER BULK OPERATIONS` o `sysadmin` |

### 3.7 Ejecución via sqlcmd

```powershell
sqlcmd -S localhost -E -i "B - Scripts SQL\08_BulkInsert_Clientes_Domicilios\Bundle_H_BulkInsert_Clientes_Domicilios.sql"
```

### 3.8 Salida Esperada

```
BUNDLE H - BULK INSERT CLIENTES + DOMICILIOS v2.0
Archivo CSV verificado - OK
1. Staging creado - OK
2. Filas cargadas en staging: 12500 - OK
3. Clientes insertados: 10000 - OK
4. Domicilios insertados: 12500 - OK
   Staging eliminado - OK

VALIDACION FINAL:
Clientes nuevos cargados  : 10000
Domicilios cargados       : 12500
Clientes sin domicilio    : 0  (debe ser 0)
Distribución: 84.6% / 11.6% / 3.9%

BUNDLE H COMPLETADO EXITOSAMENTE
```

---

## 4. Resultado Final en EsbirrosDB

| Métrica | Valor |
|---|---|
| Clientes totales en BD | 13.004 |
| Domicilios totales en BD | 15.486 |
| Clientes sin domicilio | 0 |
| Clientes con 1 domicilio | ~84.6% |
| Clientes con 2 domicilios | ~11.6% |
| Clientes con 3 domicilios | ~3.9% |
| Tiempo de ejecución | ~2 segundos |

---

## 5. Rangos de DNI — Sin Colisión

| Bundle | Rango DNI | Técnica | Registros |
|---|---|---|---|
| Bundle F | `30000001` – `30003000` | INSERT T-SQL | 3.000 clientes |
| Bundle H | `40000001` – `40010000` | BULK INSERT | 10.000 clientes |

Los rangos fueron diseñados deliberadamente para evitar colisiones al ejecutar ambos scripts en la misma base de datos.

---

## 6. Cómo Restablecer (Reset Completo)

Si se necesita eliminar los datos del Bundle H y recargar desde cero:

```sql
-- Paso 1: eliminar domicilios
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
DELETE d FROM DOMICILIOS d
INNER JOIN CLIENTES c ON d.cliente_id = c.cliente_id
WHERE c.doc_nro LIKE '400%';

-- Paso 2: eliminar clientes
DELETE FROM CLIENTES WHERE doc_nro LIKE '400%';
```

```powershell
# Paso 3: eliminar CSV
Remove-Item "C:\SQLData\clientes_domicilios.csv" -Force

# Paso 4: regenerar y recargar
python genera_csv_clientes_domicilios.py
sqlcmd -S localhost -E -i Bundle_H_BulkInsert_Clientes_Domicilios.sql
```

---

*Proyecto Educativo ISTEA — Laboratorio de Bases de Datos 2026*
