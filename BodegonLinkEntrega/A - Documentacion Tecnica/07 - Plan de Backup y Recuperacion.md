# PLAN DE BACKUP Y RECUPERACIÓN - SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Plan de Backup y Recuperación - Sistema EsbirrosDB |
| **Proyecto** | Sistema de Gestión de Pedidos — Bodegón Porteño |
| **Cliente** | Bodegón Los Esbirros de Claudio |
| **Desarrollado por** | SQLeaders S.A. |
| **Versión** | 2.0 |
| **Estado** | Implementado y Funcional |
| **Instituto** | ISTEA |

## **RESUMEN EJECUTIVO**

### **Objetivo del Documento**
Este plan define la estrategia integral de backup y recuperación para la base de datos EsbirrosDB, garantizando la continuidad del negocio mediante procedimientos automatizados de respaldo y restauración. Incluye configuraciones detalladas, procedimientos de emergencia y métricas de rendimiento.

### **Herramientas y Tecnologías**
- **Software Principal:** SQLBackupAndFTP Professional (v12.7.35)
- **Base de Datos:** Microsoft SQL Server — EsbirrosDB
- **Estrategia:** Backup 3-2-1 (Local + Google Drive)
- **Frecuencias:** Full (Semanal), Differential (Diario), Transaction Log (12h)

---

## CONFIGURACIÓN DEL SISTEMA DE BACKUP

### **Herramienta Implementada**
- **Software:** SQLBackupAndFTP Professional Trial (v12.7.35)
- **Estado de Licencia:** Trial (14 días) — Requiere adquisición para producción
- **Conectividad:** Microsoft SQL Server (Standard backup)
- **Base de Datos Objetivo:** EsbirrosDB

### **Opciones de Licencia SQLBackupAndFTP**

| **Edición** | **Precio** | **Límite BD** | **Recomendación** |
|-------------|------------|---------------|-------------------|
| **Free** | $0/año | Máximo 2 BD | **Recomendada para EsbirrosDB** |
| **Lite** | $39/año | Máximo 5 BD | Para expansiones futuras |
| **Standard/Professional** | $89-129/año | Sin límite | Para entornos empresariales |

### **¿Por qué SQLBackupAndFTP?**
- **Funcionalidad completa gratuita:** Todas las funciones disponibles en versión Free
- **Fácil configuración:** Interfaz gráfica intuitiva
- **Múltiples destinos:** Google Drive, Amazon S3, FTP, carpetas locales
- **Automatización:** Programación de backups sin intervención manual
- **Confiabilidad probada:** Ampliamente usado en entornos de producción

### **Configuración Actual Implementada**
- **Versión:** SQLBackupAndFTP Professional Trial (se migrará a Free)
- **Destinos configurados:** Carpeta local + Google Drive
- **Programación:** Full semanal, Diferencial diario, Transaction Log cada 12h

### **Programación de Respaldos Automáticos**

| **Tipo de Backup** | **Frecuencia** | **Horario** |
|-------------------|----------------|-------------|
| **Full Backup** | Cada 168 horas (Semanal) | Domingos 03:44 AM |
| **Differential** | Cada 24 horas (Diario) | Diario 03:44 AM |
| **Transaction Log** | Cada 12 horas | Cada 12 horas |

### **Destinos de Almacenamiento y Responsabilidades**

| **Destino** | **Ubicación** | **Responsable** | **Propósito** | **Estado** |
|------------|---------------|-----------------|---------------|------------|
| **Local/Network** | Servidor del bodegón (E:\EsbirrosBckp) | Claudio (administrador) | Recuperación rápida local | Activo |
| **Google Drive** | Nube (DBA SQLeaders: esbirrosbckp) | DBA SQLeaders | Seguridad offsite y DR | Activo |

### **Ventajas de esta Estrategia de Almacenamiento**
- **Recuperación rápida:** Backup local en servidor permite restauración inmediata sin dependencia de internet
- **Seguridad adicional:** Backup en nube gestionado por DBA garantiza conservación a largo plazo
- **Separación de responsabilidades:** Bodegón maneja operación diaria, SQLeaders la continuidad
- **Cumple mejores prácticas:** Implementa estrategia 3-2-1 (3 copias, 2 medios, 1 offsite)

### **Políticas de Retención Recomendadas**

| **Tipo de Backup** | **Retención Local** | **Retención Nube** | **Justificación** |
|-------------------|--------------------|--------------------|-------------------|
| **Full Backup** | 4 semanas (1 mes) | 6 meses | Recuperación punto en el tiempo, auditorías |
| **Differential** | 2 semanas | 1 mes | Balance espacio vs. flexibilidad |
| **Transaction Log** | 1 semana | 2 semanas | Recuperación granular reciente |

### **Gestión de Espacio y Limpieza Automática**
- **Local:** Limpieza automática cada domingo después del Full backup
- **Nube:** Revisión trimestral y archivo de backups antiguos
- **Espacio estimado local:** ~500 MB por semana (considerando compresión)
- **Espacio estimado nube:** ~2 GB para 6 meses de retención

### **Casos Especiales de Retención**
- **Cierre mensual:** Conservar Full backup del último día del mes por 1 año adicional
- **Auditoría anual:** Backup del 31 de diciembre conservado por 7 años (requerimientos fiscales)
- **Actualizaciones de sistema:** Backup inmediatamente antes y después conservado por 3 meses

---

## SISTEMA DE MONITOREO Y ALERTAS

### **Configuración de Notificaciones por Email**
- **Email éxito**: adrian.barletta@istea.com.ar
- **Email falla**: (Se puede configurar múltiples emails separados por coma)
- **Servicio down alerts**: Habilitado

### **Monitoreo Remoto y Logs Web**
- **Historial web**: Disponible para consulta
- **Monitoreo remoto**: Posible via web interface

---

## PROCEDIMIENTOS DE BACKUP

### **Respaldo Automático Configurado**
```
Job: Backup Job - EsbirrosDB
├── Connect to Microsoft SQL Server
├── Select Database: EsbirrosDB
├── Store backups in:
│   ├── Local/Network: E:\EsbirrosBckp
│   └── Google Drive: esbirrosbckp
├── Schedule:
│   ├── Full: every 168h
│   ├── Differential: every 24h
│   └── Transaction Log: every 12h
└── Send confirmation email
```

### **Procedimiento de Respaldo Manual**
```sql
-- Backup completo manual
BACKUP DATABASE EsbirrosDB
TO DISK = 'E:\EsbirrosBckp\EsbirrosDB_Full_Manual.bak'
WITH FORMAT, COMPRESSION, STATS = 10;
```

---

## PROCEDIMIENTOS DE RESTAURACIÓN

### **Restauración desde Almacenamiento Local**
```sql
-- Restaurar backup completo
RESTORE DATABASE EsbirrosDB_Restore
FROM DISK = 'E:\EsbirrosBckp\EsbirrosDB_Full_YYYYMMDD.bak'
WITH REPLACE, STATS = 10;

-- Aplicar backup diferencial (si existe)
RESTORE DATABASE EsbirrosDB_Restore
FROM DISK = 'E:\EsbirrosBckp\EsbirrosDB_Diff_YYYYMMDD.bak'
WITH NORECOVERY;

-- Aplicar logs de transacciones
RESTORE LOG EsbirrosDB_Restore
FROM DISK = 'E:\EsbirrosBckp\EsbirrosDB_Log_YYYYMMDDHH.trn'
WITH RECOVERY;

-- Verificar integridad
DBCC CHECKDB('EsbirrosDB_Restore');
```

### **Restauración desde Google Drive**
1. Descargar archivo .bak desde Google Drive
2. Copiar a servidor SQL Server
3. Ejecutar comandos de restauración SQL
4. Verificar integridad con `DBCC CHECKDB`

---

## MEJORES PRÁCTICAS IMPLEMENTADAS

### **Estrategia de Respaldo 3-2-1 con Segregación de Responsabilidades**
- **3 copias**: Original (servidor) + Local (bodegón) + Google Drive (SQLeaders)
- **2 medios diferentes**: Disco local + Nube
- **1 offsite**: Google Drive remoto gestionado por DBA especializado

### **Verificación de Integridad de Datos**
- **Checksum**: Automático en cada backup
- **Verification**: SQLBackupAndFTP verifica automáticamente
- **Compression**: Activada para optimizar espacio

### **Sistema de Monitoreo y Seguimiento**
- **Email notifications**: Configuradas para éxito/falla
- **Historial detallado**: Disponible en interfaz
- **Logs de actividad**: Registrados automáticamente

---

## PLAN DE MEJORAS Y OPTIMIZACIONES

### **Acciones Inmediatas Requeridas**
1. **Migrar a versión Free** cuando expire el trial (14 días)
   - Mantiene toda la funcionalidad actual
   - Permite hasta 2 bases de datos programadas (suficiente para EsbirrosDB)
   - Costo: $0
2. **Implementar políticas de retención automática**
3. **Configurar emails de fallas** con múltiples destinatarios
4. **Optimizar frecuencia de transaction log** a cada 15-30 minutos para mejor RPO
5. **Monitorear espacio en disco** y configurar alertas de capacidad

---

## ANÁLISIS DE RETENCIÓN Y ESPACIO

### **Estimación de Crecimiento de Backups**

| **Período** | **Espacio Local** | **Espacio Nube** | **Gestión** |
|-------------|-------------------|------------------|-------------|
| **1 mes** | ~2 GB | ~2 GB | Operación normal |
| **3 meses** | ~2 GB (rotación) | ~4 GB | Revisión trimestral |
| **6 meses** | ~2 GB (rotación) | ~8 GB | Limpieza selectiva |
| **1 año** | ~2 GB (rotación) | ~12 GB + archivos especiales | Archivado anual |

---

## OBJETIVOS Y TIEMPOS DE RECUPERACIÓN

| **Escenario** | **Tiempo Estimado** | **Procedimiento** |
|---------------|-------------------|------------------|
| **Corrupción menor** | 15-30 min | Restaurar desde diferencial |
| **Pérdida de base completa** | 1-2 horas | Full + Differential + Logs |
| **Disaster recovery** | 2-4 horas | Restaurar desde Google Drive |
| **Point-in-time** | 30-60 min | Full + Logs hasta punto específico |

---

## RESPONSABILIDADES Y CONTACTOS

### **Equipo de Administración de Base de Datos**
- **DBA Principal**: Adrián Barletta (adrian.barletta@istea.com.ar)
- **Backup Tool**: SQLBackupAndFTP Professional
- **Soporte**: Documentación + Community forums

### **Procedimiento de Escalamiento**
1. **Nivel 1**: Verificar logs automáticos y email alerts
2. **Nivel 2**: Contactar DBA para investigación
3. **Nivel 3**: Ejecutar procedimiento de disaster recovery

---

**Documento generado por SQLeaders S.A. — 2026**  
**Para soporte técnico: Contactar equipo de desarrollo**  
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**
