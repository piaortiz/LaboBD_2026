# RESUMEN DEL PROYECTO — ESBIRROSDB v2.0

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo**       | **Descripción**                                         |
|-----------------|---------------------------------------------------------|
| **Documento**   | Resumen del Proyecto — EsbirrosDB                      |
| **Proyecto**    | EsbirrosDB — Sistema de Gestión de Bodegón Porteño     |
| **Negocio**     | Bodegón Los Esbirros de Claudio                         |
| **Equipo**      | SQLeaders S.A.                                          |
| **Fecha**       | 2026                                                    |
| **Versión**     | 2.0                                                     |

---

## **1. NOMBRE DEL PROYECTO**

Se evaluaron 6 nombres candidatos para la base de datos, adaptados al contexto de bodegón porteño y la identidad del equipo de trabajo:

| **#** | **Nombre DB**       | **Nombre del Negocio**             | **Concepto**                                      |
|-------|---------------------|------------------------------------|---------------------------------------------------|
| 1     | **EsbirrosDB** ✅   | Bodegón Los Esbirros de Claudio    | El equipo (esbirros) + el referente (Claudio)     |
| 2     | LeñaLink            | El Bodegón de la Leña              | La leña como eje del bodegón porteño              |
| 3     | BodegonInfra        | Bodegón Infraestructura            | Guiño al stack técnico del TP                     |
| 4     | ClaudiosBodegon     | Lo de Claudio — Bodegón Porteño    | Clásico nombre de bodegón de barrio               |
| 5     | EsbirrosLeña        | Los Esbirros & La Leña             | Combina identidad del equipo + el fuego           |
| 6     | InfraLeñaDB         | Infra & Leña Bodegón               | Más técnico, juega con infraestructura y leña     |

> **Nombre seleccionado:** `EsbirrosDB` — Bodegón Los Esbirros de Claudio

**¿Por qué "esbirros"?** Término humorístico para los integrantes del equipo que ejecutan las órdenes del jefe (Claudio). En la cultura popular equivale a los *Minions* — leales, trabajadores y siempre al pie del cañón.

---

## **2. DECISIONES DE DISEÑO**

### Modelo de datos: solo platos individuales

El bodegón opera con un menú de platos sueltos — sin armado de combos ni descuentos por promoción. Esta realidad del negocio se reflejó directamente en el modelo de datos:

| **Elemento**                     | **Decisión**      | **Motivo**                                      |
|----------------------------------|-------------------|-------------------------------------------------|
| Sin tabla COMBO                  | No implementada   | El bodegón no ofrece combos armados             |
| Sin tabla PROMOCION              | No implementada   | Sin descuentos o precios especiales por volumen |
| `DETALLE_PEDIDO.plato_id`        | `NOT NULL`        | Cada ítem siempre referencia un plato           |

### Estructura de DETALLE_PEDIDO

```sql
-- Diseño EsbirrosDB: simple y directo
plato_id    INT NOT NULL   -- siempre obligatorio
-- Sin campos condicionales, sin lógica de tipo de ítem
```

### Cambios en Stored Procedures

| **Procedimiento**        | **Descripción**                                                       |
|--------------------------|-----------------------------------------------------------------------|
| `sp_AgregarItemPedido`   | `@plato_id` obligatorio; no existen parámetros opcionales de tipo ítem |
| `sp_CalcularTotalPedido` | Suma directa de subtotales, sin lógica de descuentos                  |

### Documentación ajustada al negocio

| **Documento**              | **Ajuste**                                                           |
|----------------------------|----------------------------------------------------------------------|
| Diccionario de Datos       | Módulo "Productos y Precios": solo tablas PLATO y PRECIO             |
| Reglas del Negocio         | Sin módulo de promociones; RN-007 simplificada                       |
| DER (Mermaid)              | 13 entidades, relación directa PLATO → DETALLE_PEDIDO                |

---

## **3. CUMPLIMIENTO DE MEJORES PRÁCTICAS**

Verificación según `mejorespracticas.md`:

### §1 — Infraestructura en la Nube (DBaaS)
| **Práctica**                          | **Estado** | **Evidencia**                                         |
|---------------------------------------|------------|-------------------------------------------------------|
| SQL Server Express / instancia pequeña| ✅         | Documentado en Guía de Despliegue (Bundle A1)         |
| Almacenamiento mínimo (20 GB)         | ✅         | Definido en Requerimientos Técnicos                   |
| Desactivar auto-scaling               | ✅         | Documentado en Plan de Backup                         |
| Alarmas de presupuesto (USD 1)        | ✅         | Referenciado en documentación de despliegue           |
| Puerto 1433 en Security Group         | ✅         | Detallado en Requerimientos Técnicos                  |

### §2 — Modelado Lógico y Diseño de Datos
| **Práctica**                          | **Estado** | **Evidencia**                                         |
|---------------------------------------|------------|-------------------------------------------------------|
| PKs autoincrementales (INT IDENTITY)  | ✅         | Todas las tablas usan `IDENTITY(1,1)`                 |
| Normalización 3FN                     | ✅         | Sin redundancias; provincias normalizadas en DOMICILIO|
| Integridad referencial con FK         | ✅         | 14 FKs en Bundle A1 (17 total con auxiliares)         |
| Políticas RESTRICT (sin CASCADE)      | ✅         | Ninguna FK con `ON DELETE CASCADE`                    |
| UNIQUE constraints en catálogos       | ✅         | UK en nombre, usuario, qr_token, email, etc.          |

### §3 — Carga Masiva (Bulk Insert)
| **Práctica**                          | **Estado** | **Notas**                                             |
|---------------------------------------|------------|-------------------------------------------------------|
| BULK INSERT / bcp para 10K+ registros | ⏳ Pendiente | Datos iniciales cargados; datos masivos en etapa siguiente |
| Generar datos con IA (Faker/Python)   | ⏳ Pendiente | Recomendado documentar el prompt utilizado            |
| Desactivar índices antes de BULK      | ✅ Documentado | Detallado en Diccionario de Datos §Índices           |
| FIRSTROW = 2 para omitir encabezados  | ✅ Documentado | En guía de carga masiva                              |

### §4 — Optimización: Índices
| **Práctica**                          | **Estado** | **Evidencia**                                         |
|---------------------------------------|------------|-------------------------------------------------------|
| Non-clustered indexes en FK y filtros | ✅         | 8 índices en Bundle A2                                |
| Índices compuestos para filtros multi-campo | ✅   | `IX_PEDIDO_fecha_estado`, `IX_PRECIO_plato_vigencia`  |
| Índices filtrados (WHERE IS NOT NULL) | ✅         | `IX_PEDIDO_mesa`, `IX_PEDIDO_cliente`                 |
| Análisis con Plan de Ejecución (SSMS) | ✅ Documentado | Mencionado en Diccionario de Datos                  |

### §5 — Documentación y Entrega
| **Práctica**                          | **Estado** | **Evidencia**                                         |
|---------------------------------------|------------|-------------------------------------------------------|
| DER actualizado con cardinalidades    | ✅         | `05 - Modelo Entidad–Relación (DER).md` con Mermaid  |
| Documentación de tablas, triggers, SPs| ✅         | `02 - Diccionario de Datos.md` completo              |
| Plan de Backup y Disaster Recovery    | ✅         | `07 - Plan de Backup y Recuperacion.md`              |
| Transparencia en uso de IA            | ✅         | Documentado en `04 - Carga de Datos`                 |

---

## **4. DIAGRAMA DER**

El DER fue diseñado con las siguientes características:

- **Diagrama Mermaid embebido** directamente en `05 - Modelo Entidad–Relación (DER).md` (renderizable en VS Code, GitHub, Notion, sin links externos)
- **12 entidades** principales + 4 tablas auxiliares (creadas por triggers/SPs)
- **Relación directa:** `PLATO →|o--o{ DETALLE_PEDIDO` (1:N sin intermediarios)

### Resumen de entidades del DER

```
SUCURSAL ────── MESA ────────────── PEDIDO ──── DETALLE_PEDIDO ──── PLATO
    └─────── EMPLEADO ──────────────────┘                               └── PRECIO
CANAL_VENTA ────────────────────────┘
ESTADO_PEDIDO ──────────────────────┘
CLIENTE ──── DOMICILIO ─────────────┘
```

---

## **5. ESTRUCTURA DEL PROYECTO**

```
BodegaLinkEntrega/
├── A - Documentacion Tecnica/
│   ├── 01 - Requerimientos Tecnicos.md
│   ├── 02 - Diccionario de Datos.md
│   ├── 03 - Guia de Despliegue Inicial.md
│   ├── 04 - Carga de Datos Bodegon.md
│   ├── 05 - Modelo Entidad–Relación (DER).md
│   ├── 06 - Reglas del Negocio.md
│   ├── 07 - Plan de Backup y Recuperacion.md
│   └── 08 - Glosario.md
├── B - Scripts SQL/
│   ├── 00_Reset_Completo/
│   │   └── Bundle_CERO_Reset_Completo.sql
│   ├── 01_Infraestructura_Base/
│   │   ├── Bundle_A1_BaseDatos_Estructura.sql  ← EsbirrosDB, 12 tablas
│   │   └── Bundle_A2_Indices_Datos.sql         ← Menú bodegón porteño (22 platos)
│   ├── 02_Logica_Negocio/
│   │   ├── Bundle_B1_Pedidos_Core.sql
│   │   ├── Bundle_B2_Items_Calculos.sql        ← sp_AgregarItemPedido sin combos
│   │   └── Bundle_B3_Estados_Finalizacion.sql
│   ├── 03_Seguridad_Consultas/
│   │   ├── Bundle_C_Seguridad.sql              ← Roles + app_esbirros_*
│   │   └── Bundle_D_Consultas_Basicas.sql
│   ├── 04_Automatizacion_Avanzada/
│   │   ├── Bundle_E1_Triggers_Principales.sql
│   │   └── Bundle_E2_Control_Avanzado.sql
│   ├── 05_Reportes_Dashboard/
│   │   ├── Bundle_R1_Reportes_Estructuras_SPs.sql
│   │   └── Bundle_R2_Reportes_Vistas_Dashboard.sql
│   └── 06_VALIDACION_POST_BUNDLES.sql
├── ANALISIS_REQUISITOS_TP.md
└── RESUMEN_ADAPTACION.md                        ← Este documento
```

---

## **6. PRÓXIMOS PASOS RECOMENDADOS**

1. **Carga masiva de datos** — Generar 10.000 registros de PEDIDO y DETALLE_PEDIDO con Faker (Python) o IA; ejecutar como BULK INSERT según `mejorespracticas.md §3`
2. **Despliegue AWS RDS** — Instancia SQL Server Express (T3 micro), puerto 1433, IP restringida
3. **Backup inicial** — Generar `.bak` post-despliegue según Plan de Backup
4. **Documentar prompt de IA** — Incluir el prompt usado para generación de datos en `04 - Carga de Datos`

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — EsbirrosDB — 2026**  
**Proyecto Educativo ISTEA — Prohibida la comercialización**
