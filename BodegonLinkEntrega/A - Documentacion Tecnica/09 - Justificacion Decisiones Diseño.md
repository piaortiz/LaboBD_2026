# JUSTIFICACIÓN DE DECISIONES DE DISEÑO — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                |
|-----------------|------------------------------------------------|
| **Documento**   | Justificación de Decisiones de Diseño          |
| **Proyecto**    | Sistema de Gestión de Bodegón Porteño          |
| **CLIENTES**     | Bodegón Los Esbirros de Claudio                |
| **Instituto**   | ISTEA                                          |
| **Materia**     | Laboratorio de Administración de Bases de Datos |
| **Profesor**    | Carlos Alejandro Caraccio                      |
| **Versión**     | 1.0                                            |
| **Fecha**       | Abril 2026                                     |
| **Estado**      | Documentación Post-Presentación                |

---

## **RESUMEN EJECUTIVO**

Este documento justifica y defiende las **decisiones clave de diseño** del sistema EsbirrosDB, especialmente aquellas que podrían generar cuestionamientos durante la evaluación técnica. Cada decisión fue tomada conscientemente, evaluando alternativas y priorizando escalabilidad, mantenibilidad y adherencia a principios de diseño de bases de datos.

---

## **1. SEPARACIÓN: STOCKS_SIMULADOS ↔ PLATOS**

### 📌 Decisión de Diseño

**Mantener `STOCKS_SIMULADOS` como tabla independiente con relación 1:0..1 con `PLATOS`**, a pesar de que ambas comparten `plato_id` como clave primaria.

### 🔍 Contexto

Durante la presentación del proyecto, el profesor cuestionó esta relación 1:1, preguntando si no sería más apropiado integrar los campos de stock directamente en la tabla `PLATOS`, evitando así lo que podría parecer una violación de las formas normales.

### ✅ Justificación Técnica

#### **1.1 Separación de Responsabilidades (SRP)**

**PLATOS: Catálogo Permanente del Negocio**
```sql
CREATE TABLE PLATOS (
    plato_id  INT PRIMARY KEY,
    nombre    NVARCHAR(100) NOT NULL,  -- ¿Qué vendemos?
    categoria NVARCHAR(50) NOT NULL,   -- ¿De qué tipo es?
    activo    BIT NOT NULL DEFAULT 1   -- ¿Está disponible en el menú?
)
```
- **Propósito:** Define QUÉ vende el bodegón
- **Estabilidad:** Los platos cambian raramente (agregar/quitar del menú)
- **Alcance:** Información de negocio permanente

**STOCKS_SIMULADOS: Control Operativo Temporal**
```sql
CREATE TABLE STOCKS_SIMULADOS (
    plato_id             INT PRIMARY KEY,
    stock_disponible     INT NOT NULL,      -- ¿Cuánto tenemos ahora?
    stock_minimo         INT NOT NULL,      -- ¿Cuándo reabastecer?
    ultima_actualizacion DATETIME NOT NULL  -- ¿Cuándo cambió?
)
```
- **Propósito:** Controla CUÁNTO hay disponible
- **Volatilidad:** Cambia con cada PEDIDOS (triggers automáticos)
- **Alcance:** Información operativa temporal

**Beneficio:** Cada tabla tiene una responsabilidad única y claramente definida.

---

#### **1.2 Modularidad del Sistema**

**Sistema sin control de stock:**
```
PLATOS ───► DETALLES_PEDIDOS ───► PEDIDOS
    ↑
    └─ Catálogo completo funcional
```

**Sistema con control de stock:**
```
PLATOS ───► DETALLES_PEDIDOS ───► PEDIDOS
  ↓
STOCKS_SIMULADOS (opcional)
  ↓
Triggers de validación
```

**Ventaja:** El bodegón puede operar en "modo catálogo puro" sin stock, o activar control de inventario según necesidades operativas, simplemente eliminando/agregando la tabla `STOCKS_SIMULADOS` sin tocar la estructura core.

---

#### **1.3 Extensibilidad Futura**

**Escenario actual:** Stock global
```sql
STOCKS_SIMULADOS (
    plato_id INT PRIMARY KEY,
    stock_disponible INT
)
```

**Escenario futuro:** Stock por SUCURSALES (sin modificar PLATOS)
```sql
STOCKS_SIMULADOS (
    plato_id INT,
    sucursal_id INT,
    stock_disponible INT,
    PRIMARY KEY (plato_id, sucursal_id)
)
```

**Escenario avanzado:** Stock por lote con vencimiento
```sql
STOCKS_SIMULADOS (
    plato_id INT,
    sucursal_id INT,
    lote_id INT,
    stock_disponible INT,
    fecha_vencimiento DATE,
    PRIMARY KEY (plato_id, sucursal_id, lote_id)
)
```

**Ventaja:** La evolución del modelo de stock NO requiere modificar la tabla `PLATOS`, que es core del negocio.

---

#### **1.4 Auditoría Diferenciada**

**Cambios en PLATOS (raros, críticos):**
- Agregar nuevo PLATOS al menú → Notificación a gerencia
- Cambiar categoría → Revisión de cartas
- Desactivar PLATOS → Comunicación a cocina

**Cambios en STOCKS_SIMULADOS (frecuentes, operativos):**
- Descuento automático por PEDIDOS → Trigger
- Stock bajo del mínimo → Alerta automática
- Reabastecimiento → Log operativo

**Ventaja:** Los sistemas de auditoría pueden diferenciar criticidad y actuar en consecuencia.

---

#### **1.5 Performance en Consultas**

**Consulta del menú (80% de las queries):**
```sql
-- Sin STOCK: JOIN innecesario evitado
SELECT plato_id, nombre, categoria, activo
FROM PLATOS
WHERE activo = 1
```

**Validación de stock (solo cocina, 20% de queries):**
```sql
SELECT p.nombre, s.stock_disponible
FROM PLATOS p
INNER JOIN STOCKS_SIMULADOS s ON p.plato_id = s.plato_id
WHERE s.stock_disponible < s.stock_minimo
```

**Ventaja:** Las consultas más frecuentes (menú para clientes) no cargan datos de stock innecesarios.

---

### ❌ Alternativa Evaluada y Descartada

**Opción rechazada: Integrar stock en PLATOS**
```sql
CREATE TABLE PLATOS (
    plato_id             INT PRIMARY KEY,
    nombre               NVARCHAR(100) NOT NULL,
    categoria            NVARCHAR(50) NOT NULL,
    activo               BIT NOT NULL DEFAULT 1,
    stock_disponible     INT NULL,      -- ⚠️ Problema 1
    stock_minimo         INT NULL,      -- ⚠️ Problema 2
    ultima_actualizacion DATETIME NULL  -- ⚠️ Problema 3
)
```

**Problemas identificados:**

1. **Ambigüedad semántica:** ¿NULL significa "sin control de stock" o "stock agotado"?
2. **Mezcla de responsabilidades:** Catálogo + operaciones en una sola tabla
3. **Dificulta extensibilidad:** Stock por SUCURSALES requiere refactorización completa
4. **Triggers afectan tabla principal:** Cada PEDIDOS dispara UPDATE en PLATOS
5. **Auditoría mezclada:** Cambios en menú vs cambios operativos sin distinción

---

### 🎯 Conclusión

La separación de `STOCKS_SIMULADOS` **NO viola la Tercera Forma Normal** porque está **funcionalmente justificada** por:
- Separación de responsabilidades (SRP)
- Modularidad del sistema
- Extensibilidad futura
- Auditoría diferenciada
- Optimización de performance

**Esta es una decisión consciente de diseño, no un error de normalización.**

---

## **2. SEPARACIÓN: PRECIOS ↔ PLATOS**

### 📌 Decisión de Diseño

**Mantener `PRECIOS` como tabla independiente con relación 1:N con `PLATOS`**, almacenando histórico completo de precios con vigencias temporales.

### 🔍 Contexto

El profesor validó esta decisión pero solicitó que esté **explícitamente documentada** para que la razón se comprenda a simple vista en la documentación técnica.

### ✅ Justificación Técnica

#### **2.1 Auditoría de Cambios de PRECIOS (Razón Principal)**

**Problema:** Si actualizamos el PRECIOS directamente en `PLATOS`, perdemos el histórico.

**Solución:** Insertar nuevo registro con vigencia, nunca actualizar el anterior.

**Ejemplo real:**
```sql
-- Bife de Chorizo (plato_id = 5)

-- PRECIOS Q1 2026
INSERT INTO PRECIOS VALUES (5, '2026-01-01', '2026-03-31', 8500.00)

-- PRECIOS Q2 2026 (aumento del 8.2%)
INSERT INTO PRECIOS VALUES (5, '2026-04-01', '2026-06-30', 9200.00)

-- PRECIOS Q3 2026 en adelante
INSERT INTO PRECIOS VALUES (5, '2026-07-01', NULL, 9800.00)

-- ✅ Los 3 registros se conservan para auditoría
```

**Beneficios:**
- ✅ Historial completo de cambios de PRECIOS
- ✅ Auditoría financiera: ¿Cuánto costaba el 15 de febrero?
- ✅ Análisis de rentabilidad: evolución de precios vs costos
- ✅ Reportes históricos: facturación por período con precios correctos

---

#### **2.2 Precios Diferenciados por Fecha (Razón Secundaria)**

**Caso de uso real del bodegón:**

| Día | PRECIOS Bife de Chorizo | Razón |
|-----|------------------------|-------|
| Lunes-Jueves | $8,500 | PRECIOS regular |
| Viernes-Domingo | $9,200 | PRECIOS fin de semana (+8.2%) |
| Feriados | $9,800 | PRECIOS especial (+15.3%) |

**Implementación:**
```sql
-- PRECIOS regular semana
INSERT INTO PRECIOS VALUES (5, '2026-01-06', '2026-01-09', 8500.00)  -- Lun-Jue

-- PRECIOS fin de semana
INSERT INTO PRECIOS VALUES (5, '2026-01-10', '2026-01-12', 9200.00)  -- Vie-Dom

-- PRECIOS regular siguiente semana
INSERT INTO PRECIOS VALUES (5, '2026-01-13', '2026-01-16', 8500.00)  -- Lun-Jue
```

**Consulta automática del PRECIOS vigente:**
```sql
SELECT TOP 1 PRECIOS
FROM PRECIOS
WHERE plato_id = @plato_id
  AND vigencia_desde <= GETDATE()
  AND (vigencia_hasta IS NULL OR vigencia_hasta >= GETDATE())
ORDER BY vigencia_desde DESC
```

---

#### **2.3 Precios Programados Futuros**

**Escenario:** Hoy es 15 de junio, pero ya sabemos que habrá aumento el 1 de julio.

```sql
-- PRECIOS actual (hasta 30 de junio)
INSERT INTO PRECIOS VALUES (5, '2026-04-01', '2026-06-30', 9200.00)

-- PRECIOS futuro (desde 1 de julio) - ya registrado
INSERT INTO PRECIOS VALUES (5, '2026-07-01', NULL, 9800.00)
```

**Ventaja:** El aumento se aplica automáticamente el día programado sin intervención manual.

---

#### **2.4 Trazabilidad en Pedidos**

**Cuando se crea un PEDIDOS:**
```sql
-- DETALLES_PEDIDOS guarda el PRECIOS del momento
INSERT INTO DETALLES_PEDIDOS (pedido_id, plato_id, cantidad, precio_unitario)
VALUES (1001, 5, 2, 9200.00)  -- PRECIOS vigente al momento de la venta
```

**Consulta histórica:**
```sql
-- ¿Qué PRECIOS se cobró en el PEDIDOS 1001?
SELECT precio_unitario FROM DETALLES_PEDIDOS WHERE pedido_id = 1001

-- ¿Qué precios tuvo el bife durante marzo 2026?
SELECT PRECIOS, vigencia_desde, vigencia_hasta
FROM PRECIOS
WHERE plato_id = 5
  AND vigencia_desde <= '2026-03-31'
  AND (vigencia_hasta IS NULL OR vigencia_hasta >= '2026-03-01')
```

---

### ❌ Alternativa Evaluada y Descartada

**Opción rechazada: Múltiples columnas de PRECIOS en PLATOS**
```sql
CREATE TABLE PLATOS (
    plato_id           INT PRIMARY KEY,
    nombre             NVARCHAR(100) NOT NULL,
    precio_regular     DECIMAL(10,2) NOT NULL,  -- ⚠️ Inflexible
    precio_finde       DECIMAL(10,2) NULL,      -- ⚠️ Solo 2 tipos
    precio_feriado     DECIMAL(10,2) NULL,      -- ⚠️ ¿Y si hay 3 feriados distintos?
    precio_promocion   DECIMAL(10,2) NULL       -- ⚠️ Sin fecha de inicio/fin
)
```

**Problemas identificados:**

1. **Sin historial:** Al actualizar `precio_regular`, se pierde el valor anterior
2. **Inflexibilidad:** Solo 4 tipos de PRECIOS predefinidos
3. **Sin trazabilidad:** ¿Cuándo cambió cada PRECIOS?
4. **Redundancia:** Muchos platos repiten el mismo patrón de precios
5. **Sin automatización:** ¿Cuándo aplica cada PRECIOS? Requiere lógica de aplicación compleja

---

### 🎯 Conclusión

La tabla `PRECIOS` separada es una **decisión de diseño deliberada** para soportar:
1. **Auditoría completa** de cambios de PRECIOS (razón principal)
2. **Precios temporales** diferenciados por fecha
3. **Precios programados** con aplicación automática
4. **Trazabilidad** en pedidos históricos
5. **Escalabilidad** futura (PRECIOS por canal, por SUCURSALES, etc.)

**Sin esta separación, perdemos capacidad de auditoría y flexibilidad operativa.**

---

## **3. SEPARACIÓN: DOMICILIOS ↔ CLIENTES**

### 📌 Decisión de Diseño

**Mantener `DOMICILIOS` como tabla independiente con relación 1:N con `CLIENTES`**, permitiendo que un CLIENTES registre múltiples direcciones de entrega.

### 🔍 Contexto

El profesor cuestionó inicialmente la separación, pero al explicar el caso de uso (un CLIENTES puede tener dirección de casa, trabajo, temporal, etc.) validó la decisión. Además, sugirió agregar un campo `tipo_domicilio` para mejor identificación visual.

### ✅ Justificación Técnica

#### **3.1 Caso de Uso Real**

**Escenario común en delivery:**

CLIENTES: Juan Pérez
- **DOMICILIOS 1:** Casa particular en CABA (principal)
- **DOMICILIOS 2:** Oficina en CABA (laboral)
- **DOMICILIOS 3:** Casa de fin de semana en GBA (temporal)

**Sin tabla separada:**
- CLIENTES tendría que reingresar dirección en cada PEDIDOS
- Sin historial de direcciones usadas
- Imposible analizar zonas de entrega frecuentes

**Con tabla separada:**
```sql
-- CLIENTES registra direcciones una vez
CLIENTES: Juan Pérez (cliente_id = 42)
  ↓
DOMICILIOS:
  - domicilio_id=101, calle="Av. Corrientes 1234", es_principal=1
  - domicilio_id=102, calle="Av. Santa Fe 5678", es_principal=0
  - domicilio_id=103, calle="Calle Falsa 123", es_principal=0

-- En cada PEDIDOS, solo selecciona domicilio_id
PEDIDOS: pedido_id=1001, cliente_id=42, domicilio_id=102  -- A la oficina
PEDIDOS: pedido_id=1002, cliente_id=42, domicilio_id=101  -- A casa
```

---

#### **3.2 Mejora Implementada: Campo tipo_domicilio**

**Problema identificado por el profesor:**
```
DOMICILIOS 1: es_principal=1  ← ¿Es casa? ¿Es trabajo?
DOMICILIOS 2: es_principal=0  ← ¿Qué tipo es este?
```

El campo `es_principal` indica cuál DOMICILIOS es el predeterminado, pero no describe el **propósito** de cada dirección.

**Solución implementada (Bundle A1 actualizado):**
```sql
CREATE TABLE DOMICILIOS (
    -- ... campos existentes ...
    es_principal   BIT          NOT NULL DEFAULT 0,
    tipo_domicilio NVARCHAR(50) NULL DEFAULT 'Particular',
    CONSTRAINT CK_DOMICILIO_tipo CHECK (
        tipo_domicilio IN ('Particular', 'Laboral', 'Temporal', 'Otro')
    )
)
```

**Valores permitidos:**
- **Particular:** DOMICILIOS de residencia habitual
- **Laboral:** Dirección del lugar de trabajo
- **Temporal:** Casa de fin de semana, hotel, dirección esporádica
- **Otro:** Cualquier categoría no contemplada

**Beneficio visual en la interfaz:**
```
✅ ANTES (solo es_principal):
   DOMICILIOS 1: Av. Corrientes 1234 [PRINCIPAL]
   DOMICILIOS 2: Av. Santa Fe 5678

✅ DESPUÉS (con tipo_domicilio):
   DOMICILIOS 1: Av. Corrientes 1234 [Particular ⭐ Principal]
   DOMICILIOS 2: Av. Santa Fe 5678 [Laboral]
   DOMICILIOS 3: Calle Falsa 123 [Temporal]
```

**Estado:** ✅ Implementado en Bundle A1 + Script de carga masiva V3 actualizado

---

#### **3.3 Análisis de Negocio**

**Con DOMICILIOS separado:**
```sql
-- ¿A qué zonas entregamos más?
SELECT localidad, COUNT(*) AS entregas
FROM PEDIDOS p
INNER JOIN DOMICILIOS d ON p.domicilio_id = d.domicilio_id
GROUP BY localidad
ORDER BY entregas DESC

-- ¿Qué clientes tienen múltiples direcciones?
SELECT c.nombre, COUNT(d.domicilio_id) AS cant_domicilios
FROM CLIENTES c
INNER JOIN DOMICILIOS d ON c.cliente_id = d.cliente_id
GROUP BY c.nombre
HAVING COUNT(d.domicilio_id) > 1
```

---

### ❌ Alternativa Evaluada y Descartada

**Opción rechazada: Dirección integrada en CLIENTES**
```sql
CREATE TABLE CLIENTES (
    cliente_id INT PRIMARY KEY,
    nombre NVARCHAR(100),
    calle NVARCHAR(100),      -- ⚠️ Solo una dirección
    numero NVARCHAR(10),
    localidad NVARCHAR(50),
    provincia NVARCHAR(50)
)
```

**Problemas identificados:**

1. **Limitación artificial:** CLIENTES solo puede tener 1 dirección
2. **Cambio de DOMICILIOS:** Actualizar pierde dirección anterior
3. **Sin historial:** No se puede rastrear direcciones usadas
4. **Pedir a diferente dirección:** Requiere actualizar CLIENTES temporalmente
5. **Análisis imposible:** No se pueden estudiar zonas de entrega

---

### 🎯 Conclusión

La separación de `DOMICILIOS` está plenamente justificada por:
- Caso de uso real: múltiples direcciones por CLIENTES
- Reusabilidad: CLIENTES no reingresa datos
- Historial: trazabilidad de direcciones usadas
- Análisis: estudios de zonas de entrega
- Mejora implementada: campo `tipo_domicilio` para claridad visual

---

## **4. NORMALIZACIÓN APLICADA**

### 📌 Afirmación

**El sistema EsbirrosDB cumple con la Tercera Forma Normal (3FN) en todas sus tablas.**

### ✅ Verificación

#### **Primera Forma Normal (1FN)**

**Requisito:** No grupos repetitivos, valores atómicos

✅ **Cumplimiento verificado:**

```sql
-- ❌ Violación evitada: No hacemos esto
PEDIDOS (items = "2x Empanadas, 1x Bife, 1x Flan")

-- ✅ Diseño correcto: Tabla separada
PEDIDOS (pedido_id)
  ↓
DETALLES_PEDIDOS (detalle_id, pedido_id, plato_id, cantidad)
```

```sql
-- ❌ Violación evitada: No hacemos esto
DOMICILIOS (direccion_completa = "Av. Corrientes 1234, Piso 5, Depto A")

-- ✅ Diseño correcto: Campos atómicos
DOMICILIOS (calle, numero, piso, depto, localidad, provincia)
```

---

#### **Segunda Forma Normal (2FN)**

**Requisito:** Sin dependencias parciales (todos los atributos dependen de la PK completa)

✅ **Cumplimiento verificado:**

```sql
-- ❌ Violación evitada: No hacemos esto
DETALLES_PEDIDOS (
    pedido_id,
    plato_id,
    nombre_plato,  -- ⚠️ Depende solo de plato_id, no de (pedido_id, plato_id)
    PRIMARY KEY (pedido_id, plato_id)
)

-- ✅ Diseño correcto: nombre_plato está en PLATOS
DETALLES_PEDIDOS (pedido_id, plato_id, cantidad, precio_unitario)
PLATOS (plato_id, nombre, categoria)
```

---

#### **Tercera Forma Normal (3FN)**

**Requisito:** Sin dependencias transitivas

✅ **Cumplimiento verificado:**

```sql
-- ❌ Violación evitada: No hacemos esto
EMPLEADOS (
    empleado_id,
    rol_id,
    rol_nombre  -- ⚠️ Depende de rol_id, no directamente de empleado_id
)

-- ✅ Diseño correcto: rol_nombre está en ROLES
EMPLEADOS (empleado_id, nombre, rol_id) → FK a ROLES
ROLES (rol_id, nombre, descripcion)
```

---

#### **Desnormalización Controlada**

**Único caso identificado: `PEDIDOS.total`**

```sql
PEDIDOS (
    pedido_id,
    total DECIMAL(10,2)  -- ⚠️ Calculable desde DETALLES_PEDIDOS
)
```

**Justificación:**
- **Performance:** Evita SUM() en cada consulta de PEDIDOS
- **Controlado:** Trigger `tr_ActualizarTotales` mantiene consistencia automática
- **Auditoría:** Valor capturado al momento de la transacción

**Decisión:** Desnormalización aceptable por beneficio de performance vs costo mínimo de mantenimiento automatizado.

---

### 🎯 Conclusión

El sistema cumple **estrictamente con 3FN** en todas las tablas, con una desnormalización controlada (`PEDIDOS.total`) justificada por performance y mantenida automáticamente por triggers.

---

## **5. USO DE INTELIGENCIA ARTIFICIAL**

### 📌 Aclaración Importante

Durante el desarrollo del proyecto **se utilizó Inteligencia Artificial como herramienta de apoyo**, similar a cómo se utilizan recursos como StackOverflow, documentación oficial de SQL Server, o libros técnicos.

### ✅ Cómo Se Utilizó

#### **5.1 Generación de Estructuras Base**

**IA generó:**
- Estructuras iniciales de tablas
- Scripts de stored procedures básicos
- Sintaxis de triggers
- Código boilerplate

**Equipo validó y adaptó:**
- Revisión línea por línea
- Adaptación al negocio real del bodegón
- Eliminación de elementos innecesarios
- Ajuste de constraints y validaciones

---

#### **5.2 Ejemplo: Eliminación de Tablas Sugeridas**

**IA sugirió inicialmente:**
```sql
CREATE TABLE COMBO (...)
CREATE TABLE COMBO_DETALLE (...)
CREATE TABLE PROMOCION (...)
CREATE TABLE PROMOCION_PLATO (...)
```

**Equipo decidió eliminar tras relevar negocio:**
- Bodegón opera con platos individuales
- No arma combos predefinidos
- No aplica descuentos por promoción automática
- Modelo simplificado refleja realidad operativa

**Resultado:**
```sql
-- Diseño final: solo platos individuales
DETALLES_PEDIDOS (
    plato_id NOT NULL  -- Siempre un PLATOS individual
)
```

---

#### **5.3 Ejemplo: Ajuste de Reglas de Negocio**

**IA generó constraint genérico:**
```sql
CHECK (cantidad > 0)
```

**Equipo ajustó a reglas específicas del bodegón:**
```sql
CHECK (cantidad > 0 AND cantidad <= 100)  -- Límite razonable para pedidos
CHECK (PRECIOS >= 0)  -- Precios no negativos
CHECK (vigencia_hasta IS NULL OR vigencia_hasta >= vigencia_desde)
```

---

### 🎯 Conclusión

**La IA fue una herramienta, no un reemplazo del pensamiento crítico.**

Cada decisión de diseño fue:
- ✅ Evaluada por el equipo
- ✅ Validada contra requisitos del negocio
- ✅ Ajustada a la realidad operativa del bodegón
- ✅ Documentada con justificación técnica

**El conocimiento de bases de datos, normalización, y diseño relacional es del equipo, no de la IA.**

---

## **6. RESUMEN DE DECISIONES CLAVE**

| Decisión | Justificación Principal | Beneficio Clave |
|----------|-------------------------|-----------------|
| **STOCKS_SIMULADOS separado** | Separación de responsabilidades (SRP) | Extensibilidad a stock por SUCURSALES |
| **PRECIOS separado** | Auditoría de cambios de PRECIOS | Historial completo sin pérdida de datos |
| **DOMICILIOS separado** | Un CLIENTES, múltiples direcciones (1:N) | Reusabilidad y análisis de zonas |
| **Normalización 3FN** | Eliminación de redundancia y anomalías | Integridad de datos garantizada |
| **Uso de IA** | Aceleración de implementación | Más tiempo para validación y testing |

---

## **7. ARGUMENTOS DE DEFENSA**

### Para el Parcial - Respuestas de 30 Segundos

**"¿Por qué STOCKS_SIMULADOS está separado?"**
> "Aplicamos separación de responsabilidades. PLATOS es el catálogo permanente del negocio con definiciones estáticas. STOCKS_SIMULADOS es control operativo con actualizaciones frecuentes por triggers. Esta separación facilita escalar a stock por SUCURSALES simplemente agregando sucursal_id, sin modificar la estructura core del sistema."

**"¿Por qué PRECIOS está separado?"**
> "Principalmente para auditoría. Cuando un PRECIOS cambia, NO actualizamos el registro anterior, insertamos uno nuevo con fechas de vigencia. Así conservamos historial completo de todos los cambios para reportes financieros y análisis de rentabilidad. Además, permite precios diferenciados por fecha como fin de semana o feriados."

**"¿Por qué DOMICILIOS está separado?"**
> "Relación 1:N. Un CLIENTES puede tener varias direcciones de entrega: su casa, su trabajo, una dirección temporal. Marcamos una como principal y agregamos tipo_domicilio para identificar fácilmente el propósito de cada dirección. Esto evita reingresar datos y permite analizar zonas de entrega."

**"¿Usaron inteligencia artificial?"**
> "Sí, como herramienta de apoyo para acelerar la implementación, similar a usar StackOverflow. La IA generó estructuras base que validamos y adaptamos al negocio real. Por ejemplo, eliminamos COMBO y PROMOCION que la IA sugirió porque tras relevar el bodegón, confirmamos que operan solo con platos individuales. Cada decisión fue evaluada por el equipo."

**"¿Aplicaron normalización?"**
> "Sí, 3FN completa. Primera forma normal: sin grupos repetitivos, valores atómicos. Segunda forma normal: sin dependencias parciales. Tercera forma normal: sin dependencias transitivas, todos los atributos dependen directamente de la clave primaria. Tenemos una desnormalización controlada en PEDIDOS.total por performance, mantenida automáticamente por trigger."

---

## **8. CONCLUSIÓN FINAL**

El sistema **EsbirrosDB** fue diseñado siguiendo principios sólidos de bases de datos relacionales:

✅ **Normalización estricta:** 3FN en todas las tablas  
✅ **Separación de responsabilidades:** Cada tabla tiene un propósito claro  
✅ **Extensibilidad:** Diseño preparado para evolución futura  
✅ **Auditoría:** Trazabilidad completa de cambios críticos  
✅ **Adaptación al negocio:** Modelo refleja operación real del bodegón  

**Cada decisión fue tomada conscientemente, evaluando alternativas y priorizando mantenibilidad y escalabilidad a largo plazo.**

---

## **3. ÍNDICES ÚNICOS FILTRADOS (UIX) vs. UNIQUE CONSTRAINTS**

### 📌 Decisión de Diseño

**Implementar unicidad sobre columnas nullable mediante índices únicos filtrados (`UIX_`)** en lugar de `UNIQUE` constraints convencionales en las columnas `email`, `(doc_tipo, doc_nro)` de `CLIENTES` y `es_principal` de `DOMICILIOS`.

### 🔍 Contexto

SQL Server tiene una limitación conocida: una constraint `UNIQUE` sobre una columna nullable **solo permite un único valor NULL**. Si se intentan insertar dos clientes sin email registrado, el segundo INSERT falla con error de duplicado, aunque ambos sean NULL.

En EsbirrosDB, el email y el documento son **datos opcionales**: muchos clientes de delivery se registran solo con nombre y teléfono. Un sistema que rechace el segundo cliente sin email rompería el negocio.

### ✅ Justificación Técnica

#### **3.1 El Problema con UNIQUE convencional**

```sql
-- ❌ Esto causaría error al insertar el segundo cliente sin email:
ALTER TABLE CLIENTES ADD CONSTRAINT UK_CLIENTE_email UNIQUE (email)

INSERT INTO CLIENTES (nombre, email) VALUES ('Juan',  NULL)  -- OK
INSERT INTO CLIENTES (nombre, email) VALUES ('María', NULL)  -- ERROR: duplicate NULL
```

#### **3.2 La Solución: Índice Filtrado**

```sql
-- ✅ Esto permite múltiples NULL pero garantiza unicidad sobre valores reales:
CREATE UNIQUE NONCLUSTERED INDEX UIX_CLIENTE_email
    ON CLIENTES(email) WHERE email IS NOT NULL

INSERT INTO CLIENTES (nombre, email) VALUES ('Juan',  NULL)              -- OK
INSERT INTO CLIENTES (nombre, email) VALUES ('María', NULL)              -- OK (ambos NULL)
INSERT INTO CLIENTES (nombre, email) VALUES ('Pedro', 'p@mail.com')     -- OK
INSERT INTO CLIENTES (nombre, email) VALUES ('Ana',   'p@mail.com')     -- ERROR: duplicado real
```

**El índice filtrado solo indexa (y controla unicidad sobre) filas donde `email IS NOT NULL`**, ignorando completamente las filas con NULL.

#### **3.3 Los Tres UIX Implementados**

| Índice | Tabla | Filtro | Negocio que protege |
|--------|-------|--------|---------------------|
| `UIX_CLIENTE_email` | CLIENTES | `WHERE email IS NOT NULL` | Dos clientes no pueden compartir el mismo email |
| `UIX_CLIENTE_documento` | CLIENTES | `WHERE doc_tipo IS NOT NULL AND doc_nro IS NOT NULL` | Dos clientes no pueden tener el mismo DNI/CUIL |
| `UIX_DOMICILIO_principal` | DOMICILIOS | `WHERE es_principal = 1` | Un cliente solo puede tener UN domicilio marcado como principal |

#### **3.4 Requisito Técnico**

Los índices filtrados en SQL Server requieren que la sesión tenga activos:
```sql
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
```
Por eso todos los bundles que crean o modifican estas tablas incluyen estas directivas al inicio.

### ✅ Resultado

- ✅ Múltiples clientes sin email pueden coexistir
- ✅ Dos clientes con el mismo email real son rechazados
- ✅ Solo un domicilio principal por cliente (enforcement automático por índice)
- ✅ Validado en TEST 14, 15 y 16 del script `TEST_Negocio.sql` (25/25 tests pasados)

---

**Fecha del Documento:** 25 de Abril de 2026
**Preparado por:** Equipo SQLeaders S.A.
**Revisado por:** Todos los integrantes
**Estado:** Listo para evaluación técnica

---

**ISTEA — Laboratorio de Bases de Datos 2026**
**Profesor:** Carlos Alejandro Caraccio
