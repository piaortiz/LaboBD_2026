# REQUERIMIENTOS TECNICOS - EsbirrosDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Requerimientos Tecnicos - Sistema EsbirrosDB |
| **Proyecto** | Sistema de Gestión de Pedidos — Bodegón Porteño |
| **CLIENTES** | Bodegón Los Esbirros de Claudio |
| **Desarrollado por** | SQLeaders S.A. |
| **Versión** | 1.0 |
| **Tipo** | Especificación Técnica Completa |
| **Instituto** | ISTEA |
| **Materia** | Laboratorio de Administración de Bases de Datos |
| **Profesor** | Carlos Alejandro Caraccio |

---

## **1. REQUERIMIENTOS DE SOFTWARE**

### **1.1 Motor de Base de Datos**

#### **Microsoft SQL Server**
| **Componente** | **Versión Mínima** | **Versión Recomendada** | **Estado** |
|----------------|-------------------|------------------------|------------|
| **SQL Server Engine** | 2017 (14.x) | 2022 (16.x) | COMPATIBLE |
| **SQL Server Management Studio** | 18.0 | 19.3 o superior | COMPATIBLE |
| **SQL Server Agent** | Incluido | Incluido | REQUERIDO |
| **.NET Framework** | 4.7.2 | 4.8 o superior | COMPATIBLE |

#### **Ediciones Compatibles**
- **SQL Server Enterprise** (Recomendado para producción)
- **SQL Server Standard** (Mínimo para producción)
- **SQL Server Developer** (Solo desarrollo y testing)
- **SQL Server Express** (Solo pruebas locales y AWS RDS académico)

### **1.2 Sistema Operativo**

#### **Servidor de Base de Datos**
| **SO** | **Versión Mínima** | **Arquitectura** | **Estado** |
|--------|-------------------|------------------|------------|
| **Windows Server** | 2016 | x64 | COMPATIBLE |
| **Windows Server** | 2019 | x64 | RECOMENDADO |
| **Windows Server** | 2022 | x64 | ÓPTIMO |
| **Windows 10/11** | Pro/Enterprise | x64 | DESARROLLO |

#### **Compatibilidad Linux (Opcional)**
| **Distribución** | **Versión** | **Estado** | **Notas** |
|------------------|-------------|------------|-----------|
| **Ubuntu** | 20.04 LTS+ | COMPATIBLE | SQL Server 2017+ |
| **Red Hat Enterprise Linux** | 8.0+ | COMPATIBLE | SQL Server 2017+ |
| **SUSE Linux Enterprise** | 15+ | COMPATIBLE | SQL Server 2017+ |

---

## **2. REQUERIMIENTOS DE HARDWARE**

### **2.1 Especificaciones Mínimas (Desarrollo)**

| **Componente** | **Especificación Mínima** | **Notas** |
|----------------|---------------------------|-----------|
| **CPU** | 2 cores x 2.0 GHz | x64 compatible |
| **RAM** | 8 GB | 4 GB para SQL Server |
| **Almacenamiento** | 50 GB disponibles | SSD recomendado |
| **Red** | 100 Mbps | Para conectividad |

### **2.2 Especificaciones Recomendadas (Producción)**

| **Componente** | **Especificación Recomendada** | **Justificación** |
|----------------|-------------------------------|-------------------|
| **CPU** | 8 cores x 2.4 GHz | Procesamiento concurrente |
| **RAM** | 32 GB | Buffer pool y cache |
| **Almacenamiento Principal** | 500 GB SSD NVMe | Archivos de datos (.mdf) |
| **Almacenamiento Log** | 200 GB SSD | Archivos de log (.ldf) |
| **Almacenamiento Backup** | 1 TB | Respaldos y archivos temporales |
| **Red** | 1 Gbps | Alto throughput |

### **2.3 Especificaciones AWS RDS (Académico)**

| **Componente** | **Configuración** | **Notas** |
|----------------|------------------|-----------|
| **Tipo de instancia** | db.t3.micro | SQL Server Express Edition |
| **Almacenamiento** | 20 GB gp2 | Suficiente para datos académicos |
| **Multi-AZ** | No | Express no lo soporta |
| **Costo estimado** | ~$0 (free tier) | Elegible AWS Free Tier |

---

## **3. CONFIGURACIÓN DE ALMACENAMIENTO**

### **3.1 Requerimientos Básicos**

| **Componente** | **Tamaño Mínimo** | **Recomendado** | **Notas** |
|----------------|------------------|----------------|-----------|
| **Base de Datos** | 1 GB | 5 GB | Archivos .mdf |
| **Log de Transacciones** | 500 MB | 2 GB | Archivos .ldf |
| **Backup** | 2 GB | 10 GB | Respaldos |
| **Total Estimado** | **3.5 GB** | **17 GB** | Primer año |

### **3.2 Distribución Recomendada**

- **Datos**: Disco SSD para mejor performance
- **Log**: Disco separado (puede ser SSD o HDD)
- **Backup**: Almacenamiento externo o en red
- **TempDB**: Misma unidad que datos

---

## **4. CONFIGURACIÓN DE RED**

### **4.1 Requerimientos Básicos**

| **Componente** | **Valor** | **Notas** |
|----------------|-----------|-----------|
| **Puerto SQL Server** | 1433 | Puerto estándar |
| **Protocolo** | TCP/IP | Habilitado |
| **Firewall** | Permitir puerto 1433 | Configurar en Windows / Security Group AWS |
| **Conexiones** | 100 usuarios | Máximo concurrente |

### **4.2 Configuración Simple**

- **Habilitar TCP/IP** en SQL Server Configuration Manager
- **Abrir puerto 1433** en firewall de Windows / Security Group de AWS
- **Configurar IP estática** del servidor (recomendado)
- **Verificar conectividad** desde aplicaciones CLIENTES

---

## **5. SEGURIDAD Y AUTENTICACIÓN**

### **5.1 Configuración Básica**

| **Componente** | **Configuración** | **Uso** |
|----------------|------------------|---------|
| **Modo Autenticación** | Mixed Mode | Windows + SQL |
| **Usuario Administrador** | sa (habilitado) | Administración |
| **Roles del Sistema** | 7 roles implementados | Control de acceso |

### **5.2 Usuarios del Sistema EsbirrosDB**

- **claudio.admin**: Acceso completo (administrador del bodegón)
- **app_esbirros_web**: Operaciones web (crear pedidos, gestión de mesas)
- **app_esbirros_reportes**: Solo lectura de reportes y dashboards
- **app_esbirros_delivery**: Gestión de pedidos delivery

### **5.3 Recomendaciones**

- **Usar contraseñas seguras** (mínimo 8 caracteres)
- **Activar cifrado** en conexiones (TLS 1.2+)
- **Crear usuarios específicos** para cada aplicación
- **Revisar permisos** periódicamente

---

## **6. CONFIGURACIÓN DE BACKUP**

### **6.1 Requerimientos Básicos**
- **Backup completo**: Semanal mínimo
- **Backup diferencial**: Diario recomendado
- **Backup de logs**: Cada 12 horas
- **Retención**: 30 días mínimo
- **Ubicación**: Local + almacenamiento externo/nube
- **Verificación**: Automática con alertas

### **6.2 Herramientas Recomendadas**
- **SQL Server Management Studio** (básico)
- **SQLBackupAndFTP** (automático y profesional)
- **Scripts nativos SQL Server** (personalizado)

Para la estrategia completa: ver **07 - Plan de Backup y Recuperacion.md**

---

## **7. LICENCIAMIENTO**

### **7.1 Requerimientos de Licencia**

| **Edición** | **Tipo de Licencia** | **Uso Recomendado** | **Costo Aproximado** |
|-------------|---------------------|-------------------|---------------------|
| **Express** | Gratis | Desarrollo/AWS RDS académico | $0 |
| **Standard** | Core o Server+CAL | Pequeñas/Medianas empresas | $3,717 - $931 por core |
| **Enterprise** | Core | Grandes empresas | $14,256 por core |

### **7.2 Limitaciones por Edición**

| **Característica** | **Express** | **Standard** | **Enterprise** |
|-------------------|-------------|--------------|---------------|
| **Max DB Size** | 10 GB | Ilimitado | Ilimitado |
| **Max RAM** | 1410 MB | 128 GB | Ilimitado |
| **Max Cores** | 4 | 24 | Ilimitado |

> **Nota académica:** Para el despliegue en AWS RDS se usa SQL Server Express Edition (gratuita), suficiente para los volúmenes del proyecto.

---

**Documento generado por SQLeaders S.A.**  
**Versión: 1.0 - 2026**  
**Proyecto Educativo ISTEA — Prohibida la comercialización**
