# MODELO ENTIDAD-RELACIÓN — SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**         | **Descripción**                                  |
|-------------------|--------------------------------------------------|
| **Documento**     | Modelo Entidad-Relación (DER) — EsbirrosDB       |
| **Proyecto**      | Sistema de Gestión de Bodegón Porteño            |
| **Cliente**       | Bodegón Los Esbirros de Claudio                  |
| **Instituto**     | ISTEA                                            |
| **Versión**       | 2.0                                              |
| **Estado**        | Implementado y Funcional                         |

---

## **RESUMEN EJECUTIVO**

### Objetivo del Documento
Presenta el Modelo Entidad-Relación del sistema **EsbirrosDB**, diseñado para la gestión operativa del **Bodegón Los Esbirros de Claudio**. Documenta las relaciones entre entidades y la arquitectura visual del modelo de datos.

### Componentes del Modelo

| **Métrica**           | **Valor** |
|-----------------------|-----------|
| Entidades (tablas A1) | 12        |
| Tablas auxiliares     | 4 (AUDITORIA_SIMPLE, STOCK_SIMULADO, NOTIFICACIONES, REPORTES_GENERADOS) |
| **Total tablas**      | **16**    |
| Relaciones FK         | 17        |
| Módulos funcionales   | 7         |

### Decisiones de Diseño
- **`DETALLE_PEDIDO` directo:** `plato_id NOT NULL`, cada ítem referencia un plato individual
- **Contexto de negocio:** bodegón porteño (cocina a la leña, pastas, carnes)

---

## **DIAGRAMA ENTIDAD-RELACIÓN COMPLETO**

> Renderizable en [mermaid.live](https://mermaid.live) o en cualquier editor compatible con Mermaid (VS Code + extensión, GitHub, Notion, etc.)

```mermaid
erDiagram

    %% ─── CATÁLOGOS ───────────────────────────────────────────

    SUCURSAL {
        int     sucursal_id  PK
        nvarchar nombre      UK
        nvarchar direccion
    }

    CANAL_VENTA {
        int     canal_id  PK
        nvarchar nombre   UK
    }

    ESTADO_PEDIDO {
        int     estado_id PK
        nvarchar nombre   UK
        int     orden     UK
    }

    ROL {
        int     rol_id      PK
        nvarchar nombre     UK
        nvarchar descripcion
    }

    %% ─── PERSONAL Y UBICACIÓN ────────────────────────────────

    MESA {
        int     mesa_id     PK
        int     numero
        int     capacidad
        int     sucursal_id FK
        nvarchar qr_token   UK
        bit     activa
    }

    EMPLEADO {
        int     empleado_id   PK
        nvarchar nombre
        nvarchar usuario      UK
        nvarchar hash_password
        int     rol_id        FK
        int     sucursal_id   FK
        bit     activo
    }

    %% ─── CLIENTES Y DOMICILIOS ───────────────────────────────

    CLIENTE {
        int     cliente_id PK
        nvarchar nombre
        nvarchar telefono
        nvarchar email     UK
        nvarchar doc_tipo
        nvarchar doc_nro
    }

    DOMICILIO {
        int     domicilio_id  PK
        int     cliente_id    FK
        nvarchar calle
        nvarchar numero
        nvarchar piso
        nvarchar depto
        nvarchar localidad
        nvarchar provincia
        nvarchar observaciones
        bit     es_principal
    }

    %% ─── PRODUCTOS Y PRECIOS ─────────────────────────────────


    PLATO {
        int     plato_id  PK
        nvarchar nombre   UK
        nvarchar categoria
        bit     activo
    }

    PRECIO {
        int     precio_id      PK
        int     plato_id       FK
        date    vigencia_desde
        date    vigencia_hasta
        decimal precio
    }

    %% ─── PEDIDOS ─────────────────────────────────────────────

    PEDIDO {
        int     pedido_id                 PK
        datetime fecha_pedido
        datetime fecha_entrega
        int     canal_id                  FK
        int     mesa_id                   FK
        int     cliente_id                FK
        int     domicilio_id              FK
        int     cant_comensales
        int     estado_id                 FK
        int     tomado_por_empleado_id    FK
        int     entregado_por_empleado_id FK
        decimal total
        nvarchar observaciones
    }

    DETALLE_PEDIDO {
        int     detalle_id      PK
        int     pedido_id       FK
        int     plato_id        FK
        int     cantidad
        decimal precio_unitario
        decimal subtotal
    }

    %% ─── AUDITORÍA ───────────────────────────────────────────
    %% Tabla AUDITORIA eliminada (v2.0) — se usa AUDITORIA_SIMPLE (Bundle E1)

    %% ─── TABLAS AUXILIARES (Bundles E1, E2, R1) ──────────────

    AUDITORIA_SIMPLE {
        int      auditoria_id    PK
        nvarchar tabla_afectada
        int      registro_id
        varchar  accion
        datetime fecha_auditoria
        varchar  usuario_sistema
        nvarchar datos_resumen
    }

    STOCK_SIMULADO {
        int      plato_id             PK "FK"
        int      stock_disponible
        int      stock_minimo
        datetime ultima_actualizacion
    }

    NOTIFICACIONES {
        int      notificacion_id PK
        varchar  tipo
        nvarchar titulo
        nvarchar mensaje
        int      pedido_id       FK
        int      mesa_id         FK
        varchar  prioridad
        datetime fecha_creacion
        bit      leida
        datetime fecha_lectura
        varchar  usuario_destino
    }

    REPORTES_GENERADOS {
        int      reporte_id       PK
        nvarchar tipo_reporte
        datetime fecha_generacion
        date     fecha_reporte
        int      sucursal_id      FK
        nvarchar datos_json
        nvarchar ejecutado_por
        nvarchar estado
        nvarchar observaciones
    }

    %% ─── RELACIONES ──────────────────────────────────────────

    SUCURSAL      ||--o{ MESA      : "tiene mesas"
    SUCURSAL      ||--o{ EMPLEADO  : "tiene empleados"
    ROL           ||--o{ EMPLEADO  : "asigna rol"

    CLIENTE       ||--o{ DOMICILIO : "tiene domicilios"
    CLIENTE       |o--o{ PEDIDO    : "realiza"
    DOMICILIO     |o--o{ PEDIDO    : "dirección de entrega"

    CANAL_VENTA   ||--o{ PEDIDO    : "canal de venta"
    ESTADO_PEDIDO ||--o{ PEDIDO    : "estado actual"
    MESA          |o--o{ PEDIDO    : "mesa asignada"

    EMPLEADO      ||--o{ PEDIDO    : "tomado por"
    EMPLEADO      |o--o{ PEDIDO    : "entregado por"

    PEDIDO        ||--o{ DETALLE_PEDIDO : "contiene ítems"

    PLATO         ||--o{ DETALLE_PEDIDO : "incluido en pedido"
    PLATO         ||--o{ PRECIO         : "historial de precios"

    %% Relaciones tablas auxiliares
    PLATO           ||--o| STOCK_SIMULADO     : "stock por plato"
    PEDIDO          |o--o{ NOTIFICACIONES     : "genera notificación"
    MESA            |o--o{ NOTIFICACIONES     : "notifica mesa"
    SUCURSAL        |o--o{ REPORTES_GENERADOS : "reporte por sucursal"
```

---

## **DESCRIPCIÓN DE MÓDULOS**

### Módulo 1 — Catálogos Base
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `SUCURSAL` | Hub central del sistema | 1:N con MESA y EMPLEADO |
| `CANAL_VENTA` | Catalog de canales (Mesa QR, Delivery, etc.) | 1:N con PEDIDO |
| `ESTADO_PEDIDO` | Estados ordenados del flujo | 1:N con PEDIDO |
| `ROL` | Roles del personal | 1:N con EMPLEADO |

### Módulo 2 — Personal y Ubicación
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `MESA` | Mesas físicas con QR | N:1 con SUCURSAL |
| `EMPLEADO` | Personal con autenticación | N:1 con ROL y SUCURSAL |

### Módulo 3 — Clientes
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `CLIENTE` | Datos del cliente | 1:N con DOMICILIO |
| `DOMICILIO` | Direcciones de entrega | N:1 con CLIENTE |

### Módulo 4 — Productos y Precios
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `PLATO` | Catálogo del menú (pastas, carnes, bebidas…) | 1:N con PRECIO, DETALLE_PEDIDO |
| `PRECIO` | Historial de precios con vigencia temporal | N:1 con PLATO |

### Módulo 5 — Pedidos
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `PEDIDO` | Entidad central de transacciones | N:1 con múltiples catálogos |
| `DETALLE_PEDIDO` | Líneas de pedido (siempre un plato) | N:1 con PEDIDO y PLATO |

### Módulo 6 — Auditoría
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| *(Tabla AUDITORIA eliminada v2.0 — la auditoría se maneja con AUDITORIA_SIMPLE, creada por Bundle E1)* | | |

### Módulo 7 — Reportes
| Tabla | Rol | Cardinalidad clave |
|-------|-----|--------------------|
| `REPORTES_GENERADOS` | Registro de reportes ejecutados | N:1 con SUCURSAL |

### Tablas auxiliares (creadas por Bundles E1/E2/R1)
| Tabla | Bundle | Propósito | FK |
|-------|--------|-----------|----|
| `AUDITORIA_SIMPLE` | E1 | Log simplificado de INSERT/UPDATE/DELETE | — |
| `STOCK_SIMULADO` | E2 | Inventario simulado por plato | `plato_id` → PLATO |
| `NOTIFICACIONES` | E2 | Alertas automáticas de estado de pedidos | `pedido_id` → PEDIDO, `mesa_id` → MESA |
| `REPORTES_GENERADOS` | R1 | Registro de reportes generados por SPs | `sucursal_id` → SUCURSAL |

---

## **FLUJOS DE DATOS CRÍTICOS**

### Flujo 1 — Pedido en Salón (Mesa QR)
```
CANAL_VENTA (Mesa QR) → PEDIDO → DETALLE_PEDIDO → PLATO → PRECIO
                    ↗ MESA ↗ EMPLEADO (mozo)
```

### Flujo 2 — Pedido Delivery
```
CANAL_VENTA (Delivery) → PEDIDO → DETALLE_PEDIDO → PLATO
                      ↗ CLIENTE → DOMICILIO
                      ↗ EMPLEADO (tomado) + EMPLEADO (entregado)
```

### Flujo 3 — Trazabilidad
```
PEDIDO (UPDATE estado) → tr_AuditoriaPedidos → AUDITORIA_SIMPLE
                       → tr_SistemaNotificaciones → NOTIFICACIONES
```

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — Adaptación EsbirrosDB — 2026**
