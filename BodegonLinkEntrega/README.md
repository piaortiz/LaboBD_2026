# EsbirrosDB v2.0
## Sistema de Gestión de Pedidos — Bodegón Porteño

**Proyecto Académico - Administración de Bases de Datos**  
**Profesor:** Victor Cordero  
**Instituto:** ISTEA  
**Desarrollado por:** SQLeaders S.A.  
**Cliente Ficticio:** Bodegón Los Esbirros de Claudio  
**Fecha:** 2026

---

## Equipo de Desarrollo — SQLeaders S.A.

<div align="center">
  <table>
    <tr>
      <td align="center">
        <strong>Mariapía Ortiz</strong><br/>
        <em>Project Manager</em>
      </td>
      <td align="center">
        <strong>Adrián Barletta</strong><br/>
        <em>Database Administrator</em>
      </td>
      <td align="center">
        <strong>Franco Emmert</strong><br/>
        <em>QA / Editor</em>
      </td>
    </tr>
    <tr>
      <td align="center">
        <strong>Agustín Acosta</strong><br/>
        <em>Developer SQL</em>
      </td>
      <td align="center">
        <strong>Lucas Miedwiediew</strong><br/>
        <em>Developer SQL</em>
      </td>
      <td></td>
    </tr>
  </table>
</div>

---

## Descripción del Proyecto

EsbirrosDB es un sistema integral de gestión de pedidos diseñado para un **bodegón porteño**: restaurante tradicional de Buenos Aires conocido por su ambiente cálido, cocina casera y parrilla a la leña. El cliente ficticio es **Bodegón Los Esbirros de Claudio**, con dos sucursales: San Telmo y Palermo.

El modelo de datos es directo: cada ítem de pedido referencia siempre un plato individual, lo que simplifica la operatoria del restaurante y el modelo relacional.

## Estructura del Proyecto

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
│   ├── 01_Infraestructura_Base/
│   ├── 02_Logica_Negocio/
│   ├── 03_Seguridad_Consultas/
│   ├── 04_Automatizacion_Avanzada/
│   ├── 05_Reportes_Dashboard/
│   └── 06_VALIDACION_POST_BUNDLES.sql
├── ANALISIS_REQUISITOS_TP.md
└── RESUMEN_ADAPTACION.md
```

## Características Técnicas

### Base de Datos
- **12 tablas principales** completamente normalizadas (3FN) + 4 auxiliares (16 total)
- **Motor:** Microsoft SQL Server
- **Triggers automáticos** para integridad referencial y auditoría
- **Stored procedures** para todas las operaciones críticas

### Seguridad
- **8 roles específicos** con permisos granulares
- Sistema de auditoría automático (AUDITORIA_SIMPLE)
- Control de acceso por funcionalidad
- Usuarios sin login para acceso desde aplicación

### Funcionalidades Principales
- Gestión completa de mesas con QR tokens
- Sistema de pedidos con estados automatizados
- Control de inventario simulado (STOCK_SIMULADO)
- Sistema de notificaciones internas (NOTIFICACIONES)
- Dashboard ejecutivo y monitoreo en tiempo real

## Datos del Cliente Ficticio

**Bodegón Los Esbirros de Claudio** — Restaurante tradicional porteño
- **Sucursales:** San Telmo (Defensa 742) y Palermo (Thames 1850)
- **Capacidad:** 2 sucursales, múltiples mesas
- **Menú:** 22 platos bodegón (empanadas, fideos, milanesas, parrilla, postres, bebidas)
- **Especialidad:** Cocina casera argentina, parrilla a la leña

## Instalación y Despliegue

### Prerrequisitos
- Microsoft SQL Server 2019 o superior
- SQL Server Management Studio (SSMS)
- Permisos de administrador en la instancia SQL

### Orden de Instalación
```
Bundle CERO  → Reset completo (opcional, para reinstalación)
Bundle A1    → Estructura de BD y tablas
Bundle A2    → Índices, datos de referencia y menú del bodegón
Bundle B1    → sp_CrearPedido
Bundle B2    → sp_AgregarItemPedido, sp_CalcularTotalPedido
Bundle B3    → sp_CerrarPedido, sp_CancelarPedido, sp_ActualizarEstadoPedido
Bundle C     → Roles y seguridad
Bundle D     → Consultas y vistas base
Bundle E1    → Triggers de totales y auditoría
Bundle E2    → Stock simulado y notificaciones
Bundle R1    → Stored procedures de reportes
Bundle R2    → Vistas de dashboard
Validación   → 06_VALIDACION_POST_BUNDLES.sql
```

Para instrucciones completas: **[03 - Guia de Despliegue Inicial.md](A%20-%20Documentacion%20Tecnica/03%20-%20Guia%20de%20Despliegue%20Inicial.md)**

## Tecnologías Utilizadas

- **Base de Datos:** Microsoft SQL Server
- **Herramientas:** SQL Server Management Studio
- **Documentación:** Markdown con diagramas Mermaid
- **Versionado:** Git

## Métricas del Proyecto

- **Tablas implementadas:** 12 principales + 4 auxiliares = 16 total
- **Stored Procedures:** 19
- **Triggers:** 5 activos
- **Vistas:** 4 (incluyendo dashboard)
- **Roles de seguridad:** 8
- **Documentos técnicos:** 8

## Licencia

Este proyecto es desarrollado con fines académicos como parte del cursado de la materia Administración de Bases de Datos en ISTEA. El código y la documentación están disponibles para revisión y evaluación académica. **PROHIBIDA LA COMERCIALIZACIÓN.**

---

## Agradecimientos

Agradecimiento especial al profesor Victor Cordero por la guía y supervisión durante el desarrollo del proyecto, y al instituto ISTEA por proporcionar el marco académico para el aprendizaje de administración de bases de datos.
