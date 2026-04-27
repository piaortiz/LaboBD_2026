# REGLAS DEL NEGOCIO — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                |
|-----------------|------------------------------------------------|
| **Documento**   | Reglas del Negocio — EsbirrosDB               |
| **Proyecto**    | Sistema de Gestión de Bodegón Porteño          |
| **CLIENTES**     | Bodegón Los Esbirros de Claudio                |
| **Instituto**   | ISTEA                                          |
| **Materia**     | Laboratorio de Administración de Bases de Datos |
| **Profesor**    | Carlos Alejandro Caraccio                      |
| **Versión**     | 1.0                                            |
| **Estado**      | Implementado y Funcional                       |

## **RESUMEN EJECUTIVO**

### Objetivo del Documento
Establece las reglas de negocio del sistema **EsbirrosDB**, definiendo las políticas operativas, restricciones funcionales y validaciones automáticas para el **Bodegón Los Esbirros de Claudio** (cocina a la leña, pastas, carnes y bebidas).

### Decisiones de Diseño
- **Detalle de PEDIDOS simplificado** — `plato_id NOT NULL`, cada ítem referencia un PLATOS individual
- **Contexto bodón porteño** — roles y flujos adaptados al negocio gastronómico argentino

---

## **REGLAS ORGANIZACIONALES**

### RN-001: Gestión de Personal

| **Código**    | **Regla**                                            | **Implementación**                        |
|---------------|------------------------------------------------------|-------------------------------------------|
| **RN-001.1**  | Un EMPLEADOS pertenece a una única SUCURSALES           | FK obligatoria `EMPLEADOS.sucursal_id`     |
| **RN-001.2**  | Un EMPLEADOS debe tener ROLES asignado                  | FK obligatoria `EMPLEADOS.rol_id`          |
| **RN-001.3**  | El usuario debe ser único en el sistema              | `UNIQUE` constraint en `EMPLEADOS.usuario` |
| **RN-001.4**  | Solo empleados activos pueden tomar pedidos          | Validación en `sp_CrearPedido`            |
| **RN-001.5**  | La contraseña se almacena hasheada                   | Campo `hash_password`, nunca texto plano  |

### RN-002: Gestión de Sucursales y Mesas

| **Código**    | **Regla**                                            | **Implementación**                                   |
|---------------|------------------------------------------------------|------------------------------------------------------|
| **RN-002.1**  | Cada SUCURSALES tiene nombre único                     | `UNIQUE` en `SUCURSALES.nombre`                        |
| **RN-002.2**  | Las mesas pertenecen a una única SUCURSALES            | FK obligatoria `MESAS.sucursal_id`                    |
| **RN-002.3**  | Número de MESAS único por SUCURSALES                   | `UNIQUE (numero, sucursal_id)`                       |
| **RN-002.4**  | Cada MESAS tiene código QR único                     | `UNIQUE` en `MESAS.qr_token`                          |
| **RN-002.5**  | La capacidad de MESAS debe ser positiva               | `CHECK capacidad > 0`                                |

---

## **REGLAS DE PRODUCTOS Y PRECIOS**

### RN-003: Catálogo de Productos (Menú del Bodegón)

| **Código**    | **Regla**                                             | **Implementación**                      |
|---------------|-------------------------------------------------------|-----------------------------------------|
| **RN-003.1**  | Cada PLATOS/producto tiene nombre único                | `UNIQUE` en `PLATOS.nombre`              |
| **RN-003.2**  | Solo platos activos pueden venderse                   | Validación en `sp_AgregarItemPedido`    |
| **RN-003.3**  | Todo producto debe tener una categoría                | `PLATOS.categoria NOT NULL`              |
| **RN-003.4**  | Categorías válidas del menú                           | Entradas, Pastas, Carnes a la Leña, Guarniciones, Postres, Bebidas |

### RN-004: Gestión de Precios

| **Código**    | **Regla**                                             | **Implementación**                                   |
|---------------|-------------------------------------------------------|------------------------------------------------------|
| **RN-004.1**  | Los precios no pueden ser negativos                   | `CHECK monto >= 0`                                   |
| **RN-004.2**  | Todo PRECIOS debe tener fecha de inicio                | `PRECIOS.vigencia_desde NOT NULL`                    |
| **RN-004.3**  | Fecha de fin debe ser posterior al inicio             | `CHECK vigencia_hasta >= vigencia_desde`              |
| **RN-004.4**  | Se mantiene histórico de precios                      | No se eliminan registros de `PRECIOS`                 |
| **RN-004.5**  | El sistema toma el monto más reciente vigente          | `sp_AgregarItemPedido` → `TOP 1 monto ORDER BY vigencia_desde DESC` |
| **RN-004.6**  | Al cambiar precio se inserta nuevo registro, no se actualiza el anterior | Política de auditoría: `INSERT` con nueva vigencia, preserva histórico completo |

#### 📋 Detalle RN-004.6: Política de Auditoría de Precios

**Regla crítica:** Cuando el PRECIOS de un PLATOS cambia, el sistema **NO actualiza** el registro existente en la tabla `PRECIOS`. En su lugar, **inserta un nuevo registro** con las nuevas fechas de vigencia.

**Razón:** Preservar trazabilidad completa de todos los cambios de PRECIOS para:
- Auditoría financiera y cumplimiento normativo
- Análisis de rentabilidad histórica
- Reconstrucción de facturación por período con precios correctos
- Reportes gerenciales comparativos

**Ejemplo de implementación:**
```sql
-- ❌ INCORRECTO: Actualizar precio existente
UPDATE PRECIOS 
SET monto = 9200.00, vigencia_hasta = NULL 
WHERE plato_id = 5 AND vigencia_hasta IS NULL

-- ✅ CORRECTO: Cerrar vigencia anterior e insertar nuevo registro
UPDATE PRECIOS 
SET vigencia_hasta = '2026-03-31' 
WHERE plato_id = 5 AND vigencia_hasta IS NULL

INSERT INTO PRECIOS (plato_id, vigencia_desde, vigencia_hasta, monto)
VALUES (5, '2026-04-01', NULL, 9200.00)
```

**Resultado:** El sistema mantiene ambos registros permanentemente, permitiendo consultar "¿Cuánto costaba el Bife de Chorizo el 15 de febrero de 2026?" en cualquier momento futuro.

> **Ver también:** Documento `02 - Diccionario de Datos.md` §10 y `09 - Justificacion Decisiones Diseño.md` §2 para análisis completo.

---

## **REGLAS DE PEDIDOS Y VENTAS**

### RN-005: Creación de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                              |
|---------------|--------------------------------------------------------|-------------------------------------------------|
| **RN-005.1**  | Todo PEDIDOS debe tener canal de venta                  | FK obligatoria `PEDIDOS.canal_id`                |
| **RN-005.2**  | Todo PEDIDOS debe tener EMPLEADOS responsable            | FK obligatoria `PEDIDOS.tomado_por_empleado_id`  |
| **RN-005.3**  | Todo PEDIDOS inicia en estado "Pendiente"               | Asignación automática en `sp_CrearPedido`       |
| **RN-005.4**  | Pedidos de MESAS requieren MESAS asignada                | Validación condicional por canal                |
| **RN-005.5**  | Pedidos delivery requieren CLIENTES y DOMICILIOS         | Validación condicional por canal                |

### RN-006: Estados de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-006.1**  | Los estados siguen orden secuencial                    | Campo `ESTADOS_PEDIDOS.orden`                          |
| **RN-006.2**  | Solo se puede avanzar al siguiente estado              | Validación en `sp_ActualizarEstadoPedido`            |
| **RN-006.3**  | Estados únicos con nombres únicos                      | `UNIQUE` en `nombre` y `orden`                       |
| **RN-006.4**  | Pedidos entregados requieren EMPLEADOS de entrega       | Validación en transición a "Entregado"               |
| **RN-006.5**  | Cambios de estado se auditan automáticamente           | Trigger `tr_AuditoriaPedidos`                        |

### RN-007: Detalles de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-007.1**  | Cada línea de PEDIDOS debe referenciar un PLATOS         | `plato_id NOT NULL` en `DETALLES_PEDIDOS`              |
| **RN-007.2**  | Las cantidades deben ser positivas                     | `CHECK cantidad > 0`                                 |
| **RN-007.3**  | Los precios unitarios no pueden ser negativos          | `CHECK precio_unitario >= 0`                         |
| **RN-007.4**  | Los subtotales no pueden ser negativos                 | `CHECK subtotal >= 0`                                |
| **RN-007.5**  | El subtotal = cantidad × precio_unitario               | Calculado en `sp_AgregarItemPedido`                  |

> `plato_id` es siempre obligatorio — cada línea de PEDIDOS referencia un PLATOS individual del menú.

---

## **REGLAS DE CLIENTES Y DELIVERY**

### RN-008: Gestión de Clientes

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-008.1**  | El email debe ser único si se proporciona              | Índice filtrado `UIX_CLIENTE_email` (`WHERE email IS NOT NULL`) |
| **RN-008.2**  | La combinación tipo+número de documento es única       | Índice filtrado `UIX_CLIENTE_documento` (`WHERE doc_tipo IS NOT NULL AND doc_nro IS NOT NULL`) |
| **RN-008.3**  | Todo CLIENTES debe tener nombre                         | `CLIENTES.nombre NOT NULL`                            |
| **RN-008.4**  | Los datos de contacto son opcionales                   | Campos `NULL` permitidos                             |
| **RN-008.5**  | Un CLIENTES puede tener múltiples domicilios            | Relación 1:N `CLIENTES → DOMICILIOS`                  |

> **Nota técnica:** Se usan índices únicos filtrados (UIX) en lugar de constraints UNIQUE convencionales porque SQL Server no permite múltiples valores NULL en una columna con UNIQUE constraint. Los índices filtrados con `WHERE IS NOT NULL` garantizan unicidad solo sobre valores reales, permitiendo N clientes sin email registrado.

### RN-009: Domicilios de Entrega

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-009.1**  | Todo DOMICILIOS pertenece a un CLIENTES                  | FK obligatoria `DOMICILIOS.cliente_id`                |
| **RN-009.2**  | Calle y número son obligatorios                        | `NOT NULL`                                           |
| **RN-009.3**  | Localidad y provincia son obligatorias                 | `NOT NULL`                                           |
| **RN-009.4**  | Piso y departamento son opcionales                     | Campos `NULL`                                        |
| **RN-009.5**  | Un CLIENTES puede marcar DOMICILIOS principal            | Campo `DOMICILIOS.es_principal BIT`                   |
| **RN-009.6**  | El tipo de DOMICILIOS debe ser válido                   | `CHECK` constraint con valores permitidos            |
| **RN-009.7**  | Solo puede haber **un** domicilio principal por CLIENTES | Índice filtrado `UIX_DOMICILIO_principal` (`WHERE es_principal = 1`) |

**Valores permitidos para tipo_domicilio:**
- **Particular:** DOMICILIOS de residencia habitual del CLIENTES
- **Laboral:** Dirección del lugar de trabajo
- **Temporal:** Casa de fin de semana, hotel, dirección esporádica
- **Otro:** Cualquier otra categoría no contemplada

> **Mejora post-presentación:** El campo `tipo_domicilio` fue agregado tras sugerencia del profesor para mejorar la identificación visual del propósito de cada dirección.

---

## **REGLAS DE AUDITORÍA Y SEGURIDAD**

### RN-010: Trazabilidad

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-010.1**  | Todos los pedidos se auditan automáticamente           | Trigger `tr_AuditoriaPedidos` sobre `PEDIDOS`         |
| **RN-010.2**  | Los cambios de estado se registran                     | Campo `AUDITORIAS_SIMPLES.accion`                      |
| **RN-010.3**  | Se registra el usuario de cada cambio                  | `AUDITORIAS_SIMPLES.usuario_sistema NOT NULL`          |
| **RN-010.4**  | Fecha automática en cada registro de auditoría         | `DEFAULT GETDATE()`                                  |
| **RN-010.5**  | Los datos del cambio se preservan en resumen           | Campo `AUDITORIAS_SIMPLES.datos_resumen NVARCHAR(500)` |

### RN-011: Integridad del Sistema

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-011.1**  | No se permiten eliminaciones en cascada en FK críticas | `RESTRICT` en Foreign Keys                           |
| **RN-011.2**  | Los totales se calculan automáticamente                | Trigger `tr_ActualizarTotales`                       |
| **RN-011.3**  | Las fechas de PEDIDOS se asignan automáticamente        | `DEFAULT GETDATE()` en `PEDIDOS.fecha_pedido`         |
| **RN-011.4**  | Solo empleados de la misma SUCURSALES atienden mesas     | Validación cruzada en `sp_CrearPedido`               |
| **RN-011.5**  | Los históricos de precios nunca se eliminan            | Política de retención de datos                       |

---

## **VALIDACIONES IMPLEMENTADAS**

### Integridad Referencial
- **17 Foreign Keys** garantizan consistencia entre tablas
- Validaciones cruzadas SUCURSALES/EMPLEADOS/MESAS en stored procedures

### Validaciones de Dominio
- `CHECK` constraints para valores positivos y lógicos
- Índices únicos filtrados (UIX) para columnas nullable con unicidad condicional
- `UNIQUE` constraints para catálogos con valores siempre presentes

### Validaciones de Negocio (Stored Procedures)
- `sp_CrearPedido` — validación completa de canal, EMPLEADOS, MESAS, CLIENTES
- `sp_AgregarItemPedido` — validación de PLATOS activo y PRECIOS vigente
- `sp_CalcularTotalPedido` — recálculo de totales
- `sp_CerrarPedido` / `sp_CancelarPedido` — transiciones de estado

---

**Documento generado por SQLeaders S.A.**  
**Versión: 1.0 — Adaptación EsbirrosDB — 2026**
