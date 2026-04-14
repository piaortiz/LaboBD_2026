# Estado del Trabajo — EsbirrosDB v2.0

**Fecha:** 14 de abril de 2026  
**Equipo:** SQLeaders S.A.  
**Materia:** Laboratorio de Bases de Datos 2026 — ISTEA

---

## 1. PASO INMEDIATO: Probar Scripts en la Base de Datos

Antes de avanzar con cualquier entregable, hay que verificar que los 13 bundles compilan y ejecutan correctamente en SQL Server local.

### 1.1 — Prerrequisitos

- [ ] SQL Server 2017+ instalado (Express, Developer o Standard)
- [ ] SSMS (SQL Server Management Studio) abierto
- [ ] Conectado como `sa` o usuario con permisos de `sysadmin`
- [ ] No existe una base EsbirrosDB previa (o ejecutar Bundle CERO primero)

### 1.2 — Secuencia de Ejecución y Checklist

Ejecutar **conectado a `master`** el paso 0, luego cambiar a `EsbirrosDB` para el resto.

| # | Bundle | Archivo | Conectar a | Verificación rápida | Estado |
|---|--------|---------|------------|---------------------|--------|
| 0 | Reset | `Bundle_CERO_Reset_Completo.sql` | `master` | No existe EsbirrosDB en sys.databases | ☐ |
| 1 | A1 | `Bundle_A1_BaseDatos_Estructura.sql` | `master`→`EsbirrosDB` | 12 tablas creadas, FK sin error | ☐ |
| 2 | A2 | `Bundle_A2_Indices_Datos.sql` | `EsbirrosDB` | Índices creados, datos de referencia insertados, menú cargado | ☐ |
| 3 | B1 | `Bundle_B1_Pedidos_Core.sql` | `EsbirrosDB` | `sp_CrearPedido` existe | ☐ |
| 4 | B2 | `Bundle_B2_Items_Calculos.sql` | `EsbirrosDB` | `sp_AgregarItemPedido`, `sp_CalcularTotalPedido` existen | ☐ |
| 5 | B3 | `Bundle_B3_Estados_Finalizacion.sql` | `EsbirrosDB` | `sp_CerrarPedido`, `sp_CancelarPedido`, `sp_ActualizarEstadoPedido` existen | ☐ |
| 6 | C | `Bundle_C_Seguridad.sql` | `EsbirrosDB` | 8 roles `rol_*` creados, 3 usuarios `app_esbirros_*` | ☐ |
| 7 | D | `Bundle_D_Consultas_Basicas.sql` | `EsbirrosDB` | `vw_PedidosCompletos`, `vw_EstadoMesas` + 4 SPs de consulta | ☐ |
| 8 | E1 | `Bundle_E1_Triggers_Principales.sql` | `EsbirrosDB` | 3 triggers: `tr_ActualizarTotales`, `tr_AuditoriaPedidos`, `tr_AuditoriaDetalle` | ☐ |
| 9 | E2 | `Bundle_E2_Control_Avanzado.sql` | `EsbirrosDB` | `tr_ValidarStock`, `tr_SistemaNotificaciones`, tablas auxiliares | ☐ |
| 10 | R1 | `Bundle_R1_Reportes_Estructuras_SPs.sql` | `EsbirrosDB` | 5 SPs de reportes + tabla `REPORTES_GENERADOS` | ☐ |
| 11 | R2 | `Bundle_R2_Reportes_Vistas_Dashboard.sql` | `EsbirrosDB` | `vw_DashboardEjecutivo`, `vw_MonitoreoTiempoReal` | ☐ |
| **V** | **Validación** | `06_VALIDACION_POST_BUNDLES.sql` | `EsbirrosDB` | **≥ 90% éxito = SISTEMA FUNCIONAL** | ☐ |

### 1.3 — Pruebas funcionales post-despliegue

Después de la validación, ejecutar estas pruebas manuales:

```sql
-- TEST 1: Crear un pedido completo
DECLARE @pid INT, @msg NVARCHAR(500);
EXEC sp_CrearPedido @mesa_id=1, @mozo_id=1, @canal_id=1, @pedido_id=@pid OUTPUT, @mensaje=@msg OUTPUT;
PRINT 'Pedido: ' + CAST(@pid AS VARCHAR) + ' — ' + @msg;

-- TEST 2: Agregar items
EXEC sp_AgregarItemPedido @pedido_id=@pid, @plato_id=1, @cantidad=2, @mensaje=@msg OUTPUT;
PRINT @msg;

-- TEST 3: Calcular total
EXEC sp_CalcularTotalPedido @pedido_id=@pid;

-- TEST 4: Avanzar estado (Recibido → En Preparación)
EXEC sp_ActualizarEstadoPedido @pedido_id=@pid, @nuevo_estado='En Preparación', @mensaje=@msg OUTPUT;
PRINT @msg;

-- TEST 5: Cerrar pedido
EXEC sp_CerrarPedido @pedido_id=@pid, @mensaje=@msg OUTPUT;
PRINT @msg;

-- TEST 6: Verificar vistas
SELECT TOP 5 * FROM vw_DashboardEjecutivo;
SELECT TOP 5 * FROM vw_MonitoreoTiempoReal;

-- TEST 7: Reportes
EXEC sp_ReporteVentasDiario;
```

### 1.4 — Qué hacer si un bundle falla

| Error común | Causa probable | Solución |
|-------------|---------------|----------|
| "Database already exists" | EsbirrosDB anterior | Ejecutar Bundle CERO primero |
| "Invalid object name" | Bundles ejecutados fuera de orden | Respetar secuencia A1→A2→B1→...→R2 |
| "Login failed" | Permisos insuficientes | Conectar como `sa` |
| "Cannot find object" en trigger | Tabla auxiliar no existe | Verificar que E2 se ejecutó completo |

---

## 2. Estado General del Proyecto

### 2.1 — Lo que está HECHO

| Componente | Cantidad | Estado |
|------------|----------|--------|
| Tablas principales | 12 (A1) + 4 auxiliares = **16** | ✅ |
| Foreign Keys | 17 | ✅ |
| Stored Procedures | **19** | ✅ |
| Triggers | 5 | ✅ |
| Vistas | 4 | ✅ |
| Función escalar | 1 | ✅ |
| Roles de seguridad | 8 | ✅ |
| Cuentas servicio | 3 | ✅ |
| Índices | 11 | ✅ |
| CHECK constraints | 7 | ✅ |
| Documentación técnica | 8 documentos .md | ✅ |
| Script de validación | 06_VALIDACION | ✅ |
| Script de reset | Bundle CERO | ✅ |
| DER (Mermaid) | Documento 05 | ✅ |
| Reglas del negocio | Documento 06 | ✅ |
| Plan de backup | Documento 07 | ✅ |
| Hallazgos resueltos | 12 de 17 (71%) | ✅ |

### 2.2 — Lo que FALTA (4 entregables críticos)

| # | Entregable | Criticidad | Descripción | Estado |
|---|-----------|------------|-------------|--------|
| 1 | **BULK INSERT 10K registros** | 🔴 ALTA | Generar CSVs + script BULK INSERT para PEDIDO, DETALLE_PEDIDO, CLIENTE | ☐ Pendiente |
| 2 | **Documentación de IA** | 🔴 ALTA | Documento con prompts/código usado para generar los 10K registros | ☐ Pendiente |
| 3 | **Deploy en AWS RDS** | 🔴 ALTA | Instancia RDS SQL Server Express, desplegar BD, documentar | ☐ Pendiente |
| 4 | **Archivo .bak** | 🟡 MEDIA | Backup real de la BD después del bulk insert | ☐ Pendiente |

---

## 3. Roadmap de Trabajo

```
FASE 1 — AHORA
├── Probar scripts en SQL Server local (este checklist)
├── Verificar que el script de validación da ≥ 90%
└── Anotar cualquier error para corregir

FASE 2 — BULK INSERT
├── Generar 10.000+ registros (Python/IA)
├── Crear archivos CSV
├── Script BULK INSERT
└── Doc 09 con prompts/código de generación

FASE 3 — AWS
├── Crear instancia RDS (SQL Server Express, db.t3.micro)
├── Configurar Security Group (puerto 1433)
├── Ejecutar bundles en RDS
└── Documentar con capturas

FASE 4 — CIERRE
├── Generar .bak (local post-bulk insert)
├── Revisión final de documentación
└── Preparar defensa oral
```

---

## 4. Inventario de Archivos de Entrega

```
BodegonLinkEntrega/
├── A - Documentacion Tecnica/
│   ├── 01 - Requerimientos Tecnicos.md
│   ├── 02 - Diccionario de Datos.md
│   ├── 03 - Guia de Despliegue Inicial.md
│   ├── 04 - Carga de Datos Bodegon.md
│   ├── 05 - Modelo Entidad–Relación (DER).md
│   ├── 06 - Reglas del Negocio.md
│   ├── 07 - Plan de Backup y Recuperacion.md
│   ├── 08 - Glosario.md
│   └── 09 - Generacion de Datos con IA.md     ← FALTA CREAR
├── B - Scripts SQL/
│   ├── 00_Reset_Completo/Bundle_CERO_Reset_Completo.sql
│   ├── 01_Infraestructura_Base/Bundle_A1, Bundle_A2
│   ├── 02_Logica_Negocio/Bundle_B1, Bundle_B2, Bundle_B3
│   ├── 03_Seguridad_Consultas/Bundle_C, Bundle_D
│   ├── 04_Automatizacion_Avanzada/Bundle_E1, Bundle_E2
│   ├── 05_Reportes_Dashboard/Bundle_R1, Bundle_R2
│   └── 06_VALIDACION_POST_BUNDLES.sql
├── C - Datos Bulk Insert/                       ← FALTA CREAR
│   ├── datos_pedidos.csv
│   ├── datos_detalle_pedido.csv
│   └── script_bulk_insert.sql
└── EsbirrosDB_Full.bak                          ← FALTA GENERAR
```
