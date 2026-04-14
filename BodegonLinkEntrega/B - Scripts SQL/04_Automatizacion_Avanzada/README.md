# AUTOMATIZACIÓN AVANZADA - EsbirrosDB

**Orden de ejecución:** PASO 4  
**Dependencias:** Pasos 1-3 completados

## CONTENIDO DE LA CARPETA

### **Bundle_E1_Triggers_Principales.sql**
- **Propósito:** Triggers de totales automáticos y auditoría principal
- **Tiempo estimado:** 1 minuto
- **Crea:**
  - `tr_ActualizarTotales` — Recalcula `PEDIDO.total` automáticamente en INSERT/UPDATE/DELETE sobre DETALLE_PEDIDO
  - `tr_AuditoriaPedidos` — Registra cambios de estado y monto en AUDITORIA_SIMPLE
  - `tr_AuditoriaDetalle` — Registra INSERT/DELETE de ítems en AUDITORIA_SIMPLE
  - Tabla auxiliar: `AUDITORIA_SIMPLE`

### **Bundle_E2_Control_Avanzado.sql**
- **Propósito:** Control de inventario simulado y sistema de notificaciones
- **Tiempo estimado:** 1 minuto
- **Crea:**
  - `tr_ValidarStock` — Verifica stock disponible al agregar ítems
  - `tr_SistemaNotificaciones` — Genera notificaciones automáticas al cambiar estado de pedido
  - Tabla auxiliar: `STOCK_SIMULADO` (100 unidades por plato al inicio)
  - Tabla auxiliar: `NOTIFICACIONES`
  - SPs: `sp_ConsultarNotificaciones`, `sp_MarcarNotificacionLeida`, `sp_ConsultarStock`

## ORDEN DE EJECUCIÓN

1. Bundle_E1_Triggers_Principales.sql
2. Bundle_E2_Control_Avanzado.sql

## VALIDACIÓN

```sql
USE EsbirrosDB;

-- Verificar triggers activos
SELECT name, is_disabled
FROM sys.triggers
WHERE name IN (
    'tr_ActualizarTotales','tr_AuditoriaPedidos','tr_AuditoriaDetalle',
    'tr_ValidarStock','tr_SistemaNotificaciones'
)
-- Esperado: 5 triggers, is_disabled = 0

-- Verificar tablas auxiliares
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('AUDITORIA_SIMPLE','STOCK_SIMULADO','NOTIFICACIONES')
-- Esperado: 3 tablas

-- Verificar stock inicial cargado
SELECT COUNT(*) FROM STOCK_SIMULADO
-- Esperado: igual al número de platos (22)
```

## FUNCIONALIDAD DE NOTIFICACIONES

Las notificaciones se generan automáticamente cuando:
- Un pedido pasa a estado **Listo** → notificación a MOZOS (prioridad ALTA)
- Un pedido pasa a estado **Cerrado** → notificación a CAJA (prioridad NORMAL)

```sql
-- Consultar notificaciones no leídas para mozos
EXEC sp_ConsultarNotificaciones @usuario_destino = 'MOZOS', @solo_no_leidas = 1

-- Consultar stock bajo
EXEC sp_ConsultarStock @solo_stock_bajo = 1
```
