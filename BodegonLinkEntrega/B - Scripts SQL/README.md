# B - Scripts SQL - EsbirrosDB

**Cliente:** Bodegón Los Esbirros de Claudio  
**Desarrollado por:** SQLeaders S.A.  
**Versión:** 2.0  
**Fecha:** 2026

---

## CONTENIDO DE LA CARPETA

Esta carpeta contiene **todos los scripts SQL** necesarios para el despliegue completo del sistema EsbirrosDB, organizados por funcionalidad en subcarpetas específicas.

### **Estructura Organizada**

```
B - Scripts SQL/
├── 00_Reset_Completo/              ← Opcional: limpiar instalación anterior
├── 01_Infraestructura_Base/        ← Paso 1: Estructura y datos básicos
├── 02_Logica_Negocio/              ← Paso 2: SPs y lógica de pedidos
├── 03_Seguridad_Consultas/         ← Paso 3: Seguridad y consultas
├── 04_Automatizacion_Avanzada/     ← Paso 4: Triggers y automatización
├── 05_Reportes_Dashboard/          ← Paso 5: Sistema de reportes
└── 06_VALIDACION_POST_BUNDLES.sql  ← Validación final del sistema
```

---

## INICIO RÁPIDO

### **Para desplegar desde cero:**

1. **LEER PRIMERO:** `../A - Documentacion Tecnica/03 - Guia de Despliegue Inicial.md`
2. **EJECUTAR en orden:** Scripts de cada subcarpeta (01 → 02 → 03 → 04 → 05)
3. **VALIDAR:** Ejecutar `06_VALIDACION_POST_BUNDLES.sql`

### **Orden de ejecución crítico:**

| **Paso** | **Carpeta** | **Descripción** | **Tiempo estimado** |
|----------|-------------|-----------------|---------------------|
| **0** | `00_Reset_Completo/` | Reset (solo si reinstalando) | 1 minuto |
| **1** | `01_Infraestructura_Base/` | Tablas, índices, datos básicos | 5 minutos |
| **2** | `02_Logica_Negocio/` | SPs de pedidos y cálculos | 8 minutos |
| **3** | `03_Seguridad_Consultas/` | Roles, permisos, vistas | 6 minutos |
| **4** | `04_Automatizacion_Avanzada/` | Triggers y controles | 7 minutos |
| **5** | `05_Reportes_Dashboard/` | Sistema completo de reportes | 8 minutos |
| **Final** | Validación completa | Verificar instalación | 2 minutos |

---

## ARCHIVOS PRINCIPALES

### **Guía de Despliegue Principal**
- **Ubicación:** `../A - Documentacion Tecnica/03 - Guia de Despliegue Inicial.md`
- **Propósito:** Guía completa paso a paso
- **Contenido:** Instrucciones detalladas, prerrequisitos, troubleshooting
- **Importancia:** **CRÍTICA** — Leer antes de cualquier instalación

### **06_VALIDACION_POST_BUNDLES.sql**
- **Propósito:** Verificar que todos los componentes estén correctos
- **Ejecutar:** Al final del despliegue
- **Resultado:** Reporte detallado del estado del sistema

---

## SUBCARPETAS DETALLADAS

### **00_Reset_Completo/**
- **Contenido:** Bundle_CERO_Reset_Completo.sql
- **Función:** Eliminar EsbirrosDB completamente para reinstalación limpia
- **Dependencias:** Ninguna (conectar a `master`)
- **Precaución:** DESTRUCTIVO — elimina todos los datos

### **01_Infraestructura_Base/**
- **Contenido:** Bundle_A1, Bundle_A2 + README
- **Función:** Crear estructura completa de BD y cargar menú del bodegón
- **Dependencias:** Ninguna

### **02_Logica_Negocio/**
- **Contenido:** Bundle_B1, Bundle_B2, Bundle_B3 + README
- **Función:** Implementar lógica de pedidos
- **Dependencias:** Infraestructura Base

### **03_Seguridad_Consultas/**
- **Contenido:** Bundle_C, Bundle_D + README
- **Función:** Configurar seguridad y vistas básicas
- **Dependencias:** Infraestructura + Lógica

### **04_Automatizacion_Avanzada/**
- **Contenido:** Bundle_E1, Bundle_E2 + README
- **Función:** Triggers y automatización
- **Dependencias:** Pasos 1-3 completados

### **05_Reportes_Dashboard/**
- **Contenido:** Bundle_R1, Bundle_R2 + README
- **Función:** Sistema completo de reportes y dashboard
- **Dependencias:** Todos los pasos anteriores

---

## VALIDACIÓN RÁPIDA

### **Verificar antes de empezar:**
```sql
-- Verificar que SQL Server está listo
SELECT @@VERSION as SQLServerVersion
SELECT SERVERPROPERTY('ProductLevel') as ServicePack
```

### **Verificar después del despliegue:**
```sql
-- Ejecutar script de validación completa
-- Ubicación: B - Scripts SQL/06_VALIDACION_POST_BUNDLES.sql
-- Resultado esperado: Porcentaje exito >= 90%
```

---

## SOPORTE Y TROUBLESHOOTING

### **Si algo falla:**

1. **Revisar prerrequisitos** en la guía principal
2. **Verificar orden de ejecución** (muy importante)
3. **Consultar README** de la carpeta específica donde falló
4. **Ejecutar validación** para identificar qué falta
5. **Re-ejecutar bundles** — todos incluyen verificaciones IF EXISTS y son re-ejecutables

### **Contacto:**
- **Desarrollado por:** SQLeaders S.A.
- **Proyecto:** EsbirrosDB v2.0
- **Cliente:** Bodegón Los Esbirros de Claudio

---

## CONSIDERACIONES IMPORTANTES

⚠️ **SIEMPRE hacer backup** antes de ejecutar en producción  
⚠️ **Probar en ambiente de desarrollo** primero  
⚠️ **Ejecutar en orden estricto** — las dependencias son críticas  
⚠️ **Leer documentación** antes de ejecutar cada paso  

---

**EsbirrosDB — Sistema de Gestión de Bodegón Porteño**  
**SQLeaders S.A. — Proyecto Educativo ISTEA**
