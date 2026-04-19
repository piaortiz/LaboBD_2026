# 🍽️ PROYECTO: SISTEMA DE GESTIÓN ESBIRROSDB

## 📋 Información del Proyecto

**Institución:** ISTEA - Instituto Superior de Tecnología en Administración  
**Materia:** Laboratorio de Administración de Bases de Datos  
**Profesor:** Carlos Alejandro Caraccio  
**Año:** 2026  
**Tipo de Proyecto:** Sistema de gestión integral para bodegón porteño

---

## 🏢 Descripción del Negocio

**Razón Social:** Bodegón Los Esbirros de Claudio  
**Rubro:** Gastronomía - Bodegón tradicional argentino  
**Ubicación:** San Telmo, Ciudad Autónoma de Buenos Aires  
**Modelo de Negocio:** Restaurante con atención presencial en local + servicio de delivery

---

## ⚙️ Flujo Operativo Completo

### 📋 Ciclo de Vida de un Pedido

```
┌─────────────────┐
│ 1. RECEPCIÓN    │  Cliente ingresa (presencial/delivery)
│                 │  → Validación de cliente/dirección
└────────┬────────┘
         │
┌────────▼────────┐
│ 2. REGISTRO     │  sp_CrearPedido → Genera cabecera
│                 │  sp_AgregarDetallePedido → Agrega items
│                 │  → Trigger: trg_ActualizarTotalPedido (calcula $)
│                 │  → Trigger: trg_AuditoriaPedidos (registra log)
└────────┬────────┘
         │
┌────────▼────────┐
│ 3. STOCK        │  Trigger: trg_ActualizarStock (descuenta)
│                 │  ¿Stock < 10? → trg_NotificacionStockBajo
└────────┬────────┘
         │
┌────────▼────────┐
│ 4. PREPARACIÓN  │  Cocina: Pendiente → En Preparación → Listo
│                 │  → Cada cambio auditado automáticamente
└────────┬────────┘
         │
┌────────▼────────┐
│ 5. ENTREGA      │  Mozo/Repartidor: Listo → Entregado
│                 │  → Cierre de pedido
└─────────────────┘
```

### 🔄 Automatizaciones Clave
| Trigger | Evento | Acción |
|---------|--------|--------|
| `trg_ActualizarTotalPedido` | INSERT/UPDATE en PEDIDOS_DETALLE | Recalcula total del pedido |
| `trg_AuditoriaPedidos` | INSERT/UPDATE/DELETE en PEDIDOS | Registra en AUDITORIA_SIMPLE |
| `trg_AuditoriaClientes` | INSERT/UPDATE/DELETE en CLIENTES | Registra en AUDITORIA_SIMPLE |
| `trg_ActualizarStock` | INSERT en PEDIDOS_DETALLE | Descuenta stock de plato |
| `trg_NotificacionStockBajo` | UPDATE en STOCK_SIMULADO | Alerta si stock < 10 |

---

## 🏗️ Arquitectura de Base de Datos

### Modelo Relacional: 16 Tablas + Componentes Programáticos

#### 📦 Tablas Core del Negocio (12)
| Módulo | Tabla | Propósito |
|--------|-------|-----------|
| **Infraestructura** | SUCURSALES | Gestión de sucursales (San Telmo activa) |
| **Clientes** | CLIENTES | Datos maestros de clientes (DNI, contacto) |
| | DIRECCIONES_CLIENTES | Múltiples direcciones de entrega por cliente |
| **Productos** | CATEGORIAS | Categorización del menú |
| | INGREDIENTES | Maestro de ingredientes |
| | PLATOS | Menú completo con precios actuales |
| | PLATOS_INGREDIENTES | Recetas (relación N:M) |
| | LOGS_CAMBIOS_PRECIOS | Histórico de ajustes de precio |
| **Ventas** | CANALES_VENTA | Presencial (65%), Delivery (35%) |
| | ESTADOS_PEDIDO | Workflow de pedidos (4 estados) |
| | PEDIDOS | Cabecera de pedidos (maestro) |
| | PEDIDOS_DETALLE | Items individuales (detalle) |

#### 🔧 Tablas Auxiliares (4)
| Tabla | Función | ¿Tiene FK? |
|-------|---------|------------|
| **AUDITORIA_SIMPLE** | Log de operaciones críticas | ❌ NO (ver explicación abajo) |
| **STOCK_SIMULADO** | Inventario de platos | ✅ SÍ (FK a PLATOS) |
| **NOTIFICACIONES** | Sistema de alertas automáticas | ⚠️ Parcial (puede referenciar eliminados) |
| **REPORTES_GENERADOS** | Histórico de reportes ejecutados | ✅ SÍ (FK a SUCURSALES) |

#### ⚙️ Componentes Programáticos
- **12 Stored Procedures**: 6 operaciones CRUD, 5 reportes gerenciales, 1 auditoría de seguridad
- **4 Views**: Dashboard ejecutivo, monitoreo en tiempo real, pedidos completos, estado de mesas
- **5 Triggers**: Cálculo de totales, auditoría (x2), control de stock, notificaciones
- **9 Roles de Seguridad**: Administrador, Gerente, Mozo, Cajero, Cocinero, Delivery, Cliente, Reportes, App Web
- **3 Usuarios de Aplicación**: app_esbirros_web, app_esbirros_reportes, app_esbirros_delivery
- **19 Empleados**: Distribuidos por roles según horarios de atención (almuerzo/cena)

---

---

## 🔍 DECISIÓN DE DISEÑO: ¿Por qué AUDITORIA_SIMPLE no tiene Foreign Keys?

### 🎯 Explicación Breve

En el DER, la tabla `AUDITORIA_SIMPLE` aparece **sin relaciones (Foreign Keys)** hacia otras tablas. **Esto es intencional**, no un error.

### 📐 Estructura Simplificada

```sql
CREATE TABLE AUDITORIA_SIMPLE (
    id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
    tabla_afectada NVARCHAR(100),  -- 'PEDIDOS', 'CLIENTES', etc.
    registro_id INT,                -- ID del registro modificado
    operacion NVARCHAR(50),         -- 'INSERT', 'UPDATE', 'DELETE'
    usuario NVARCHAR(100),          -- Usuario responsable
    fecha_hora DATETIME,
    descripcion NVARCHAR(MAX)
    -- ⚠️ SIN Foreign Keys intencionalmente
);
```

### ✅ 3 Razones Fundamentales

#### **1. Independencia del Ciclo de Vida**
- La auditoría debe **sobrevivir a la eliminación** de datos originales
- Si tuviera FK: al eliminar un pedido se perdería su histórico (CASCADE) o no se podría eliminar (RESTRICT)
- Sin FK: se elimina el pedido pero su log de auditoría permanece intacto

**Ejemplo:**
```sql
DELETE FROM PEDIDOS WHERE id_pedido = 500;
-- ✅ El pedido se elimina, pero AUDITORIA_SIMPLE conserva el registro
-- de que existió, quién lo creó, cuándo, y que fue eliminado
```

#### **2. Auditoría Multi-Tabla (Patrón Polimórfico)**
- `AUDITORIA_SIMPLE` registra cambios de **múltiples tablas**:
  - `tabla_afectada = 'PEDIDOS'` → `registro_id` apunta a un pedido
  - `tabla_afectada = 'CLIENTES'` → `registro_id` apunta a un cliente
  - `tabla_afectada = 'PLATOS'` → `registro_id` apunta a un plato
- **No es posible** crear una FK que apunte a múltiples tablas simultáneamente
- La integridad es **lógica** (controlada por la aplicación), no física

#### **3. Patrón Estándar de la Industria**
- Mismo diseño usado en:
  - SQL Server Temporal Tables
  - Hibernate Envers (Java)
  - Sistemas bancarios y de auditoría empresarial
- Cumple con normativas de auditoría (SOX, ISO 27001)
- Garantiza **inmutabilidad del registro histórico**

### 🎓 Conclusión

La ausencia de FK en `AUDITORIA_SIMPLE` es una **decisión de diseño profesional** que:
- ✅ Preserva el histórico completo del sistema
- ✅ Permite auditar múltiples tablas con una sola estructura
- ✅ Sigue mejores prácticas reconocidas en la industria

> **Principio aplicado:** *"Las tablas de auditoría deben ser testigos independientes de los hechos, no participantes activos en las relaciones del modelo operacional."*

---

## 📈 Métricas y Capacidades del Sistema

### 📊 Estado Actual (Base de Datos Operativa)
| Componente | Cantidad | Detalle |
|------------|----------|---------|
| **Sucursales** | 1 activa | San Telmo (Defensa 742) |
| **Platos en menú** | 22 | Entradas, Pastas, Carnes, Postres, Bebidas |
| **Mesas** | 8 | Capacidad 2-10 comensales (~50 personas) |
| **Stock inicial** | 2,200 unidades | 100 unidades por plato |
| **Canales operativos** | 2 | Presencial (65%), Delivery (35%) |
| **Estados de pedido** | 4 | Pendiente → En Preparación → Listo → Entregado |
| **Stored Procedures** | 12 | 6 CRUD + 5 Reportes + 1 Auditoría |
| **Views** | 4 | Dashboard, Monitoreo, Pedidos, Mesas |
| **Triggers** | 5 | Totales, Auditoría (x2), Stock, Notificaciones |
| **Roles de seguridad** | 9 | Admin, Gerente, Mozo, Cajero, Cocinero, Delivery, Hostess, Reportes, App |
| **Usuarios de app** | 3 | app_esbirros_web, app_esbirros_reportes, app_esbirros_delivery |
| **Empleados** | 19 | Distribuidos por turnos (almuerzo/cena) |

### 🚀 Capacidad de Carga Masiva (Testing)
El sistema incluye un script de prueba (`07_CARGA_MASIVA_DATOS.sql`) capaz de generar:
- **3,000 clientes** con datos realistas
- **4,500 direcciones** (1.5 promedio por cliente)
- **10,000 pedidos** distribuidos en 6 meses
- **~30,000 items de pedido** (3 items promedio)
- **500 registros de auditoría** adicionales
- **1,000 notificaciones** automáticas

**Tiempo de ejecución estimado:** 5-10 minutos  
**Propósito:** Performance testing y validación de escalabilidad

---

## 🔐 Seguridad y Control de Acceso

### Roles Implementados (9 roles)
| Rol | Permisos | Empleados Asignados |
|-----|----------|---------------------|
| **rol_administrador** | Control total del sistema | 1 Administrador |
| **rol_gerente** | Reportes, configuración, gestión operativa | 1 Gerente |
| **rol_mozo** | Toma de pedidos, consulta mesas, actualizar estados | 6 Mozos (3 almuerzo + 3 cena) |
| **rol_cajero** | Operaciones de caja, cierre de pedidos | 2 Cajeros (1 por turno) |
| **rol_cocinero** | Ver pedidos, actualizar estados de preparación | 4 Cocineros (2 por turno) |
| **rol_delivery** | Ver pedidos delivery, actualizar entregas | 3 Repartidores (turno cena) |
| **rol_hostess** | Gestión de mesas, recepción de clientes | 2 Hostess (1 por turno) |
| **rol_reportes** | Ejecución de reportes gerenciales | Acceso para reportes |
| **rol_aplicacion_web** | Permisos para aplicación web | App externa |
| **rol_cliente** | Lectura de menú y propios pedidos | Acceso clientes |

**Total empleados:** 19 personas distribuidas según horarios de atención

### Horarios del Bodegón
- **Lunes a Sábado:** 12:00-16:00 (almuerzo) y 20:00-00:00 (cena)
- **Domingo:** 12:00-17:00 (solo almuerzo)
- **Capacidad:** 8 mesas (2-10 comensales) = ~50 personas simultáneas

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| **SGBD** | Microsoft SQL Server 2019+ |
| **Lenguaje** | T-SQL (Transact-SQL) |
| **Diagramación** | Mermaid (DER adjunto) |
| **Versionado** | GitHub ([piaortiz/LaboBD_2026](https://github.com/piaortiz/LaboBD_2026)) |
| **Documentación** | Markdown |
| **Instalación** | Modular (Bundles A1→R2) |

---

## 📂 Estructura de Entrega Académica

```
BodegonLinkEntrega/
│
├── 📄 DER_MERMAID.md                    # Diagrama Entidad-Relación completo
├── 📄 RESUMEN_NEGOCIO.md                # Este documento (presentación ejecutiva)
│
├── 📁 Scripts_Instalacion/
│   ├── Bundle_A1_CreacionDB.sql         # Creación de base de datos y tablas
│   ├── Bundle_A2_Indices_Datos.sql      # Índices y datos iniciales
│   ├── Bundle_B1_SP_CRUD.sql            # Stored Procedures CRUD
│   ├── Bundle_B2_SP_Reportes.sql        # Stored Procedures de reportes
│   ├── Bundle_B3_SP_Procesos.sql        # Stored Procedures de procesos
│   ├── Bundle_C_Vistas.sql              # Views de consolidación
│   ├── Bundle_D_Triggers.sql            # Triggers de automatización
│   ├── Bundle_E1_Seguridad.sql          # Roles y permisos
│   ├── Bundle_E2_Usuarios.sql           # Usuarios de aplicación
│   ├── Bundle_R1_ValidacionSistema.sql  # Script de validación
│   └── Bundle_R2_ConsultasEjemplo.sql   # Consultas de demostración
│
└── 📁 Testing/ (Opcional)
    ├── 07_CARGA_MASIVA_DATOS.sql        # Script de carga masiva
    └── README_CARGA_MASIVA.md           # Documentación de testing
```

---

## ✅ Validación y Cumplimiento de Requisitos

### ✓ Requisitos Funcionales
- [x] Gestión completa de clientes y direcciones
- [x] Sistema de pedidos multicanal (Presencial + Delivery)
- [x] Control de stock automático
- [x] Sistema de notificaciones
- [x] Auditoría de operaciones críticas
- [x] Reportes gerenciales

### ✓ Requisitos No Funcionales
- [x] Integridad referencial (12 tablas con FK correctas)
- [x] Auditoría independiente (AUDITORIA_SIMPLE sin FK - diseño intencional)
- [x] Automatización mediante triggers
- [x] Seguridad basada en roles
- [x] Escalabilidad (probado con 10K+ pedidos)
- [x] Documentación completa

### ✓ Requisitos Académicos
- [x] DER completo en Mermaid
- [x] Resumen ejecutivo del negocio
- [x] Justificación de decisiones de diseño
- [x] Scripts modulares e instalables
- [x] Código comentado y autodocumentado
- [x] Control de versiones (GitHub)

---

## 🎯 Conclusiones y Lecciones del Proyecto

### 💡 Aprendizajes Clave

1. **Diseño Intencional vs. Error**
   - No todas las tablas deben tener FK
   - Las tablas de auditoría requieren independencia
   - Justificar decisiones de diseño es crucial

2. **Automatización Efectiva**
   - Los triggers reducen errores humanos
   - Calculan totales, auditan cambios, controlan stock
   - Evitan inconsistencias de datos

3. **Seguridad por Capas**
   - Roles granulares
   - Usuarios de aplicación
   - Auditoría de todas las operaciones críticas

4. **Escalabilidad desde el Diseño**
   - Estructura modular
   - Preparado para múltiples sucursales
   - Testeo con volumen realista (10K+ registros)

### 📐 Principios de Diseño Aplicados

- **Separación de Concerns**: Tablas operacionales vs. auxiliares
- **Inmutabilidad de Logs**: Auditoría que sobrevive a los datos
- **Automatización Inteligente**: Triggers solo donde agregan valor
- **Seguridad by Design**: Control de acceso desde el inicio
- **Documentación como Código**: Scripts autoexplicativos

---

## 📞 Información del Proyecto

**Materia:** Laboratorio de Administración de Bases de Datos  
**Profesor:** Carlos Alejandro Caraccio  
**Institución:** ISTEA  
**Año Académico:** 2026  
**Tipo:** Proyecto Final Integrador  
**Estado:** ✅ Completado y Validado  

**Repositorio:** [github.com/piaortiz/LaboBD_2026](https://github.com/piaortiz/LaboBD_2026)  
**Negocio:** Bodegón Los Esbirros de Claudio (San Telmo, CABA)  
**Base de Datos:** EsbirrosDB

---

### 📋 Checklist de Entrega

- [x] DER completo en formato Mermaid
- [x] Resumen ejecutivo del negocio
- [x] Explicación de decisión de diseño (AUDITORIA_SIMPLE sin FK)
- [x] Scripts de instalación modulares
- [x] Scripts de validación
- [x] Documentación técnica
- [x] Scripts de testing (opcional)
- [x] Repositorio GitHub actualizado

---

**Preparado por:** Equipo de Desarrollo EsbirrosDB  
**Fecha:** Abril 2026  
**Versión:** 1.0 - Entrega Final  
