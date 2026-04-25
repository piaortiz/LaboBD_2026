# 14 - Documentación de Prompts de IA Utilizados
## EsbirrosDB — Bodegón Los Esbirros de Claudio
**Proyecto académico ISTEA | Laboratorio de Bases de Datos 2026**
**Herramienta de IA:** GitHub Copilot (GPT-4o) vía Visual Studio Code
**Período de uso:** Abril 2026

---

## 1. Introducción

Durante el desarrollo del proyecto EsbirrosDB se utilizó inteligencia artificial generativa (GitHub Copilot) como asistente de diseño, escritura de código SQL y documentación técnica. Este documento registra los prompts más relevantes utilizados, las decisiones tomadas a partir de las respuestas, y una reflexión crítica sobre el rol de la IA en el proceso.

> **Nota metodológica:** El uso de IA fue **asistivo**, no delegativo. Todos los scripts fueron revisados, corregidos y validados manualmente antes de ser ejecutados contra la base de datos real. Los errores detectados se corrigieron en sesión (ver sección 5).

---

## 2. Inventario de Prompts Utilizados

### 2.1 Diseño del Modelo Relacional

**Prompt:**
> "Tengo un negocio de bodegón porteño llamado Los Esbirros de Claudio. Necesito un modelo de base de datos relacional para gestionar pedidos, clientes con múltiples domicilios, productos con stock, empleados y delivery. Dame las tablas con sus columnas, tipos de datos y relaciones."

**Resultado obtenido:**
- Propuesta inicial de 12 tablas core: `CLIENTES`, `DOMICILIOS`, `PRODUCTOS`, `CATEGORIAS`, `PEDIDOS`, `ITEMS_PEDIDO`, `EMPLEADOS`, `DELIVERY`, `PAGOS`, `PROVEEDORES`, `STOCK`, `USUARIOS`
- Identificación de la relación 1:N entre `CLIENTES` y `DOMICILIOS`
- Sugerencia de usar `IDENTITY` como PK en todas las tablas

**Decisión tomada:** Se adoptó la estructura propuesta con ajustes manuales en tipos de datos (por ejemplo, `DECIMAL(10,2)` para precios en lugar de `FLOAT`) y se agregaron las 4 tablas auxiliares de control.

---

### 2.2 Diccionario de Datos

**Prompt:**
> "Generá el diccionario de datos completo para las tablas CLIENTES, DOMICILIOS, PEDIDOS e ITEMS_PEDIDO de EsbirrosDB. Incluí nombre de columna, tipo de dato SQL Server, nullable, PK/FK, descripción de negocio y restricciones CHECK si aplica."

**Resultado obtenido:**
- Tabla markdown con columnas bien tipadas
- CHECK constraints sugeridos: `tipo_domicilio IN ('Particular','Laboral','Temporal','Otro')`, `estado_pedido IN ('Pendiente','En preparación','En camino','Entregado','Cancelado')`
- Notas sobre `es_principal BIT DEFAULT 1`

**Decisión tomada:** Se adoptaron los CHECK constraints tal como fueron sugeridos. El tipo de `es_principal` fue cambiado a `TINYINT` en la tabla de staging (por compatibilidad con BULK INSERT) pero se mantuvo como `BIT` en la tabla real.

---

### 2.3 Reglas del Negocio

**Prompt:**
> "Definí las reglas de negocio para un sistema de gestión de bodegón porteño. Contemplá: restricciones sobre pedidos (mínimo de items, estados válidos), política de domicilios por cliente, manejo de stock, lógica de delivery y condiciones de pago."

**Resultado obtenido:**
- 18 reglas de negocio organizadas por dominio
- Distinción entre reglas implementadas en BD (triggers, CHECK) y reglas de aplicación

**Decisión tomada:** Se seleccionaron 12 reglas para implementar a nivel de base de datos mediante triggers y constraints. Las restantes se documentaron como reglas de capa de aplicación.

---

### 2.4 Comparación INSERT Masivo vs BULK INSERT

**Prompt:**
> "Explicá las diferencias técnicas entre INSERT masivo con T-SQL y BULK INSERT en SQL Server. Incluí: velocidad, logging, casos de uso, ventajas y desventajas de cada uno. Lo necesito para documentación académica."

**Resultado obtenido:**
- Comparativa en tabla markdown con 8 dimensiones de análisis
- Explicación del logging mínimo en BULK INSERT
- Recomendación de BULK INSERT para volúmenes > 5.000 filas

**Decisión tomada:** Se usó INSERT T-SQL en Bundle F (por claridad pedagógica y control fila a fila) y BULK INSERT en Bundle H (para demostrar la técnica con un archivo CSV externo).

---

### 2.5 Diseño de la Solución BULK INSERT con CSV Desnormalizado

**Prompt:**
> "Necesito cargar 10.000 clientes y sus domicilios en SQL Server usando BULK INSERT. El problema es que DOMICILIOS tiene una FK a CLIENTES.cliente_id que es IDENTITY. No puedo poner el ID real en el CSV porque no lo conozco. ¿Cómo lo resuelvo?"

**Resultado obtenido:**
- Patrón staging table: cargar todo en tabla temporal sin restricciones → INSERT CLIENTES primero → INSERT DOMICILIOS con JOIN por clave natural (`doc_nro`)
- Sugerencia de usar `GROUP BY doc_nro` para deduplicar clientes del CSV
- Sugerencia de `WHERE NOT EXISTS` para idempotencia

**Decisión tomada:** Se implementó el patrón completo tal como fue sugerido. Fue la decisión de diseño más crítica del Bundle H.

---

### 2.6 Script Python Generador de CSV

**Prompt:**
> "Escribí un script Python que genere un CSV con 10.000 clientes ficticios para SQL Server. Cada cliente debe tener entre 1 y 3 domicilios: 80% con 1, 15% con 2, 5% con 3. El primer domicilio es siempre 'Particular' y es_principal=1. Los adicionales son de tipos aleatorios. Sin tildes. DNIs desde 40000001."

**Resultado obtenido:**
- Script completo con funciones `generar_domicilio()` y `generar_cliente()`
- Listas de nombres, apellidos, calles y localidades porteñas
- Lógica de distribución con `i % 100`
- Manejo de piso/depto opcionales (1 de cada 3)
- Output con estadísticas al finalizar

**Decisión tomada:** Se adoptó el script sin cambios estructurales. Se verificó la distribución en la ejecución real: 84.6% / 11.6% / 3.9% (ligeramente diferente al objetivo teórico por aleatoriedad, pero dentro de rango aceptable).

---

### 2.7 Script SQL BULK INSERT Completo

**Prompt:**
> "Escribí el script SQL Server completo para hacer BULK INSERT desde el CSV generado. Debe incluir: verificación de existencia del archivo, tabla staging, BULK INSERT con opciones correctas, INSERT a CLIENTES sin duplicados, INSERT a DOMICILIOS con JOIN por doc_nro, limpieza del staging y validación final con conteos."

**Resultado obtenido:**
- Script de 260 líneas con los 4 pasos bien estructurados
- Pre-validación con `xp_fileexist`
- Opciones de BULK INSERT: `TABLOCK`, `MAXERRORS=10`, `ERRORFILE`
- Validación final con query de distribución por cantidad de domicilios

**Decisión tomada:** Se adoptó la estructura. Se detectaron y corrigieron dos errores en ejecución real (ver sección 5).

---

### 2.8 Plan de Backup y Recuperación

**Prompt:**
> "Generá un plan de backup y recuperación para EsbirrosDB en SQL Server. Incluí: tipos de backup (full, diferencial, log), frecuencia recomendada, procedimiento de restauración paso a paso, políticas de retención y consideraciones para entorno académico."

**Resultado obtenido:**
- Plan con backup full semanal + diferencial diario + log cada 4 horas
- Scripts T-SQL para automatización con SQL Server Agent
- Checklist de verificación post-restauración

**Decisión tomada:** Se simplificó para contexto académico: backup full antes de cada entrega. Los scripts de automatización se incluyeron como referencia.

---

## 3. Prompts de Corrección y Debugging

### 3.1 Error RAISERROR con concatenación

**Contexto:** El script SQL fallaba con "Incorrect syntax near '+'" al ejecutarse vía sqlcmd.

**Prompt:**
> "Este RAISERROR falla en sqlcmd: `RAISERROR('texto' + CHAR(13) + 'más texto', 16, 1)`. ¿Por qué y cómo lo corrijo?"

**Respuesta:**
> RAISERROR no acepta expresiones de concatenación como primer argumento en todos los contextos. Usar una variable NVARCHAR intermedia: `DECLARE @msg NVARCHAR(500) = 'texto'; RAISERROR(@msg, 16, 1)`

**Acción:** Corrección aplicada en el script.

---

### 3.2 Error SET QUOTED_IDENTIFIER

**Contexto:** INSERT fallaba con "SET options have incorrect settings: QUOTED_IDENTIFIER".

**Prompt:**
> "INSERT falla con el error 'SET options have incorrect settings: QUOTED_IDENTIFIER' al ejecutar desde sqlcmd. ¿Qué causa esto y cómo se soluciona?"

**Respuesta:**
> sqlcmd ejecuta con `QUOTED_IDENTIFIER OFF` por defecto. Si la tabla tiene índices filtrados, vistas indexadas o columnas computadas, SQL Server exige que esté ON. Agregar `SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;` al inicio del script.

**Acción:** Se agregaron ambos SET al inicio del Bundle H.

---

## 4. Herramientas y Contexto de Uso

| Aspecto | Detalle |
|---|---|
| Herramienta | GitHub Copilot (modelo GPT-4o) |
| Interfaz | Visual Studio Code — panel de chat |
| Modalidad | Conversacional con contexto de archivos del workspace |
| Archivos compartidos como contexto | Scripts SQL, py, archivos .md del proyecto |
| Sesiones aproximadas | 3 sesiones de trabajo |
| Prompts de diseño | ~8 |
| Prompts de debugging | ~5 |
| Prompts de documentación | ~6 |

---

## 5. Errores Detectados y Corregidos Manualmente

| # | Error | Causa | Corrección |
|---|---|---|---|
| 1 | `RAISERROR` con `+` | Concatenación no permitida como argumento directo | Variable `NVARCHAR` intermedia |
| 2 | `SET QUOTED_IDENTIFIER` | sqlcmd lo desactiva por defecto | `SET QUOTED_IDENTIFIER ON` al inicio |
| 3 | Encoding `.md` corrompido | PowerShell `Out-File` usa UTF-16 por defecto | `[System.IO.File]::WriteAllText()` con `UTF8` explícito |

> Estos errores demuestran que **la IA genera código funcional en contexto ideal pero no siempre anticipa comportamientos específicos del entorno de ejecución** (sqlcmd, PowerShell, SQL Server versión específica). La revisión humana es indispensable.

---

## 6. Reflexión Crítica sobre el Uso de IA

### Lo que la IA hizo bien
- Estructuración rápida de ideas complejas (modelo relacional, plan de backup)
- Generación de código boilerplate (scripts SQL repetitivos, listas de datos ficticios)
- Explicación de conceptos técnicos con ejemplos concretos
- Sugerencia del patrón staging para resolver el problema de FK con IDENTITY (solución no obvia)

### Lo que requirió intervención humana
- Verificar que los tipos de datos coincidan exactamente con los DDL reales de EsbirrosDB
- Detectar errores de ejecución en entorno real (sqlcmd, versión de SQL Server)
- Ajustar rangos de DNI para evitar colisiones entre bundles
- Validar que los CHECK constraints del CSV generen datos válidos
- Decisiones de diseño académico (qué demostrar con cada técnica)

### Conclusión
La inteligencia artificial fue una herramienta de **aceleración y asistencia**, no un reemplazo del criterio técnico. El valor real estuvo en la combinación: IA para generación rápida + desarrollador para validación, corrección y decisiones de diseño contextual.

---

*Proyecto Educativo ISTEA — Laboratorio de Bases de Datos 2026*
