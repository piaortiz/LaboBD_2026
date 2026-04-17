# EsbirrosDB v2.0
## Sistema de Gestión de Pedidos — Bodegón Porteño

**Proyecto Académico - Laboratorio de Administración de Bases de Datos**  
**Profesor:** Carlos Alejandro Caraccio  
**Instituto:** ISTEA  
**Desarrollado por:** SQLeaders S.A.  
**Cliente Ficticio:** Bodegón Los Esbirros de Claudio  
**Fecha:** Abril 2026

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

EsbirrosDB es un sistema integral de gestión de pedidos diseñado para un **bodegón porteño**: restaurante tradicional de Buenos Aires conocido por su ambiente cálido, cocina casera y parrilla a la leña. El cliente ficticio es **Bodegón Los Esbirros de Claudio**, con sucursal en **San Telmo** (datos de Palermo eliminados de producción).

El modelo de datos es directo: cada ítem de pedido referencia siempre un plato individual, lo que simplifica la operatoria del restaurante y el modelo relacional.

### Canales de Venta Operativos
- **Presencial (65%)**: Atención en mesas del local
- **Delivery (35%)**: Entregas a domicilio
- **Nota**: App Móvil no implementada en esta versión

## Estructura del Proyecto

```
BodegonLinkEntrega/
├── RESUMEN_NEGOCIO.md                    # 📄 Presentación ejecutiva del proyecto
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
│   ├── 06_VALIDACION_POST_BUNDLES.sql
│   ├── 07_CARGA_MASIVA_DATOS.sql         # 🚀 Script de testing (10K+ pedidos)
│   └── README_CARGA_MASIVA.md            # 📋 Documentación de testing
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
- Gestión completa de clientes y direcciones de entrega
- Sistema de pedidos multicanal (Presencial + Delivery)
- Control de inventario simulado (STOCK_SIMULADO)
- Sistema de notificaciones automáticas (NOTIFICACIONES)
- Auditoría completa de operaciones (AUDITORIA_SIMPLE)
- Dashboard ejecutivo y reportes gerenciales

## Datos del Cliente Ficticio

**Bodegón Los Esbirros de Claudio** — Restaurante tradicional porteño
- **Sucursal activa:** San Telmo (Defensa 742)
- **Canales:** Presencial (65%) y Delivery (35%)
- **Menú:** 22 platos bodegón (empanadas, fideos, milanesas, parrilla, postres, bebidas)
- **Especialidad:** Cocina casera argentina, parrilla a la leña
- **Nota:** Datos de sucursal Palermo eliminados en versión actual

## Instalación y Despliegue

### Prerrequisitos
- Microsoft SQL Server 2019 o superior
- SQL Server Management Studio (SSMS)
- Permisos de administrador en la instancia SQL

### Orden de Instalación
```
Bundle CERO  → Reset completo (opcional, para reinstalación)
Bundle A1    → Estructura de BD y tablas
Bundle A2    → Índices y datos iniciales (solo San Telmo)
Bundle B1    → Stored Procedures CRUD
Bundle B2    → Stored Procedures de Reportes
Bundle B3    → Stored Procedures de Procesos
Bundle C     → Vistas de consolidación
Bundle D     → Triggers de automatización
Bundle E1    → Seguridad (roles y permisos)
Bundle E2    → Usuarios de aplicación
Bundle R1    → Validación del sistema
Bundle R2    → Consultas de ejemplo
Validación   → 06_VALIDACION_POST_BUNDLES.sql
Testing      → 07_CARGA_MASIVA_DATOS.sql (opcional, 10K+ pedidos)
```

Para instrucciones completas: **[03 - Guia de Despliegue Inicial.md](A%20-%20Documentacion%20Tecnica/03%20-%20Guia%20de%20Despliegue%20Inicial.md)**

## Tecnologías Utilizadas

- **Base de Datos:** Microsoft SQL Server
- **Herramientas:** SQL Server Management Studio
- **Documentación:** Markdown con diagramas Mermaid
- **Versionado:** Git

## Métricas del Proyecto

- **Tablas implementadas:** 12 principales + 4 auxiliares = 16 total
- **Stored Procedures:** 18
- **Triggers:** 5 activos
- **Vistas:** 4 (incluyendo dashboard)
- **Roles de seguridad:** 8
- **Usuarios de aplicación:** 3
- **Documentos técnicos:** 8
- **Scripts de testing:** 1 (carga masiva con 10K+ pedidos)

## Licencia

Este proyecto es desarrollado con fines académicos como parte del cursado de la materia Administración de Bases de Datos en ISTEA. El código y la documentación están disponibles para revisión y evaluación académica. **PROHIBIDA LA COMERCIALIZACIÓN.**

---

## Agradecimientos

Agradecimiento especial al profesor Victor Cordero por la guía y supervisión durante el desarrollo del proyecto, y al instituto ISTEA por proporcionar el marco académico para el aprendizaje de administración de bases de datos.
