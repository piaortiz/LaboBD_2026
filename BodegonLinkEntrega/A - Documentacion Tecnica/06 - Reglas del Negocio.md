# REGLAS DEL NEGOCIO — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                |
|-----------------|------------------------------------------------|
| **Documento**   | Reglas del Negocio — EsbirrosDB               |
| **Proyecto**    | Sistema de Gestión de Bodegón Porteño          |
| **Cliente**     | Bodegón Los Esbirros de Claudio                |
| **Instituto**   | ISTEA                                          |
| **Versión**     | 2.0                                            |
| **Estado**      | Implementado y Funcional                       |

## **RESUMEN EJECUTIVO**

### Objetivo del Documento
Establece las reglas de negocio del sistema **EsbirrosDB**, definiendo las políticas operativas, restricciones funcionales y validaciones automáticas para el **Bodegón Los Esbirros de Claudio** (cocina a la leña, pastas, carnes y bebidas).

### Decisiones de Diseño
- **Detalle de pedido simplificado** — `plato_id NOT NULL`, cada ítem referencia un plato individual
- **Contexto bodón porteño** — roles y flujos adaptados al negocio gastronómico argentino

---

## **REGLAS ORGANIZACIONALES**

### RN-001: Gestión de Personal

| **Código**    | **Regla**                                            | **Implementación**                        |
|---------------|------------------------------------------------------|-------------------------------------------|
| **RN-001.1**  | Un empleado pertenece a una única sucursal           | FK obligatoria `EMPLEADO.sucursal_id`     |
| **RN-001.2**  | Un empleado debe tener rol asignado                  | FK obligatoria `EMPLEADO.rol_id`          |
| **RN-001.3**  | El usuario debe ser único en el sistema              | `UNIQUE` constraint en `EMPLEADO.usuario` |
| **RN-001.4**  | Solo empleados activos pueden tomar pedidos          | Validación en `sp_CrearPedido`            |
| **RN-001.5**  | La contraseña se almacena hasheada                   | Campo `hash_password`, nunca texto plano  |

### RN-002: Gestión de Sucursales y Mesas

| **Código**    | **Regla**                                            | **Implementación**                                   |
|---------------|------------------------------------------------------|------------------------------------------------------|
| **RN-002.1**  | Cada sucursal tiene nombre único                     | `UNIQUE` en `SUCURSAL.nombre`                        |
| **RN-002.2**  | Las mesas pertenecen a una única sucursal            | FK obligatoria `MESA.sucursal_id`                    |
| **RN-002.3**  | Número de mesa único por sucursal                   | `UNIQUE (numero, sucursal_id)`                       |
| **RN-002.4**  | Cada mesa tiene código QR único                     | `UNIQUE` en `MESA.qr_token`                          |
| **RN-002.5**  | La capacidad de mesa debe ser positiva               | `CHECK capacidad > 0`                                |

---

## **REGLAS DE PRODUCTOS Y PRECIOS**

### RN-003: Catálogo de Productos (Menú del Bodegón)

| **Código**    | **Regla**                                             | **Implementación**                      |
|---------------|-------------------------------------------------------|-----------------------------------------|
| **RN-003.1**  | Cada plato/producto tiene nombre único                | `UNIQUE` en `PLATO.nombre`              |
| **RN-003.2**  | Solo platos activos pueden venderse                   | Validación en `sp_AgregarItemPedido`    |
| **RN-003.3**  | Todo producto debe tener una categoría                | `PLATO.categoria NOT NULL`              |
| **RN-003.4**  | Categorías válidas del menú                           | Entradas, Pastas, Carnes a la Leña, Guarniciones, Postres, Bebidas |

### RN-004: Gestión de Precios

| **Código**    | **Regla**                                             | **Implementación**                                   |
|---------------|-------------------------------------------------------|------------------------------------------------------|
| **RN-004.1**  | Los precios no pueden ser negativos                   | `CHECK precio >= 0`                                  |
| **RN-004.2**  | Todo precio debe tener fecha de inicio                | `PRECIO.vigencia_desde NOT NULL`                     |
| **RN-004.3**  | Fecha de fin debe ser posterior al inicio             | `CHECK vigencia_hasta >= vigencia_desde`              |
| **RN-004.4**  | Se mantiene histórico de precios                      | No se eliminan registros de `PRECIO`                 |
| **RN-004.5**  | El sistema toma el precio más reciente vigente        | `sp_AgregarItemPedido` → `TOP 1 ORDER BY vigencia_desde DESC` |

---

## **REGLAS DE PEDIDOS Y VENTAS**

### RN-005: Creación de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                              |
|---------------|--------------------------------------------------------|-------------------------------------------------|
| **RN-005.1**  | Todo pedido debe tener canal de venta                  | FK obligatoria `PEDIDO.canal_id`                |
| **RN-005.2**  | Todo pedido debe tener empleado responsable            | FK obligatoria `PEDIDO.tomado_por_empleado_id`  |
| **RN-005.3**  | Todo pedido inicia en estado "Pendiente"               | Asignación automática en `sp_CrearPedido`       |
| **RN-005.4**  | Pedidos de mesa requieren mesa asignada                | Validación condicional por canal                |
| **RN-005.5**  | Pedidos delivery requieren cliente y domicilio         | Validación condicional por canal                |

### RN-006: Estados de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-006.1**  | Los estados siguen orden secuencial                    | Campo `ESTADO_PEDIDO.orden`                          |
| **RN-006.2**  | Solo se puede avanzar al siguiente estado              | Validación en `sp_ActualizarEstadoPedido`            |
| **RN-006.3**  | Estados únicos con nombres únicos                      | `UNIQUE` en `nombre` y `orden`                       |
| **RN-006.4**  | Pedidos entregados requieren empleado de entrega       | Validación en transición a "Entregado"               |
| **RN-006.5**  | Cambios de estado se auditan automáticamente           | Trigger `tr_AuditoriaPedidos`                        |

### RN-007: Detalles de Pedidos

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-007.1**  | Cada línea de pedido debe referenciar un plato         | `plato_id NOT NULL` en `DETALLE_PEDIDO`              |
| **RN-007.2**  | Las cantidades deben ser positivas                     | `CHECK cantidad > 0`                                 |
| **RN-007.3**  | Los precios unitarios no pueden ser negativos          | `CHECK precio_unitario >= 0`                         |
| **RN-007.4**  | Los subtotales no pueden ser negativos                 | `CHECK subtotal >= 0`                                |
| **RN-007.5**  | El subtotal = cantidad × precio_unitario               | Calculado en `sp_AgregarItemPedido`                  |

> `plato_id` es siempre obligatorio — cada línea de pedido referencia un plato individual del menú.

---

## **REGLAS DE CLIENTES Y DELIVERY**

### RN-008: Gestión de Clientes

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-008.1**  | El email debe ser único si se proporciona              | `UNIQUE` en `CLIENTE.email`                          |
| **RN-008.2**  | La combinación tipo+número de documento es única       | `UNIQUE (doc_tipo, doc_nro)`                         |
| **RN-008.3**  | Todo cliente debe tener nombre                         | `CLIENTE.nombre NOT NULL`                            |
| **RN-008.4**  | Los datos de contacto son opcionales                   | Campos `NULL` permitidos                             |
| **RN-008.5**  | Un cliente puede tener múltiples domicilios            | Relación 1:N `CLIENTE → DOMICILIO`                   |

### RN-009: Domicilios de Entrega

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-009.1**  | Todo domicilio pertenece a un cliente                  | FK obligatoria `DOMICILIO.cliente_id`                |
| **RN-009.2**  | Calle y número son obligatorios                        | `NOT NULL`                                           |
| **RN-009.3**  | Localidad y provincia son obligatorias                 | `NOT NULL`                                           |
| **RN-009.4**  | Piso y departamento son opcionales                     | Campos `NULL`                                        |
| **RN-009.5**  | Un cliente puede marcar domicilio principal            | Campo `DOMICILIO.es_principal BIT`                   |

---

## **REGLAS DE AUDITORÍA Y SEGURIDAD**

### RN-010: Trazabilidad

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-010.1**  | Todos los pedidos se auditan automáticamente           | Trigger `tr_AuditoriaPedidos` sobre `PEDIDO`         |
| **RN-010.2**  | Los cambios de estado se registran                     | Campo `AUDITORIA_SIMPLE.accion`                      |
| **RN-010.3**  | Se registra el usuario de cada cambio                  | `AUDITORIA_SIMPLE.usuario_sistema NOT NULL`          |
| **RN-010.4**  | Fecha automática en cada registro de auditoría         | `DEFAULT GETDATE()`                                  |
| **RN-010.5**  | Los datos del cambio se preservan en resumen           | Campo `AUDITORIA_SIMPLE.datos_resumen NVARCHAR(500)` |

### RN-011: Integridad del Sistema

| **Código**    | **Regla**                                              | **Implementación**                                   |
|---------------|--------------------------------------------------------|------------------------------------------------------|
| **RN-011.1**  | No se permiten eliminaciones en cascada en FK críticas | `RESTRICT` en Foreign Keys                           |
| **RN-011.2**  | Los totales se calculan automáticamente                | Trigger `tr_ActualizarTotales`                       |
| **RN-011.3**  | Las fechas de pedido se asignan automáticamente        | `DEFAULT GETDATE()` en `PEDIDO.fecha_pedido`         |
| **RN-011.4**  | Solo empleados de la misma sucursal atienden mesas     | Validación cruzada en `sp_CrearPedido`               |
| **RN-011.5**  | Los históricos de precios nunca se eliminan            | Política de retención de datos                       |

---

## **VALIDACIONES IMPLEMENTADAS**

### Integridad Referencial
- **17 Foreign Keys** garantizan consistencia entre tablas
- Validaciones cruzadas sucursal/empleado/mesa en stored procedures

### Validaciones de Dominio
- `CHECK` constraints para valores positivos y lógicos
- `UNIQUE` constraints para evitar duplicados en catálogos

### Validaciones de Negocio (Stored Procedures)
- `sp_CrearPedido` — validación completa de canal, empleado, mesa, cliente
- `sp_AgregarItemPedido` — validación de plato activo y precio vigente
- `sp_CalcularTotalPedido` — recálculo de totales
- `sp_CerrarPedido` / `sp_CancelarPedido` — transiciones de estado

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — Adaptación EsbirrosDB — 2026**
