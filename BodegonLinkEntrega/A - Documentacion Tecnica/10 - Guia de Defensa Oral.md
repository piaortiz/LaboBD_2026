# 10 — Guía de Defensa Oral — EsbirrosDB

> **Objetivo:** Preparar a todos los integrantes del grupo para responder correctamente las preguntas del profesor durante el examen parcial. Cada sección incluye la pregunta probable, la respuesta correcta con argumentos técnicos, y los números clave a mencionar.

---

## 🔢 NÚMEROS CLAVE — Memorizar antes del examen

| Elemento | Cantidad | Detalle |
|---|---|---|
| Tablas | **16** | Ver Diccionario de Datos |
| Stored Procedures | **19** | Flujo completo de pedidos + reportes |
| Triggers | **5** | Control automático de estados y auditoría |
| Vistas | **4** | Dashboard + consultas frecuentes |
| Índices non-clustered | **23 totales** (11 definidos explícitamente) | 3 UIX filtrados, 8 de performance/unicidad |
| Roles de seguridad | **9** | Desde `rol_solo_lectura` hasta `rol_administrador` |
| Estados del pedido | **8** | Secuencia estricta implementada por triggers |
| Canales | **4** | Mesa / Mostrador / Delivery / App |
| Platos en menú | **22** | Cargados en Bundle F |
| Mesas | **8** | Numeradas 1–8 |
| Sucursales | **1** | Palermo eliminado — solo Casa Central |
| Registros cargados (F) | **~96.000** | 3004 clientes, 10000 pedidos, 30001 detalles, etc. |

---

## 📋 SECCIÓN 1 — Modelo de Datos y Diseño de Tablas

### P1: ¿Por qué tienen una tabla PRECIOS separada de PLATOS?

**Respuesta:**
Porque los precios cambian con el tiempo y necesitábamos mantener el historial sin modificar el precio original de un pedido ya cerrado. Si el precio estuviera directamente en PLATOS, al actualizarlo perderíamos la referencia histórica.

La tabla PRECIOS tiene:
- `plato_id` (FK a PLATOS)
- `monto` (decimal, no negativo — CHECK monto >= 0)
- `fecha_desde` y `fecha_hasta` (vigencia)

El SP `sp_ObtenerPrecioVigente` consulta el precio activo según la fecha del pedido.

**Argumento adicional:** Esto respeta la regla de negocio RN-004 y permite auditar cambios de precios históricos.

---

### P2: ¿Por qué existe STOCKS_SIMULADOS si es una simulación?

**Respuesta:**
Porque la materia pide modelar el control de inventario aunque el local no tenga un sistema real de stock. La tabla permite al trigger `trg_DescontarStock` restar automáticamente las unidades cuando un pedido pasa a estado "En Preparación", y rechazarlo si no hay stock disponible.

Es una tabla auxiliar de soporte pedagógico — simula el comportamiento real de un sistema de inventario sin necesidad de integrar un ERP externo.

**No viola 3FN** porque `stock_actual` depende funcionalmente de `plato_id`, que es la PK.

---

### P3: ¿Por qué no modelaron combos o promociones?

**Respuesta:**
Decisión explícita de alcance. El foco del proyecto era modelar correctamente el flujo de pedidos con sus estados, la seguridad por roles, y la auditoría. Agregar combos requeriría una tabla de asociación N:M (COMBO_ITEMS), lógica de precio compuesto, y validaciones adicionales que excedían el tiempo disponible.

Si se quisiera extender, se agregaría una tabla `COMBOS` con `combo_id`, `nombre`, y una tabla `COMBO_ITEMS (combo_id, plato_id, cantidad)`.

---

### P4: ¿Por qué tienen la tabla NOTIFICACIONES si siempre tiene 0 registros después de la carga?

**Respuesta:**
La tabla existe porque los triggers la usan para registrar eventos automáticos (cambios de estado importantes). En la carga masiva (Bundle F) se insertaron pedidos directamente en sus estados finales, sin pasar por el flujo normal de cambios de estado, por eso no se generaron notificaciones.

En operación real, cada vez que un pedido cambia de estado por medio de `sp_CambiarEstadoPedido`, el trigger correspondiente inserta registros en NOTIFICACIONES.

---

### P5: ¿Cuántas tablas tiene el sistema y cuáles son las principales?

**Respuesta — 16 tablas:**

| Grupo | Tablas |
|---|---|
| Maestras | PLATOS, CATEGORIAS, INGREDIENTES, PLATOS_INGREDIENTES |
| Precios/Stock | PRECIOS, STOCKS_SIMULADOS |
| Pedidos | PEDIDOS, DETALLE_PEDIDOS |
| Operación | ESTADOS_PEDIDOS, CANALES, MESAS, DOMICILIOS |
| Clientes | CLIENTES |
| Sucursales | SUCURSALES |
| Auditoría | AUDITORIA_ESTADOS |
| Notificaciones | NOTIFICACIONES |

---

## 📋 SECCIÓN 2 — Normalización

### P6: ¿En qué forma normal está la base de datos?

**Respuesta:**
En **Tercera Forma Normal (3FN):**

1. **1FN:** Todos los campos son atómicos, no hay grupos repetidos. Cada tabla tiene una PK definida.

2. **2FN:** No hay dependencias parciales. En la única tabla con PK compuesta (PLATOS_INGREDIENTES con `plato_id + ingrediente_id`), todos los atributos dependen de la clave completa.

3. **3FN:** No hay dependencias transitivas. Por ejemplo, `categoria_nombre` no está en PLATOS — está en CATEGORIAS referenciada por FK. El precio no está en PEDIDOS — está en PRECIOS referenciado por SP.

**Ejemplo de aplicación de 3FN:** Si el nombre de una categoría cambia, se actualiza en un solo lugar (CATEGORIAS) y todos los platos reflejan el cambio automáticamente.

---

### P7: ¿Por qué DETALLE_PEDIDOS almacena `precio_unitario` en lugar de consultarlo desde PRECIOS?

**Respuesta:**
Desnormalización controlada e intencional. Al insertar un ítem en el detalle, se "congela" el precio vigente en ese momento. Si mañana el precio del plato cambia, el detalle histórico del pedido conserva el precio original.

Este patrón es estándar en sistemas de facturación y e-commerce. El SP `sp_AgregarItemPedido` se encarga de consultar el precio vigente y copiarlo al detalle.

---

## 📋 SECCIÓN 3 — Índices

### P8: ¿Qué son los índices UIX filtrados y por qué los usaron?

**Respuesta:**
Son índices `UNIQUE` con una cláusula `WHERE` que limita qué filas participan en la restricción de unicidad.

**El problema:** SQL Server implementa los índices UNIQUE con `NULL` de forma que un solo NULL es aceptable (es único), pero si intentáramos dos filas con email NULL, fallaría — o con algunos drivers, ambos NULLs se consideran distintos. Pero en nuestro caso, email y documento son opcionales (puede haber clientes que no los provean), y no queremos que dos clientes sin email violen unicidad.

**La solución — 3 UIX filtrados:**
```sql
-- Solo aplica unicidad cuando el campo NO es NULL
CREATE UNIQUE INDEX UIX_CLIENTE_email
  ON CLIENTES(email) WHERE email IS NOT NULL;

CREATE UNIQUE INDEX UIX_CLIENTE_documento
  ON CLIENTES(documento) WHERE documento IS NOT NULL;

-- Solo aplica cuando la dirección está marcada como principal
CREATE UNIQUE INDEX UIX_DOMICILIO_principal
  ON DOMICILIOS(cliente_id, es_principal) WHERE es_principal = 1;
```

**Requisito técnico importante:** Para que los índices filtrados funcionen correctamente, todas las sesiones deben tener `SET QUOTED_IDENTIFIER ON` y `SET ANSI_NULLS ON`. Por eso agregamos esas directivas al inicio de todos los bundles.

---

### P9: ¿Cuántos índices tiene el sistema y cuál es su propósito?

**Respuesta:**
**23 índices non-clustered en total** (verificado con `sys.indexes`).

De los 11 definidos explícitamente en los bundles:
- **3 UIX filtrados** (email, documento, domicilio principal) — unicidad condicional
- **2 UIX convencionales** — teléfono de cliente (único no nulo), nombre de plato
- **6 de performance** — sobre FKs frecuentes: `pedido_id` en DETALLE, `cliente_id` en PEDIDOS y DOMICILIOS, `plato_id` en DETALLE y PRECIOS, `estado_id` en PEDIDOS

Los índices adicionales (hasta 23) son los que SQL Server crea automáticamente para las PKs y algunas FKs.

---

## 📋 SECCIÓN 4 — Stored Procedures y Flujo de Pedidos

### P10: Expliquen el flujo completo de un pedido desde que el cliente llega hasta que paga.

**Respuesta — flujo de los 8 estados:**

```
1. PENDIENTE       → sp_CrearPedido valida cliente, canal, mesa/domicilio
2. CONFIRMADO      → sp_CambiarEstadoPedido (solo si hay ítems en el detalle)
3. EN PREPARACIÓN  → trigger trg_DescontarStock descuenta inventario
4. LISTO           → cocina notifica que el pedido está terminado
5. EN CAMINO       → solo para canal Delivery (valida domicilio)
6. ENTREGADO       → confirmación de entrega al cliente
7. PAGADO          → sp_FinalizarPedido registra método de pago
8. CANCELADO       → sp_CancelarPedido (solo desde estados tempranos)
```

**Restricciones:** Los estados siguen una secuencia estricta. No se puede saltar de PENDIENTE a LISTO. El trigger `trg_ValidarTransicionEstado` rechaza transiciones inválidas con RAISERROR.

---

### P11: ¿Qué valida sp_CrearPedido antes de crear el pedido?

**Respuesta — validaciones en orden:**
1. Que el `cliente_id` exista en CLIENTES
2. Que el `canal_id` exista en CANALES
3. Si canal = Mesa: que `mesa_id` exista y no esté ocupada
4. Si canal = Delivery: que `domicilio_id` exista y pertenezca al cliente
5. Que la `sucursal_id` exista en SUCURSALES
6. Si todo pasa: INSERT en PEDIDOS con estado inicial = 1 (PENDIENTE)

Si alguna validación falla, retorna error con RAISERROR y hace ROLLBACK.

---

### P12: ¿Qué hace sp_FinalizarPedido?

**Respuesta:**
1. Valida que el pedido esté en estado ENTREGADO (no se puede finalizar antes)
2. Registra el método de pago (`efectivo`, `tarjeta`, `transferencia`, `mercadopago`)
3. Cambia el estado a PAGADO
4. Inserta en AUDITORIA_ESTADOS el registro del cambio
5. Si el canal era Mesa: libera la mesa (actualiza `esta_ocupada = 0`)

---

### P13: ¿Cuántos SPs tiene el sistema y cuáles son los más importantes?

**Respuesta — 19 SPs totales:**

| Grupo | SPs |
|---|---|
| Pedidos core | sp_CrearPedido, sp_CambiarEstadoPedido, sp_CancelarPedido, sp_FinalizarPedido |
| Ítems | sp_AgregarItemPedido, sp_EliminarItemPedido, sp_ModificarCantidadItem |
| Clientes | sp_CrearCliente, sp_ActualizarCliente, sp_AgregarDomicilio |
| Platos | sp_AgregarPlato, sp_ActualizarPrecio, sp_ObtenerPrecioVigente |
| Stock | sp_ActualizarStock, sp_ConsultarStock |
| Reportes | sp_ReportePedidosPorPeriodo, sp_ReporteVentasPorCanal, sp_ReportePlatosMasVendidos, sp_ReporteClientesFrecuentes |

---

## 📋 SECCIÓN 5 — Triggers

### P14: ¿Cuántos triggers tiene el sistema y qué hace cada uno?

**Respuesta — 5 triggers:**

| Trigger | Tabla | Evento | Función |
|---|---|---|---|
| `trg_ValidarTransicionEstado` | PEDIDOS | AFTER UPDATE | Rechaza cambios de estado inválidos (secuencia estricta) |
| `trg_AuditarCambioEstado` | PEDIDOS | AFTER UPDATE | Inserta registro en AUDITORIA_ESTADOS en cada cambio |
| `trg_DescontarStock` | PEDIDOS | AFTER UPDATE | Descuenta STOCKS_SIMULADOS cuando pasa a "En Preparación"; rechaza si stock < cantidad pedida |
| `trg_LiberarMesa` | PEDIDOS | AFTER UPDATE | Libera la mesa cuando el pedido llega a PAGADO o CANCELADO |
| `trg_NotificarCambioEstado` | PEDIDOS | AFTER UPDATE | Inserta en NOTIFICACIONES para alertas del sistema |

**Nota:** Los 5 triggers están en AFTER UPDATE sobre la tabla PEDIDOS, específicamente sobre la columna `estado_id`.

---

### P15: ¿Por qué todos los triggers están en AFTER UPDATE y no en INSTEAD OF?

**Respuesta:**
Porque queremos que el cambio de estado ocurra primero en la tabla, y luego el trigger reacciona a ese cambio. `INSTEAD OF` reemplazaría la operación original, lo que requeriría que el trigger hiciera el INSERT/UPDATE manualmente — más complejo y propenso a errores.

`AFTER UPDATE` permite que el motor procese el cambio y luego el trigger accede a las pseudotablas `inserted` (nuevo estado) y `deleted` (estado anterior) para validar y reaccionar.

---

## 📋 SECCIÓN 6 — Seguridad y Roles

### P16: ¿Qué esquema de seguridad implementaron?

**Respuesta:**
Implementamos **seguridad basada en roles** usando `DATABASE ROLE` de SQL Server. Hay **9 roles** con permisos granulares:

| Rol | Nivel de acceso |
|---|---|
| `rol_solo_lectura` | SELECT en vistas y tablas maestras |
| `rol_mozo` | Crear pedidos, agregar ítems, consultar estados |
| `rol_cocina` | Ver pedidos en preparación, actualizar estados de cocina |
| `rol_cajero` | Finalizar pedidos, registrar pagos |
| `rol_delivery` | Ver pedidos delivery, actualizar estado "En Camino" |
| `rol_supervisor` | Todo lo anterior + reportes básicos |
| `rol_gerente` | Todo + reportes avanzados + gestión de precios |
| `rol_administrador` | Control total del sistema |
| `rol_auditoria` | SELECT en AUDITORIA_ESTADOS y vistas de control |

Los permisos se otorgan sobre SPs y vistas, **no directamente sobre tablas**. Esto asegura que el acceso a datos siempre pase por la lógica del negocio.

---

### P17: ¿Por qué los permisos son sobre SPs y vistas, no sobre tablas directamente?

**Respuesta:**
Porque si los usuarios tuvieran acceso directo a las tablas podrían:
- Insertar pedidos sin pasar por las validaciones de `sp_CrearPedido`
- Cambiar estados saltándose la secuencia (sin que dispare `trg_ValidarTransicionEstado`)
- Modificar precios sin control de vigencia

Al forzar el acceso a través de SPs, la lógica de negocio y las validaciones siempre se ejecutan, independientemente de qué usuario realice la operación.

---

## 📋 SECCIÓN 7 — Vistas y Reportes

### P18: ¿Qué vistas implementaron y para qué sirven?

**Respuesta — 4 vistas:**

| Vista | Propósito |
|---|---|
| `vw_PedidosCompletos` | JOIN de PEDIDOS con cliente, canal, estado, mesa — una fila por pedido con todo el contexto |
| `vw_DetallePedidos` | JOIN de DETALLE_PEDIDOS con nombre del plato y precio unitario |
| `vw_StockBajo` | Filtra STOCKS_SIMULADOS donde `stock_actual < stock_minimo` — alerta de inventario |
| `vw_Dashboard` | Métricas agregadas: pedidos del día, ventas por canal, platos más vendidos |

Las vistas son de solo lectura y son el punto de acceso para los roles de consulta.

---

### P19: ¿Cómo funciona el sistema de reportes?

**Respuesta:**
El sistema tiene **4 SPs de reportes** que aceptan parámetros de fechas y devuelven resultados paginados o resumidos:

- `sp_ReportePedidosPorPeriodo(@fecha_inicio, @fecha_fin)` — todos los pedidos con totales
- `sp_ReporteVentasPorCanal(@fecha_inicio, @fecha_fin)` — desglose por canal (Mesa/Delivery/etc.)
- `sp_ReportePlatosMasVendidos(@top_n, @fecha_inicio, @fecha_fin)` — ranking de platos
- `sp_ReporteClientesFrecuentes(@top_n)` — clientes con más pedidos

Complementariamente, las vistas del dashboard (`Bundle_R2`) proveen datos en tiempo real sin parámetros.

---

## 📋 SECCIÓN 8 — Decisiones de Diseño (Preguntas difíciles)

### P20: ¿Qué pasa si dos mozos intentan crear un pedido en la misma mesa al mismo tiempo?

**Respuesta:**
Lo maneja `sp_CrearPedido` con una validación antes del INSERT:
```sql
IF EXISTS (SELECT 1 FROM MESAS WHERE mesa_id = @mesa_id AND esta_ocupada = 1)
    RAISERROR('La mesa ya está ocupada', 16, 1);
```

Para mayor robustez en concurrencia, el SP podría usar `SELECT ... WITH (UPDLOCK)` para bloquear la fila de la mesa durante la transacción. En la implementación actual, el nivel de aislamiento de SQL Server (`READ COMMITTED` por defecto) maneja la mayoría de los casos.

---

### P21: ¿Por qué una sola sucursal? ¿El sistema no escala a múltiples sucursales?

**Respuesta:**
El diseño sí contempla múltiples sucursales — la tabla SUCURSALES existe y PEDIDOS tiene FK a `sucursal_id`. La decisión de cargar solo una sucursal (Casa Central) fue de alcance del proyecto, no una limitación del modelo.

Para agregar una segunda sucursal, simplemente se insertaría un registro en SUCURSALES y todos los SPs ya aceptan `@sucursal_id` como parámetro.

---

### P22: ¿Por qué usaron DECIMAL en lugar de FLOAT para los montos?

**Respuesta:**
Porque `FLOAT` es un tipo de punto flotante binario que acumula errores de redondeo. Por ejemplo, `0.1 + 0.2` en FLOAT puede dar `0.30000000000000004` en lugar de `0.3`.

`DECIMAL(10,2)` almacena exactamente dos decimales, lo que es crítico para cálculos monetarios. Una diferencia de centavos en un sistema de facturación es inaceptable.

---

### P23: ¿El sistema valida que no se agreguen ítems a un pedido ya confirmado o pagado?

**Respuesta:**
Sí. `sp_AgregarItemPedido` valida que el pedido esté en estado **PENDIENTE** antes de permitir agregar ítems. Si el pedido ya fue confirmado o está en preparación, el SP rechaza la operación con RAISERROR.

Esta es la regla de negocio RN-006: el detalle del pedido solo es modificable mientras está en estado inicial.

---

### P24: ¿Cómo funciona el sistema de auditoría?

**Respuesta:**
El trigger `trg_AuditarCambioEstado` inserta automáticamente en `AUDITORIA_ESTADOS` cada vez que cambia `estado_id` en PEDIDOS. El registro incluye:
- `pedido_id` — qué pedido cambió
- `estado_anterior_id` y `estado_nuevo_id` — la transición
- `fecha_cambio` — timestamp exacto
- `usuario_sql` — quién ejecutó el cambio (`SYSTEM_USER`)

Esto permite reconstruir la historia completa de cualquier pedido y detectar anomalías. El rol `rol_auditoria` puede consultar esta tabla.

---

### P25: ¿Qué pasaría si borraran un plato que ya tiene pedidos históricos?

**Respuesta:**
El sistema lo previene a través de las **Foreign Keys con restricción `NO ACTION`** (comportamiento por defecto). Si se intenta hacer `DELETE` de un plato que aparece en DETALLE_PEDIDOS, SQL Server rechaza la operación con un error de FK.

Para "dar de baja" un plato del menú sin eliminarlo, se podría agregar una columna `activo BIT` en PLATOS y filtrar por `activo = 1` en las consultas. En la versión actual, los platos son permanentes una vez insertados.

---

## 📋 SECCIÓN 9 — Carga Masiva y Despliegue

### P26: ¿Cómo cargaron los datos de prueba?

**Respuesta:**
Con el **Bundle F** (`Bundle_F_Carga_Masiva.sql`), que genera los datos con T-SQL puro usando:
- Tablas temporales para staging
- Bucles `WHILE` con lógica de distribución realista
- `NEWID()` y `ABS(CHECKSUM(...))` para randomización reproducible
- Llamadas a los SPs del sistema (no INSERTs directos) para mantener integridad

**Volumen real insertado:**
- 3.004 clientes
- 2.986 domicilios
- 10.000 pedidos
- 30.001 ítems de detalle
- ~50.001 registros de auditoría
- Total: ~96.000 registros

No se usó BULK INSERT ni archivos CSV — todo está autocontenido en el script.

---

### P27: ¿Cómo se despliega el sistema desde cero?

**Respuesta — orden de ejecución de los bundles:**

```
CERO  → Reset completo (DROP de todo si existe)
A1    → Estructura de la base de datos (tablas, FKs, CHECKs)
A2    → Índices y datos maestros (estados, canales, mesas, sucursal, menú)
B1    → SPs de pedidos core (Crear, Cambiar, Cancelar, Finalizar)
B2    → SPs de ítems y cálculos (Agregar, Eliminar, Modificar cantidad)
B3    → SPs de estados y finalización
C     → Roles de seguridad y permisos
D     → Consultas básicas y vistas de uso frecuente
E1    → Triggers principales (ValidarTransicion, AuditarCambio, DescontarStock)
E2    → Control avanzado (LiberarMesa, NotificarCambio)
R1    → SPs de reportes
R2    → Vistas del dashboard
F     → Carga masiva de datos de prueba (opcional)
```

**Resultado verificado de un despliegue limpio:**
- 25/25 tests pasando en `TEST_Negocio.sql`
- 16 tablas, 19 SPs, 5 triggers, 4 vistas, 23 índices, 9 roles

---

## 📋 SECCIÓN 10 — Preguntas de Cierre

### P28: ¿Qué mejorarían del sistema si tuvieran más tiempo?

**Respuestas sugeridas (elegir 2-3):**
- **Combos y promociones:** Tabla COMBOS + COMBO_ITEMS con precio compuesto calculado
- **Múltiples mesas por pedido** (mesas combinadas para grupos grandes)
- **Sistema de fidelidad:** Puntos acumulados por compra, tabla PUNTOS_CLIENTES
- **Integración con pagos reales:** Webhook a Mercado Pago, estado "PAGO_PENDIENTE" adicional
- **Plato `activo BIT`** para dar de baja sin borrar historial
- **Soft delete** en CLIENTES (baja lógica en lugar de física)

---

### P29: ¿Cuál fue la decisión de diseño más difícil?

**Respuesta sugerida:**
Los **índices únicos filtrados**. El problema de cómo garantizar unicidad de email y documento cuando son opcionales (pueden ser NULL) no tiene una solución trivial con un UNIQUE convencional. La solución con `WHERE campo IS NOT NULL` requirió entender cómo SQL Server trata los NULLs en índices UNIQUE, y también descubrir que los índices filtrados requieren `SET QUOTED_IDENTIFIER ON` para funcionar correctamente en SPs y triggers — lo que nos llevó a revisar todos los bundles para agregar esa configuración.

---

### P30: ¿Qué garantiza que el sistema funciona correctamente?

**Respuesta:**
El archivo `TEST_Negocio.sql` en `06_Validacion_Post_Bundles/` contiene **25 tests end-to-end** que verifican:
- Creación de clientes con validaciones
- Flujo completo de pedido (PENDIENTE → PAGADO)
- Rechazo de transiciones de estado inválidas
- Control de stock (rechazo por stock insuficiente)
- Unicidad de UIX filtrados
- Funcionamiento de todos los SPs principales

**Resultado verificado:** ✅ 25/25 tests pasando en un despliegue limpio desde cero.

---

*Documento preparado para el examen parcial — EsbirrosDB v2.0 — Abril 2025*
