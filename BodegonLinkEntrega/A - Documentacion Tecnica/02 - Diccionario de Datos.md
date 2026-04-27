# DICCIONARIO DE DATOS — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                |
|-----------------|------------------------------------------------|
| **Documento**   | Diccionario de Datos — EsbirrosDB             |
| **Proyecto**    | Sistema de Gestión de Bodegón Porteño          |
| **CLIENTES**     | Bodegón Los Esbirros de Claudio                |
| **Instituto**   | ISTEA                                          |
| **Materia**     | Laboratorio de Administración de Bases de Datos |
| **Profesor**    | Carlos Alejandro Caraccio                      |
| **Versión**     | 1.0                                            |
| **Estado**      | Implementado y Funcional                       |

---

## **RESUMEN EJECUTIVO**

### Estadísticas Generales

| **Métrica**              | **Valor** | **Descripción**                                   |
|--------------------------|-----------|---------------------------------------------------|
| **Tablas (Bundle A1)**   | 12        | Entidades principales del sistema                  |
| **Tablas auxiliares**    | 4         | Creadas por Bundles E1/E2/R1                       |
| **Total tablas**         | **16**    | Incluyendo auxiliares                              |
| **Campos totales**       | 75+       | Atributos en todas las tablas                      |
| **Claves Primarias**     | 16        | Una por tabla                                      |
| **Claves Foráneas**      | 17        | Referencias entre tablas                           |
| **Índices**              | 11        | 8 Non-clustered (A2) + 3 reportes (R1)             |
| **Triggers**             | 5         | Auditoría, totales, stock, notificaciones          |
| **Stored Procedures**    | 19        | Operacionales, consultas, reportes, control        |

### Distribución por Módulos

| **Módulo**               | **Tablas**                                              |
|--------------------------|---------------------------------------------------------|
| **Catálogos Base**       | SUCURSALES, CANALES_VENTAS, ESTADOS_PEDIDOS, ROLES, PLATOS        |
| **Personal y Ubicación** | MESAS, EMPLEADOS                                          |
| **Clientes**             | CLIENTES, DOMICILIOS                                      |
| **Productos y Precios**  | PRECIOS                                                  |
| **Pedidos**              | PEDIDOS, DETALLES_PEDIDOS                                  |
| **Auditoría y Control**  | AUDITORIAS_SIMPLES, STOCKS_SIMULADOS                         |
| **Notificaciones**       | NOTIFICACIONES                                          |
| **Reportes**             | REPORTES_GENERADOS                                      |

---

## **CONVENCIONES DE NOMENCLATURA**

| **Elemento**          | **Convención**        | **Ejemplo**                          |
|-----------------------|-----------------------|--------------------------------------|
| Tablas                | MAYÚSCULAS            | `PEDIDOS`, `DETALLES_PEDIDOS`        |
| Campos ID             | `tabla_id`            | `pedido_id`, `cliente_id`            |
| Claves Foráneas       | `FK_TABLA_campo`      | `FK_PEDIDO_cliente`                  |
| Claves Únicas         | `UK_TABLA_campo`      | `UK_MESA_qr_token`                   |
| Índices únicos filtrados | `UIX_TABLA_campo`  | `UIX_CLIENTE_email` (WHERE NOT NULL) |
| Check Constraints     | `CK_TABLA_campo`      | `CK_PRECIO_vigencia`                 |
| Índices de performance| `IX_TABLA_campos`     | `IX_PEDIDO_fecha_estado`             |
| Stored Procedures     | `sp_AccionEntidad`    | `sp_AgregarItemPedido`               |
| Triggers              | `tr_AccionTabla`      | `tr_ActualizarTotales`               |

---

## **DICCIONARIO DETALLADO POR TABLA**

---

### 1. SUCURSALES
**Propósito:** Almacena las sucursales del bodegón.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**  | **Descripción**                  |
|----------------|---------------|----------|-----------|--------------|----------------------------------|
| sucursal_id    | INT           | NO       | PK        | IDENTITY(1,1)| Identificador único de SUCURSALES  |
| nombre         | NVARCHAR(100) | NO       | UK        | —            | Nombre comercial de la SUCURSALES  |
| direccion      | NVARCHAR(255) | NO       | —         | —            | Dirección física                 |

---

### 2. CANALES_VENTAS
**Propósito:** Catálogo de canales por los que llegan pedidos.

| **Campo**  | **Tipo**    | **Nulo** | **Clave** | **Default**   | **Descripción**              |
|------------|-------------|----------|-----------|---------------|------------------------------|
| canal_id   | INT         | NO       | PK        | IDENTITY(1,1) | Identificador del canal      |
| nombre     | NVARCHAR(50)| NO       | UK        | —             | Nombre del canal de venta    |

**Valores iniciales:** Mostrador, Delivery, MESAS QR, Telefono

---

### 3. ESTADOS_PEDIDOS
**Propósito:** Estados del flujo operativo de pedidos.

| **Campo**  | **Tipo**    | **Nulo** | **Clave** | **Default**   | **Descripción**                  |
|------------|-------------|----------|-----------|---------------|----------------------------------|
| estado_id  | INT         | NO       | PK        | IDENTITY(1,1) | Identificador del estado         |
| nombre     | NVARCHAR(50)| NO       | UK        | —             | Nombre del estado                |
| orden      | INT         | NO       | UK        | —             | Orden secuencial del flujo       |

**Flujo:** Pendiente(1) → Confirmado(2) → En Preparación(3) → Listo(4) → En Reparto(5) → Entregado(6) → Cerrado(7) | Cancelado(99)

---

### 4. ROLES
**Propósito:** Roles del personal del bodegón.

| **Campo**   | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**          |
|-------------|---------------|----------|-----------|---------------|--------------------------|
| rol_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador del ROLES    |
| nombre      | NVARCHAR(50)  | NO       | UK        | —             | Nombre del ROLES           |
| descripcion | NVARCHAR(255) | SÍ       | —         | —             | Descripción del ROLES      |

**Valores iniciales:** Administrador, Gerente, Mozo, Cajero, Cocinero, Repartidor, Hostess

---

### 5. MESAS
**Propósito:** Mesas físicas del salón con soporte de QR.

| **Campo**   | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                     |
|-------------|---------------|----------|-----------|---------------|-------------------------------------|
| mesa_id     | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único de MESAS         |
| numero      | INT           | NO       | UK(comp.) | —             | Número de MESAS (único por SUCURSALES) |
| capacidad   | INT           | NO       | —         | —             | Cantidad máxima de comensales (>0)  |
| sucursal_id | INT           | NO       | FK        | —             | SUCURSALES a la que pertenece         |
| qr_token    | NVARCHAR(255) | NO       | UK        | —             | Token único del código QR           |
| activa      | BIT           | NO       | —         | 1             | Si la MESAS está habilitada          |

**Constraints:** `CHECK capacidad > 0` · `UNIQUE (numero, sucursal_id)`

---

### 6. EMPLEADOS
**Propósito:** Personal del bodegón con autenticación.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                    |
|----------------|---------------|----------|-----------|---------------|------------------------------------|
| empleado_id    | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del EMPLEADOS   |
| nombre         | NVARCHAR(100) | NO       | —         | —             | Nombre completo                    |
| usuario        | NVARCHAR(50)  | NO       | UK        | —             | Nombre de usuario (único global)   |
| hash_password  | NVARCHAR(255) | NO       | —         | —             | Contraseña hasheada                |
| rol_id         | INT           | NO       | FK        | —             | ROLES asignado                       |
| sucursal_id    | INT           | NO       | FK        | —             | SUCURSALES de pertenencia            |
| activo         | BIT           | NO       | —         | 1             | Si el EMPLEADOS está activo         |

---

### 7. CLIENTES
**Propósito:** Clientes registrados para delivery e historial.

| **Campo**  | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                     |
|------------|---------------|----------|-----------|---------------|-------------------------------------|
| cliente_id | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del CLIENTES     |
| nombre     | NVARCHAR(100) | NO       | —         | —             | Nombre completo del CLIENTES         |
| telefono   | NVARCHAR(20)  | SÍ       | —         | —             | Teléfono de contacto                |
| email      | NVARCHAR(100) | SÍ       | UIX       | —             | Email único (índice filtrado WHERE NOT NULL) |
| doc_tipo   | NVARCHAR(10)  | SÍ       | UIX(comp.)| —             | Tipo de documento (DNI, CUIL, etc.) |
| doc_nro    | NVARCHAR(20)  | SÍ       | UIX(comp.)| —             | Número de documento                 |

**Índices filtrados:**
- `UIX_CLIENTE_email` — unicidad de email solo cuando NOT NULL (permite múltiples clientes sin email)
- `UIX_CLIENTE_documento` — unicidad de `(doc_tipo, doc_nro)` solo cuando ambos NOT NULL

> **Nota de diseño:** Se usan índices filtrados en lugar de UNIQUE constraints convencionales porque SQL Server no admite UNIQUE sobre columnas nullable con múltiples NULLs. Ver `09 - Justificacion Decisiones Diseño.md` §3.

---

### 8. DOMICILIOS
**Propósito:** Direcciones de entrega vinculadas a clientes.

| **Campo**       | **Tipo**      | **Nulo** | **Clave** | **Default**     | **Descripción**                  |
|-----------------|---------------|----------|-----------|-----------------|----------------------------------|
| domicilio_id    | INT           | NO       | PK        | IDENTITY(1,1)   | Identificador único              |
| cliente_id      | INT           | NO       | FK        | —               | CLIENTES propietario              |
| calle           | NVARCHAR(100) | NO       | —         | —               | Nombre de la calle               |
| numero          | NVARCHAR(10)  | NO       | —         | —               | Número de puerta                 |
| piso            | NVARCHAR(10)  | SÍ       | —         | —               | Piso (opcional)                  |
| depto           | NVARCHAR(10)  | SÍ       | —         | —               | Departamento (opcional)          |
| localidad       | NVARCHAR(50)  | NO       | —         | —               | Localidad                        |
| provincia       | NVARCHAR(50)  | NO       | —         | —               | Provincia                        |
| observaciones   | NVARCHAR(255) | SÍ       | —         | —               | Notas de entrega (timbre, etc.)  |
| es_principal    | BIT           | NO       | UIX       | 0               | Si es el DOMICILIOS principal (solo uno por CLIENTES) |
| tipo_domicilio  | NVARCHAR(50)  | SÍ       | —         | 'Particular'    | Tipo de DOMICILIOS (mejora visual)|

**Constraints:** `CHECK tipo_domicilio IN ('Particular', 'Laboral', 'Temporal', 'Otro')`

**Índice filtrado:**
- `UIX_DOMICILIO_principal` — garantiza que solo existe UN domicilio principal (`es_principal = 1`) por cliente. Implementado como índice filtrado `WHERE es_principal = 1`.

**Valores permitidos para tipo_domicilio:**
- **Particular:** DOMICILIOS de residencia habitual del CLIENTES
- **Laboral:** Dirección del lugar de trabajo
- **Temporal:** Dirección de uso esporádico (casa de fin de semana, hotel, etc.)
- **Otro:** Cualquier otro tipo no categorizado

---

### 9. PLATOS
**Propósito:** Catálogo de ítems del menú del bodegón (entradas, pastas, carnes, bebidas, postres).

| **Campo**  | **Tipo**     | **Nulo** | **Clave** | **Default**   | **Descripción**                              |
|------------|--------------|----------|-----------|---------------|----------------------------------------------|
| plato_id   | INT          | NO       | PK        | IDENTITY(1,1) | Identificador único del producto/PLATOS        |
| nombre     | NVARCHAR(100)| NO       | UK        | —             | Nombre del PLATOS (único en el menú)          |
| categoria  | NVARCHAR(50) | NO       | —         | —             | Categoría del menú                           |
| activo     | BIT          | NO       | —         | 1             | Si el PLATOS está disponible en el menú       |

**Categorías del bodegón:** Entradas, Pastas, Carnes a la Leña, Guarniciones, Postres, Bebidas

---

### 10. PRECIOS
**Propósito:** Historial de precios con vigencia temporal por PLATOS.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                          |
|----------------|---------------|----------|-----------|---------------|------------------------------------------|
| precio_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del registro         |
| plato_id       | INT           | NO       | FK        | —             | PLATOS al que aplica el PRECIOS            |
| vigencia_desde | DATE          | NO       | —         | —             | Fecha de inicio de vigencia              |
| vigencia_hasta | DATE          | SÍ       | —         | —             | Fecha de fin (NULL = vigente hasta nuevo)|
| monto          | DECIMAL(10,2) | NO       | —         | —             | Precio en pesos argentinos (≥ 0)         |

**Constraints:** `CHECK monto >= 0` · `CHECK vigencia_hasta >= vigencia_desde`

---

#### 📋 DECISIÓN DE DISEÑO: PRECIOS como tabla separada

**RAZÓN PRINCIPAL: Auditoría de cambios de PRECIOS**

Cuando un PRECIOS cambia, **NO actualizamos el registro anterior**, sino que **insertamos uno nuevo** con nuevas fechas de vigencia. Esto preserva el historial completo de todos los cambios de PRECIOS para:
- ✅ **Auditoría financiera:** ¿Cuánto costaba el Bife de Chorizo el 15 de febrero de 2026?
- ✅ **Análisis de rentabilidad:** Evolución de precios vs. costos operativos
- ✅ **Reportes históricos:** Facturación por período con precios correctos del momento
- ✅ **Cumplimiento normativo:** Trazabilidad completa ante inspecciones fiscales

**Ejemplo real - Historial de 3 precios para Bife de Chorizo:**

```sql
-- PRECIOS Q1 2026
INSERT INTO PRECIOS (plato_id, vigencia_desde, vigencia_hasta, monto)
VALUES (5, '2026-01-01', '2026-03-31', 8500.00)

-- PRECIOS Q2 2026 (aumento del 8.2%)
INSERT INTO PRECIOS (plato_id, vigencia_desde, vigencia_hasta, monto)
VALUES (5, '2026-04-01', '2026-06-30', 9200.00)

-- PRECIOS Q3 2026 en adelante (aumento del 6.5%)
INSERT INTO PRECIOS (plato_id, vigencia_desde, vigencia_hasta, monto)
VALUES (5, '2026-07-01', NULL, 9800.00)
```

✅ **Resultado:** Los 3 registros se conservan permanentemente. El sistema consulta automáticamente cuál PRECIOS aplicar según `GETDATE()` entre las fechas de vigencia.

**BENEFICIO SECUNDARIO: Precios temporales diferenciados**

La misma estructura permite gestionar precios por contexto temporal:
- **Precios de fin de semana:** Mayor costo viernes-domingo
- **Precios especiales en feriados:** Tarifa diferenciada
- **Precios programados futuros:** Se registran hoy, se aplican automáticamente en la fecha configurada

**Alternativa descartada:** Integrar PRECIOS directamente en tabla PLATOS
- ❌ Pierde historial al actualizar
- ❌ No permite auditoría de cambios
- ❌ Imposible reconstruir facturación histórica con precios correctos
- ❌ Sin trazabilidad para análisis financiero

> **Ver también:** Documento `09 - Justificacion Decisiones Diseño.md` §2 para análisis técnico completo.

---

### 11. PEDIDOS
**Propósito:** Entidad central. Registra cada transacción del bodegón.

| **Campo**                 | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                          |
|---------------------------|---------------|----------|-----------|---------------|------------------------------------------|
| pedido_id                 | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del PEDIDOS           |
| fecha_pedido              | DATETIME      | NO       | —         | GETDATE()     | Fecha y hora de creación                 |
| fecha_entrega             | DATETIME      | SÍ       | —         | —             | Fecha y hora de entrega (delivery)       |
| canal_id                  | INT           | NO       | FK        | —             | Canal de venta                           |
| mesa_id                   | INT           | SÍ       | FK        | —             | MESAS asignada (solo canal MESAS QR)       |
| cliente_id                | INT           | SÍ       | FK        | —             | CLIENTES (delivery o registrado)          |
| domicilio_id              | INT           | SÍ       | FK        | —             | DOMICILIOS de entrega (solo delivery)     |
| cant_comensales           | INT           | SÍ       | —         | —             | Número de comensales en MESAS             |
| estado_id                 | INT           | NO       | FK        | —             | Estado actual del PEDIDOS                 |
| tomado_por_empleado_id    | INT           | NO       | FK        | —             | EMPLEADOS que tomó el PEDIDOS              |
| entregado_por_empleado_id | INT           | SÍ       | FK        | —             | EMPLEADOS que entregó (delivery)          |
| total                     | DECIMAL(10,2) | NO       | —         | 0             | Total del PEDIDOS (calculado por trigger) |
| observaciones             | NVARCHAR(500) | SÍ       | —         | —             | Notas especiales del PEDIDOS              |

---

### 12. DETALLES_PEDIDOS
**Propósito:** Líneas de PEDIDOS. Cada registro = un ítem (PLATOS) dentro de un PEDIDOS.

> `plato_id` es siempre obligatorio — cada línea de PEDIDOS referencia un PLATOS individual.

| **Campo**       | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                         |
|-----------------|---------------|----------|-----------|---------------|-----------------------------------------|
| detalle_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único de la línea         |
| pedido_id       | INT           | NO       | FK        | —             | PEDIDOS al que pertenece                 |
| plato_id        | INT           | NO       | FK        | —             | PLATOS PEDIDOS (siempre obligatorio)      |
| cantidad        | INT           | NO       | —         | —             | Cantidad pedida (> 0)                   |
| precio_unitario | DECIMAL(10,2) | NO       | —         | —             | PRECIOS al momento del PEDIDOS (≥ 0)      |
| subtotal        | DECIMAL(10,2) | NO       | —         | —             | cantidad × precio_unitario (≥ 0)        |

**Constraints:** `CHECK cantidad > 0` · `CHECK precio_unitario >= 0` · `CHECK subtotal >= 0`

---

## **TABLAS AUXILIARES (creadas por Bundles E1/E2/R1)**

### AUDITORIAS_SIMPLES (Bundle E1)
Log simplificado generado por `tr_AuditoriaPedidos` y `tr_AuditoriaDetalle`.

| **Campo**        | **Tipo**      | **Descripción**                        |
|------------------|---------------|----------------------------------------|
| auditoria_id     | INT PK        | Identificador                          |
| tabla_afectada   | NVARCHAR(50)  | Tabla modificada                       |
| registro_id      | INT           | ID del registro afectado               |
| accion           | VARCHAR(20)   | INSERT / UPDATE / DELETE               |
| fecha_auditoria  | DATETIME      | Timestamp (DEFAULT GETDATE())          |
| usuario_sistema  | VARCHAR(128)  | Usuario SQL (DEFAULT SYSTEM_USER)      |
| datos_resumen    | NVARCHAR(500) | Resumen legible del cambio             |

### STOCKS_SIMULADOS (Bundle E2)
Inventario simulado por PLATOS, gestionado por `tr_ValidarStock`.

| **Campo**           | **Tipo** | **Descripción**                     |
|---------------------|----------|-------------------------------------|
| plato_id            | INT PK/FK| PLATOS (referencia a PLATOS)          |
| stock_disponible    | INT      | Unidades disponibles (DEFAULT 100)  |
| stock_minimo        | INT      | Umbral de alerta (DEFAULT 10)       |
| ultima_actualizacion| DATETIME | Última modificación                 |

---

#### 📋 DECISIÓN DE DISEÑO: STOCKS_SIMULADOS como tabla separada (relación 1:0..1 con PLATOS)

**RAZÓN PRINCIPAL: Separación de Responsabilidades (SRP - Single Responsibility Principle)**

La tabla `PLATOS` y la tabla `STOCKS_SIMULADOS` tienen responsabilidades completamente diferentes:

**PLATOS: Catálogo Permanente del Negocio**
- **Propósito:** Define QUÉ vende el bodegón
- **Estabilidad:** Los platos cambian raramente (agregar/quitar del menú)
- **Naturaleza:** Información de negocio permanente y estructural
- **Ejemplo:** "Bife de Chorizo" existe como concepto independiente del inventario

**STOCKS_SIMULADOS: Control Operativo Temporal**
- **Propósito:** Controla CUÁNTO hay disponible en este momento
- **Volatilidad:** Cambia con cada PEDIDOS (triggers automáticos)
- **Naturaleza:** Información operativa temporal y variable
- **Ejemplo:** "Quedan 45 unidades de Bife de Chorizo" cambia constantemente

**Ventajas de la separación:**

1. **Modularidad del sistema:**
   - El bodegón puede operar en "modo catálogo puro" sin control de stock
   - Se puede activar/desactivar el inventario simplemente agregando/quitando `STOCKS_SIMULADOS`
   - La estructura core del sistema (PLATOS → PEDIDOS → DETALLES_PEDIDOS) funciona independientemente

2. **Extensibilidad futura sin modificar estructura core:**
   - **Hoy:** Stock global por PLATOS
   - **Futuro cercano:** Stock por SUCURSALES → Agregar `sucursal_id` a PK de `STOCKS_SIMULADOS`
   - **Futuro avanzado:** Stock por lote con vencimiento → Agregar `lote_id`, `fecha_vencimiento`
   - **PLATOS nunca se toca:** Todas las evoluciones ocurren en `STOCKS_SIMULADOS`

3. **Performance en consultas:**
   - Consultar menú (80% de queries): No carga datos de stock innecesarios
   - Validar stock (20% de queries, solo cocina): JOIN específico cuando se necesita

4. **Auditoría diferenciada:**
   - Cambios en `PLATOS` (raros, críticos) → Notificación a gerencia
   - Cambios en `STOCKS_SIMULADOS` (frecuentes, operativos) → Log automático por trigger

**Alternativa descartada:** Integrar campos de stock directamente en PLATOS
```sql
-- ❌ Opción rechazada
CREATE TABLE PLATOS (
    plato_id INT PRIMARY KEY,
    nombre NVARCHAR(100),
    stock_disponible INT NULL,  -- ⚠️ Mezcla catálogo con operaciones
    stock_minimo INT NULL        -- ⚠️ Dificulta extensibilidad futura
)
```

**Problemas de esta alternativa:**
- ❌ Ambigüedad semántica: ¿NULL significa "sin control de stock" o "stock agotado"?
- ❌ Mezcla de responsabilidades: Catálogo + operaciones en una sola tabla
- ❌ Dificulta extensibilidad: Stock por SUCURSALES requiere refactorización completa de PLATOS
- ❌ Triggers afectan tabla principal: Cada PEDIDOS dispara UPDATE en tabla core del negocio

**Conclusión:** La separación NO viola la Tercera Forma Normal porque está **funcionalmente justificada** por principios de diseño de software (SRP, modularidad, extensibilidad).

> **Ver también:** Documento `09 - Justificacion Decisiones Diseño.md` §1 para análisis técnico completo con ejemplos de escalabilidad.

### NOTIFICACIONES (Bundle E2)
Alertas automáticas generadas por `tr_SistemaNotificaciones`.

| **Campo**       | **Tipo**      | **Descripción**                            |
|-----------------|---------------|--------------------------------------------|
| notificacion_id | INT PK        | Identificador                              |
| tipo            | VARCHAR(50)   | PEDIDO_LISTO / PEDIDO_CERRADO / etc.       |
| titulo          | NVARCHAR(200) | Título de la notificación                  |
| mensaje         | NVARCHAR(500) | Cuerpo del mensaje                         |
| pedido_id       | INT NULL      | PEDIDOS relacionado (referencia lógica)     |
| mesa_id         | INT NULL      | MESAS relacionada (referencia lógica)       |
| prioridad       | VARCHAR(20)   | BAJA / NORMAL / ALTA / CRITICA             |
| fecha_creacion  | DATETIME      | Timestamp de creación                      |
| leida           | BIT           | Si fue leída (DEFAULT 0)                   |
| fecha_lectura   | DATETIME NULL | Cuándo fue leída                           |
| usuario_destino | VARCHAR(100)  | Destinatario (MOZOS / CAJA / etc.)         |

### REPORTES_GENERADOS (Bundle R1)
Registro de reportes generados por los Stored Procedures de reporting.

| **Campo**        | **Tipo**       | **Descripción**                           |
|------------------|----------------|-------------------------------------------|
| reporte_id       | INT PK         | Identificador                             |
| tipo_reporte     | NVARCHAR(50)   | Tipo: VENTAS_DIARIO, PLATO_POPULAR, etc. |
| fecha_generacion | DATETIME       | Timestamp de ejecución (DEFAULT GETDATE())|
| fecha_reporte    | DATE           | Fecha del período reportado               |
| sucursal_id      | INT NULL FK    | SUCURSALES (referencia a SUCURSALES)          |
| datos_json       | NVARCHAR(MAX)  | Resultados del reporte en JSON            |
| ejecutado_por    | NVARCHAR(100)  | Usuario que ejecutó (DEFAULT SYSTEM_USER) |
| estado           | NVARCHAR(20)   | Estado del reporte (DEFAULT 'COMPLETADO') |
| observaciones    | NVARCHAR(500)  | Notas adicionales                         |

---

## **ÍNDICES IMPLEMENTADOS**

| **Índice**                    | **Tabla**         | **Columnas**                        | **Tipo**                  | **Propósito**                         |
|-------------------------------|-------------------|-------------------------------------|---------------------------|---------------------------------------|
| IX_PEDIDO_fecha_estado        | PEDIDOS           | fecha_pedido, estado_id             | Non-clustered             | Reportes de ventas diarias            |
| IX_PEDIDO_mesa                | PEDIDOS           | mesa_id (filtrado NOT NULL)         | Non-clustered             | Lookup por MESAS en servicio de salón  |
| IX_PEDIDO_cliente             | PEDIDOS           | cliente_id (filtrado NOT NULL)      | Non-clustered             | Historial de CLIENTES / delivery       |
| IX_DETALLE_PEDIDO_pedido      | DETALLES_PEDIDOS  | pedido_id                           | Non-clustered             | JOIN principal detalle→PEDIDOS         |
| IX_DETALLE_PEDIDO_plato       | DETALLES_PEDIDOS  | plato_id                            | Non-clustered             | Ranking de productos populares        |
| IX_MESA_sucursal_activa       | MESAS             | sucursal_id, activa                 | Non-clustered             | Mesas activas por SUCURSALES            |
| IX_EMPLEADO_sucursal_activo   | EMPLEADOS         | sucursal_id, activo                 | Non-clustered             | Empleados activos por SUCURSALES        |
| IX_PRECIO_plato_vigencia      | PRECIOS           | plato_id, vigencia_desde, hasta     | Non-clustered             | Precio vigente (evita table scan)     |
| UIX_CLIENTE_email             | CLIENTES          | email WHERE NOT NULL                | Unique Non-clustered (filtrado) | Unicidad de email en clientes registrados |
| UIX_CLIENTE_documento         | CLIENTES          | doc_tipo, doc_nro WHERE ambos NOT NULL | Unique Non-clustered (filtrado) | Unicidad de documento sin restringir NULLs |
| UIX_DOMICILIO_principal       | DOMICILIOS        | cliente_id WHERE es_principal = 1   | Unique Non-clustered (filtrado) | Máximo un domicilio principal por cliente |

> **Total:** 11 índices non-clustered (8 de performance + 3 de unicidad filtrada)

---

**Documento generado por SQLeaders S.A.**  
**Versión: 1.0 — Adaptación EsbirrosDB — 2026**
