# Análisis de Requisitos del TP vs. Proyecto EsbirrosDB v2.0

**Fecha de análisis:** 14 de abril de 2026  
**Proyecto:** EsbirrosDB v2.0 — Sistema de Gestión de Pedidos para Bodegón Porteño  
**Equipo:** SQLeaders S.A.  
**Materia:** Laboratorio de Bases de Datos 2026  
**Instituto:** ISTEA

---

## 1. Requisitos YA CUMPLIDOS

| Requisito | Estado | Detalle |
|---|---|---|
| Caso de negocio elegido | ✅ Cumplido | Restaurante bodegón porteño (Los Esbirros de Claudio) — tema propio aprobado |
| Tablas con PK y cardinalidades | ✅ Cumplido | 16 tablas (12 principales + 4 auxiliares), 17 FK, constraints, relaciones bien armadas |
| Diagrama Entidad-Relación (DER) | ✅ Cumplido | Documento 05 con diagrama Mermaid completo embebido |
| Documentación respaldatoria | ✅ Cumplido | 8 documentos técnicos: tablas, vistas, índices, triggers, SPs, backup, glosario |
| Stored Procedures | ✅ Cumplido | 19 SPs (pedidos, reportes, estados, notificaciones, stock, seguridad) |
| Triggers | ✅ Cumplido | 5 triggers activos (auditoría, stock, totales, notificaciones) |
| Vistas | ✅ Cumplido | 4 vistas (vw_PedidosCompletos, vw_EstadoMesas, vw_DashboardEjecutivo, vw_MonitoreoTiempoReal) |
| Índices | ✅ Cumplido | 8+ índices de performance documentados |
| Plan de Backup y frecuencia | ✅ Cumplido | Documento 07 con estrategia 3-2-1, frecuencias definidas |
| Análisis del negocio | ✅ Cumplido | Documento 06 (Reglas del Negocio) |
| Seguridad y roles | ✅ Cumplido | 8 roles con permisos granulares + usuarios app_esbirros_* |
| Eliminación de combos/promociones | ✅ Cumplido | COMBO, COMBO_DETALLE, PROMOCION, PROMOCION_PLATO eliminadas |

---

## 2. Requisitos FALTANTES (Críticos)

### 2.1 — Bulk Insert con 10.000 registros

- **Criticidad:** 🔴 ALTA
- **Qué pide el profesor:** Un archivo con **10.000 registros** para algunas de las tablas y el **script SQL de BULK INSERT** usado para cargarlos.
- **Estado actual:** Los datos actuales son solo los de referencia y menú (Bundle_A2): ~100 registros. No hay archivos CSV ni script BULK INSERT real.
- **Qué hacer:**
  1. Generar archivos CSV con 10.000+ registros ficticios (PEDIDO, DETALLE_PEDIDO, CLIENTE, EMPLEADO, MESA).
  2. Crear el script SQL con `BULK INSERT ... FROM 'archivo.csv'` para cargar esos datos.
  3. Incluir ambos archivos en la entrega.
- **Referencia:** Ver documento `04 - Carga de Datos Bodegon.md` §3 para el script de referencia.

---

### 2.2 — Documentación de Inteligencia Artificial

- **Criticidad:** 🔴 ALTA
- **Qué pide el profesor:** Detallar el **prompt exacto** que se le indicó a la IA (y qué IA se usó) **o** el **código fuente** (ej: Python) usado para generar los 10.000 registros ficticios.
- **Estado actual:** No existe ningún documento de IA en el proyecto.
- **Qué hacer:**
  1. Crear `A - Documentacion Tecnica/09 - Generacion de Datos con IA.md` que incluya:
     - Qué IA/herramienta se usó (ChatGPT, Copilot, script Python, etc.)
     - El prompt exacto utilizado
     - O el código fuente Python/otro usado para generar los datos
  2. Agregar este documento a la entrega.

---

### 2.3 — Entorno en AWS (RDS con SQL Server Express)

- **Criticidad:** 🔴 ALTA
- **Qué pide el profesor:** Levantar la base de datos en la nube usando **AWS RDS con SQL Server Express Edition**.
- **Estado actual:** El proyecto solo contempla instalación local. No hay ninguna referencia a AWS/RDS en los scripts (solo en documentación de requerimientos y mejorespracticas.md).
- **Qué hacer:**
  1. Crear una instancia de **AWS RDS** con SQL Server Express (db.t3.micro, elegible Free Tier).
  2. Desplegar EsbirrosDB en esa instancia (ejecutar bundles A1→R2).
  3. Documentar el proceso: capturas de pantalla, configuración de Security Group, endpoint.
  4. Tener en cuenta que algunas features se muestran desde local por limitaciones de Express.

---

### 2.4 — Archivo .bak de Backup

- **Criticidad:** 🟡 MEDIA
- **Qué pide el profesor:** Entregar un **archivo de copia de seguridad** (.bak) de la base de datos.
- **Estado actual:** El plan de backup está documentado (doc 07), pero **no se incluye un archivo .bak real**.
- **Qué hacer:**
  1. Generar el backup desde SSMS:
     ```sql
     BACKUP DATABASE EsbirrosDB
     TO DISK = 'EsbirrosDB_Full.bak'
     WITH FORMAT, COMPRESSION, STATS = 10;
     ```
  2. Incluir el archivo .bak en la entrega (o enlace de descarga si es muy pesado).

---

## 3. Aspectos a VERIFICAR

### 3.1 — Volumen de datos insuficiente

- **Problema:** Con los datos actuales (~100 registros de referencia) no se puede demostrar performance real de índices ni consultas complejas.
- **Acción:** Ejecutar el bulk insert de 10.000+ registros antes de la demostración en vivo.

### 3.2 — Tablas COMBO/PROMOCION (RESUELTO en v2.0)

- **Estado:** ✅ RESUELTO — Las tablas COMBO, COMBO_DETALLE, PROMOCION y PROMOCION_PLATO fueron **eliminadas** en EsbirrosDB v2.0. El script de validación verifica que no existan.

### 3.3 — Fechas vigentes en 2026

- **Estado:** ✅ RESUELTO — Los precios tienen `vigencia_desde = '2026-01-01'` con `vigencia_hasta = NULL`. Los reportes y el dashboard funcionarán correctamente en 2026.

### 3.4 — AWS RDS vs. Local

- **Problema:** El profesor acepta que algunas cosas se muestren desde local (por limitaciones de Express en la nube), pero la BD tiene que estar levantada en RDS.
- **Acción:** Documentar claramente qué se muestra desde AWS y qué desde local, y por qué.

---

## 4. Plan de Acción Sugerido (Priorizado)

| Prioridad | Tarea | Responsable sugerido |
|---|---|---|
| 🔴 1 | Generar 10.000 registros con script Python o IA (PEDIDO, DETALLE_PEDIDO, CLIENTE) | Developer SQL |
| 🔴 2 | Crear script `BULK INSERT` que cargue los 10K registros desde CSV | Developer SQL |
| 🔴 3 | Documentar proceso de IA: prompt usado, herramienta, código fuente (doc 09) | QA / Editor |
| 🔴 4 | Levantar BD en AWS RDS (SQL Server Express, db.t3.micro) y documentar proceso | DBA |
| 🟡 5 | Generar archivo .bak real y agregarlo a la entrega | DBA |
| 🟢 6 | Preparar la demostración en vivo: ejecutar reportes, mostrar dashboard | Todo el equipo |

---

## 5. Resumen Ejecutivo

| Categoría | Cantidad |
|---|---|
| Requisitos cumplidos | 12 |
| Requisitos faltantes (críticos) | 4 |
| Aspectos verificados/mejorados | 4 |

**EsbirrosDB v2.0 tiene una base sólida**: buena arquitectura, documentación profesional, funcionalidad completa y la adaptación del negocio completada (bodegón porteño, sin combos/promociones). Los 4 faltantes críticos son los mismos que en v1.0: **volumen de datos (BULK INSERT 10K)**, **documentación de IA**, **despliegue en AWS** y **backup .bak**. Con estas adiciones, el proyecto estaría listo para la evaluación.

> **Ventaja respecto a v1.0:** Se eliminó el problema de las tablas vacías (COMBO/PROMOCION) que podría generar preguntas durante la defensa. El modelo simplificado es más fácil de explicar y defender.
