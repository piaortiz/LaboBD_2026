# DICCIONARIO DE DATOS — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                |
|-----------------|------------------------------------------------|
| **Documento**   | Diccionario de Datos — EsbirrosDB             |
| **Proyecto**    | Sistema de Gestión de Bodegón Porteño          |
| **Cliente**     | Bodegón Los Esbirros de Claudio                |
| **Instituto**   | ISTEA                                          |
| **Versión**     | 2.0                                            |
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
| **Catálogos Base**       | SUCURSAL, CANAL_VENTA, ESTADO_PEDIDO, ROL, PLATO        |
| **Personal y Ubicación** | MESA, EMPLEADO                                          |
| **Clientes**             | CLIENTE, DOMICILIO                                      |
| **Productos y Precios**  | PRECIO                                                  |
| **Pedidos**              | PEDIDO, DETALLE_PEDIDO                                  |
| **Auditoría y Control**  | AUDITORIA_SIMPLE, STOCK_SIMULADO                         |
| **Notificaciones**       | NOTIFICACIONES                                          |
| **Reportes**             | REPORTES_GENERADOS                                      |

---

## **CONVENCIONES DE NOMENCLATURA**

| **Elemento**      | **Convención**      | **Ejemplo**                    |
|-------------------|---------------------|--------------------------------|
| Tablas            | MAYÚSCULAS          | `PEDIDO`, `DETALLE_PEDIDO`     |
| Campos ID         | `tabla_id`          | `pedido_id`, `cliente_id`      |
| Claves Foráneas   | `FK_TABLA_campo`    | `FK_PEDIDO_cliente`            |
| Claves Únicas     | `UK_TABLA_campo`    | `UK_MESA_qr_token`             |
| Check Constraints | `CK_TABLA_campo`    | `CK_PRECIO_vigencia`           |
| Índices           | `IX_TABLA_campos`   | `IX_PEDIDO_fecha_estado`       |
| Stored Procedures | `sp_AccionEntidad`  | `sp_AgregarItemPedido`         |
| Triggers          | `tr_AccionTabla`    | `tr_ActualizarTotales`         |

---

## **DICCIONARIO DETALLADO POR TABLA**

---

### 1. SUCURSAL
**Propósito:** Almacena las sucursales del bodegón.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**  | **Descripción**                  |
|----------------|---------------|----------|-----------|--------------|----------------------------------|
| sucursal_id    | INT           | NO       | PK        | IDENTITY(1,1)| Identificador único de sucursal  |
| nombre         | NVARCHAR(100) | NO       | UK        | —            | Nombre comercial de la sucursal  |
| direccion      | NVARCHAR(255) | NO       | —         | —            | Dirección física                 |

---

### 2. CANAL_VENTA
**Propósito:** Catálogo de canales por los que llegan pedidos.

| **Campo**  | **Tipo**    | **Nulo** | **Clave** | **Default**   | **Descripción**              |
|------------|-------------|----------|-----------|---------------|------------------------------|
| canal_id   | INT         | NO       | PK        | IDENTITY(1,1) | Identificador del canal      |
| nombre     | NVARCHAR(50)| NO       | UK        | —             | Nombre del canal de venta    |

**Valores iniciales:** Mostrador, Delivery, Mesa QR, Teléfono, App Móvil

---

### 3. ESTADO_PEDIDO
**Propósito:** Estados del flujo operativo de pedidos.

| **Campo**  | **Tipo**    | **Nulo** | **Clave** | **Default**   | **Descripción**                  |
|------------|-------------|----------|-----------|---------------|----------------------------------|
| estado_id  | INT         | NO       | PK        | IDENTITY(1,1) | Identificador del estado         |
| nombre     | NVARCHAR(50)| NO       | UK        | —             | Nombre del estado                |
| orden      | INT         | NO       | UK        | —             | Orden secuencial del flujo       |

**Flujo:** Pendiente(1) → Confirmado(2) → En Preparación(3) → Listo(4) → En Reparto(5) → Entregado(6) → Cerrado(7) | Cancelado(99)

---

### 4. ROL
**Propósito:** Roles del personal del bodegón.

| **Campo**   | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**          |
|-------------|---------------|----------|-----------|---------------|--------------------------|
| rol_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador del rol    |
| nombre      | NVARCHAR(50)  | NO       | UK        | —             | Nombre del rol           |
| descripcion | NVARCHAR(255) | SÍ       | —         | —             | Descripción del rol      |

**Valores iniciales:** Administrador, Gerente, Mozo, Cajero, Cocinero, Repartidor, Hostess

---

### 5. MESA
**Propósito:** Mesas físicas del salón con soporte de QR.

| **Campo**   | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                     |
|-------------|---------------|----------|-----------|---------------|-------------------------------------|
| mesa_id     | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único de mesa         |
| numero      | INT           | NO       | UK(comp.) | —             | Número de mesa (único por sucursal) |
| capacidad   | INT           | NO       | —         | —             | Cantidad máxima de comensales (>0)  |
| sucursal_id | INT           | NO       | FK        | —             | Sucursal a la que pertenece         |
| qr_token    | NVARCHAR(255) | NO       | UK        | —             | Token único del código QR           |
| activa      | BIT           | NO       | —         | 1             | Si la mesa está habilitada          |

**Constraints:** `CHECK capacidad > 0` · `UNIQUE (numero, sucursal_id)`

---

### 6. EMPLEADO
**Propósito:** Personal del bodegón con autenticación.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                    |
|----------------|---------------|----------|-----------|---------------|------------------------------------|
| empleado_id    | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del empleado   |
| nombre         | NVARCHAR(100) | NO       | —         | —             | Nombre completo                    |
| usuario        | NVARCHAR(50)  | NO       | UK        | —             | Nombre de usuario (único global)   |
| hash_password  | NVARCHAR(255) | NO       | —         | —             | Contraseña hasheada                |
| rol_id         | INT           | NO       | FK        | —             | Rol asignado                       |
| sucursal_id    | INT           | NO       | FK        | —             | Sucursal de pertenencia            |
| activo         | BIT           | NO       | —         | 1             | Si el empleado está activo         |

---

### 7. CLIENTE
**Propósito:** Clientes registrados para delivery e historial.

| **Campo**  | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                     |
|------------|---------------|----------|-----------|---------------|-------------------------------------|
| cliente_id | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del cliente     |
| nombre     | NVARCHAR(100) | NO       | —         | —             | Nombre completo del cliente         |
| telefono   | NVARCHAR(20)  | SÍ       | —         | —             | Teléfono de contacto                |
| email      | NVARCHAR(100) | SÍ       | UK        | —             | Email único                         |
| doc_tipo   | NVARCHAR(10)  | SÍ       | UK(comp.) | —             | Tipo de documento (DNI, CUIL, etc.) |
| doc_nro    | NVARCHAR(20)  | SÍ       | UK(comp.) | —             | Número de documento                 |

**Constraints:** `UNIQUE (email)` · `UNIQUE (doc_tipo, doc_nro)`

---

### 8. DOMICILIO
**Propósito:** Direcciones de entrega vinculadas a clientes.

| **Campo**     | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                  |
|---------------|---------------|----------|-----------|---------------|----------------------------------|
| domicilio_id  | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único              |
| cliente_id    | INT           | NO       | FK        | —             | Cliente propietario              |
| calle         | NVARCHAR(100) | NO       | —         | —             | Nombre de la calle               |
| numero        | NVARCHAR(10)  | NO       | —         | —             | Número de puerta                 |
| piso          | NVARCHAR(10)  | SÍ       | —         | —             | Piso (opcional)                  |
| depto         | NVARCHAR(10)  | SÍ       | —         | —             | Departamento (opcional)          |
| localidad     | NVARCHAR(50)  | NO       | —         | —             | Localidad                        |
| provincia     | NVARCHAR(50)  | NO       | —         | —             | Provincia                        |
| observaciones | NVARCHAR(255) | SÍ       | —         | —             | Notas de entrega (timbre, etc.)  |
| es_principal  | BIT           | NO       | —         | 0             | Si es el domicilio principal     |

---

### 9. PLATO
**Propósito:** Catálogo de ítems del menú del bodegón (entradas, pastas, carnes, bebidas, postres).

| **Campo**  | **Tipo**     | **Nulo** | **Clave** | **Default**   | **Descripción**                              |
|------------|--------------|----------|-----------|---------------|----------------------------------------------|
| plato_id   | INT          | NO       | PK        | IDENTITY(1,1) | Identificador único del producto/plato        |
| nombre     | NVARCHAR(100)| NO       | UK        | —             | Nombre del plato (único en el menú)          |
| categoria  | NVARCHAR(50) | NO       | —         | —             | Categoría del menú                           |
| activo     | BIT          | NO       | —         | 1             | Si el plato está disponible en el menú       |

**Categorías del bodegón:** Entradas, Pastas, Carnes a la Leña, Guarniciones, Postres, Bebidas

---

### 10. PRECIO
**Propósito:** Historial de precios con vigencia temporal por plato.

| **Campo**      | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                          |
|----------------|---------------|----------|-----------|---------------|------------------------------------------|
| precio_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del registro         |
| plato_id       | INT           | NO       | FK        | —             | Plato al que aplica el precio            |
| vigencia_desde | DATE          | NO       | —         | —             | Fecha de inicio de vigencia              |
| vigencia_hasta | DATE          | SÍ       | —         | —             | Fecha de fin (NULL = vigente hasta nuevo)|
| precio         | DECIMAL(10,2) | NO       | —         | —             | Precio en pesos argentinos (≥ 0)         |

**Constraints:** `CHECK precio >= 0` · `CHECK vigencia_hasta >= vigencia_desde`

---

### 11. PEDIDO
**Propósito:** Entidad central. Registra cada transacción del bodegón.

| **Campo**                 | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                          |
|---------------------------|---------------|----------|-----------|---------------|------------------------------------------|
| pedido_id                 | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único del pedido           |
| fecha_pedido              | DATETIME      | NO       | —         | GETDATE()     | Fecha y hora de creación                 |
| fecha_entrega             | DATETIME      | SÍ       | —         | —             | Fecha y hora de entrega (delivery)       |
| canal_id                  | INT           | NO       | FK        | —             | Canal de venta                           |
| mesa_id                   | INT           | SÍ       | FK        | —             | Mesa asignada (solo canal Mesa QR)       |
| cliente_id                | INT           | SÍ       | FK        | —             | Cliente (delivery o registrado)          |
| domicilio_id              | INT           | SÍ       | FK        | —             | Domicilio de entrega (solo delivery)     |
| cant_comensales           | INT           | SÍ       | —         | —             | Número de comensales en mesa             |
| estado_id                 | INT           | NO       | FK        | —             | Estado actual del pedido                 |
| tomado_por_empleado_id    | INT           | NO       | FK        | —             | Empleado que tomó el pedido              |
| entregado_por_empleado_id | INT           | SÍ       | FK        | —             | Empleado que entregó (delivery)          |
| total                     | DECIMAL(10,2) | NO       | —         | 0             | Total del pedido (calculado por trigger) |
| observaciones             | NVARCHAR(500) | SÍ       | —         | —             | Notas especiales del pedido              |

---

### 12. DETALLE_PEDIDO
**Propósito:** Líneas de pedido. Cada registro = un ítem (plato) dentro de un pedido.

> `plato_id` es siempre obligatorio — cada línea de pedido referencia un plato individual.

| **Campo**       | **Tipo**      | **Nulo** | **Clave** | **Default**   | **Descripción**                         |
|-----------------|---------------|----------|-----------|---------------|-----------------------------------------|
| detalle_id      | INT           | NO       | PK        | IDENTITY(1,1) | Identificador único de la línea         |
| pedido_id       | INT           | NO       | FK        | —             | Pedido al que pertenece                 |
| plato_id        | INT           | NO       | FK        | —             | Plato pedido (siempre obligatorio)      |
| cantidad        | INT           | NO       | —         | —             | Cantidad pedida (> 0)                   |
| precio_unitario | DECIMAL(10,2) | NO       | —         | —             | Precio al momento del pedido (≥ 0)      |
| subtotal        | DECIMAL(10,2) | NO       | —         | —             | cantidad × precio_unitario (≥ 0)        |

**Constraints:** `CHECK cantidad > 0` · `CHECK precio_unitario >= 0` · `CHECK subtotal >= 0`

---

## **TABLAS AUXILIARES (creadas por Bundles E1/E2/R1)**

### AUDITORIA_SIMPLE (Bundle E1)
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

### STOCK_SIMULADO (Bundle E2)
Inventario simulado por plato, gestionado por `tr_ValidarStock`.

| **Campo**           | **Tipo** | **Descripción**                     |
|---------------------|----------|-------------------------------------|
| plato_id            | INT PK/FK| Plato (referencia a PLATO)          |
| stock_disponible    | INT      | Unidades disponibles (DEFAULT 100)  |
| stock_minimo        | INT      | Umbral de alerta (DEFAULT 10)       |
| ultima_actualizacion| DATETIME | Última modificación                 |

### NOTIFICACIONES (Bundle E2)
Alertas automáticas generadas por `tr_SistemaNotificaciones`.

| **Campo**       | **Tipo**      | **Descripción**                            |
|-----------------|---------------|--------------------------------------------|
| notificacion_id | INT PK        | Identificador                              |
| tipo            | VARCHAR(50)   | PEDIDO_LISTO / PEDIDO_CERRADO / etc.       |
| titulo          | NVARCHAR(200) | Título de la notificación                  |
| mensaje         | NVARCHAR(500) | Cuerpo del mensaje                         |
| pedido_id       | INT NULL      | Pedido relacionado (referencia lógica)     |
| mesa_id         | INT NULL      | Mesa relacionada (referencia lógica)       |
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
| tipo_reporte     | NVARCHAR(50)   | Tipo: VENTAS_DIARIO, PLATOS_POPULAR, etc. |
| fecha_generacion | DATETIME       | Timestamp de ejecución (DEFAULT GETDATE())|
| fecha_reporte    | DATE           | Fecha del período reportado               |
| sucursal_id      | INT NULL FK    | Sucursal (referencia a SUCURSAL)          |
| datos_json       | NVARCHAR(MAX)  | Resultados del reporte en JSON            |
| ejecutado_por    | NVARCHAR(100)  | Usuario que ejecutó (DEFAULT SYSTEM_USER) |
| estado           | NVARCHAR(20)   | Estado del reporte (DEFAULT 'COMPLETADO') |
| observaciones    | NVARCHAR(500)  | Notas adicionales                         |

---

## **ÍNDICES IMPLEMENTADOS**

| **Índice**                    | **Tabla**      | **Columnas**                        | **Tipo**        | **Propósito**                         |
|-------------------------------|----------------|-------------------------------------|-----------------|---------------------------------------|
| IX_PEDIDO_fecha_estado        | PEDIDO         | fecha_pedido, estado_id             | Non-clustered   | Reportes de ventas diarias            |
| IX_PEDIDO_mesa                | PEDIDO         | mesa_id (filtrado NOT NULL)         | Non-clustered   | Lookup por mesa en servicio de salón  |
| IX_PEDIDO_cliente             | PEDIDO         | cliente_id (filtrado NOT NULL)      | Non-clustered   | Historial de cliente / delivery       |
| IX_DETALLE_PEDIDO_pedido      | DETALLE_PEDIDO | pedido_id                           | Non-clustered   | JOIN principal detalle→pedido         |
| IX_DETALLE_PEDIDO_plato       | DETALLE_PEDIDO | plato_id                            | Non-clustered   | Ranking de productos populares        |
| IX_MESA_sucursal_activa       | MESA           | sucursal_id, activa                 | Non-clustered   | Mesas activas por sucursal            |
| IX_EMPLEADO_sucursal_activo   | EMPLEADO       | sucursal_id, activo                 | Non-clustered   | Empleados activos por sucursal        |
| IX_PRECIO_plato_vigencia      | PRECIO         | plato_id, vigencia_desde, hasta     | Non-clustered   | Precio vigente (evita table scan)     |

> **Buena práctica (mejorespracticas.md §4):** Para cargas masivas (BULK INSERT), eliminar índices antes de la carga y recrearlos al finalizar.

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — Adaptación EsbirrosDB — 2026**
