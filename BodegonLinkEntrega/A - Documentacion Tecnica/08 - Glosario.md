# GLOSARIO DE TÉRMINOS - SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Glosario de Términos - Sistema EsbirrosDB |
| **Proyecto** | Sistema de Gestión de Pedidos — Bodegón Porteño |
| **CLIENTES** | Bodegón Los Esbirros de Claudio |
| **Desarrollado por** | SQLeaders S.A. |
| **Versión** | 2.0 |
| **Estado** | Implementado y Funcional |

## **RESUMEN EJECUTIVO**

### **Objetivo del Documento**
Este glosario define todos los términos técnicos, conceptos de negocio y abreviaciones utilizadas en el sistema EsbirrosDB y su documentación. Proporciona una referencia unificada para asegurar la comprensión consistente de la terminología empleada en el proyecto.

### **Alcance del Glosario**
- Términos propios del **bodegón porteño** y su operatoria
- El sistema no maneja combos ni promociones; solo platos individuales

---

## **TÉRMINOS GENERALES DEL SISTEMA**

| **Término** | **Definición** | **Contexto** |
|-------------|----------------|--------------|
| **EsbirrosDB** | Sistema de gestión integral para el Bodegón Los Esbirros de Claudio | Sistema |
| **BodegaLink** | Nombre del proyecto de entrega académica que contiene EsbirrosDB | Proyecto |
| **Bundle** | Conjunto de scripts SQL agrupados por funcionalidad específica (ej: Bundle_A1_BaseDatos_Estructura.sql) | Desarrollo |
| **DER** | Diagrama Entidad-Relación. Representación gráfica de la estructura de la base de datos | Documentación |
| **FK** | Foreign Key (Clave Foránea). Campo que establece relación entre dos tablas | Base de datos |
| **PK** | Primary Key (Clave Primaria). Campo único identificador de cada registro en una tabla | Base de datos |
| **SP** | Stored Procedure. Procedimiento almacenado en la base de datos | Base de datos |
| **UK** | Unique Key (Clave Única). Restricción que garantiza valores únicos en un campo | Base de datos |
| **MVP** | Minimum Viable Product. Versión mínima funcional del sistema | Desarrollo |

---

## **TÉRMINOS DE NEGOCIO**

### **Bodegón Porteño**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **Bodegón** | Restaurante tradicional de Buenos Aires, conocido por cocina casera, ambiente informal y precios accesibles | Los Esbirros de Claudio |
| **Porteño** | Relacionado con la ciudad de Buenos Aires y su cultura gastronómica | Estilo de cocina porteño |
| **Cocina casera** | Preparaciones tradicionales argentinas: fideos, milanesas, guisos, parrilla | Ñoquis al Pomodoro, Lasagna Casera |
| **Cubiertos** | Servicio básico de MESAS en bodegones tradicionales | Incluido en el PRECIOS del menú |

### **Gestión de Pedidos**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **PEDIDOS** | Solicitud de productos realizada por un CLIENTES en el restaurante | PEDIDOS #1001 con 2 platos principales |
| **Detalle de PEDIDOS** | Línea individual dentro de un PEDIDOS que especifica producto, cantidad y PRECIOS | 2x Milanesa Napolitana - $12.000 |
| **Canal de Venta** | Modalidad por la cual se realiza el PEDIDOS | MESAS, Mostrador, Delivery |
| **Estado de PEDIDOS** | Situación actual en el flujo operativo del PEDIDOS | Pendiente → En Preparación → Listo → Entregado |
| **Comensales** | Número de personas que consumirán en un PEDIDOS de MESAS | MESAS para 4 comensales |
| **QR Token** | Código QR único asignado a cada MESAS para identificación | QR: MESA001-SUCURSAL1 |

### **Productos y Precios**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **PLATOS** | Producto individual del menú del restaurante | Bife de Chorizo a la Leña, Fideos con Tuco |
| **Categoría** | Clasificación de productos del menú | Entradas, Pastas, Carnes, Guarniciones, Postres, Bebidas |
| **Vigencia** | Período de tiempo en que un PRECIOS está activo | Desde 01/01/2026 sin vencimiento |
| **PRECIOS Unitario** | Costo individual de un producto al momento de la venta | $7.800 por Bife de Chorizo |
| **Subtotal** | Cantidad × PRECIOS unitario por ítem del PEDIDOS | 2 × $7.800 = $15.600 |

> **Nota:** EsbirrosDB no maneja combos ni promociones. El menú solo incluye platos individuales.

### **Organización y Personal**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **SUCURSALES** | Ubicación física del bodegón | San Telmo (Defensa 742) |
| **EMPLEADOS** | Personal del restaurante con acceso al sistema | Claudio (administrador), mozos, cocineros |
| **ROLES** | Función o cargo que define los permisos de un EMPLEADOS | Administrador, Mesero, Cocinero, Cajero |
| **MESAS** | Ubicación física donde se atienden clientes en el restaurante | MESAS 5 — Capacidad 6 personas |
| **Mozo** | EMPLEADOS que atiende las mesas (equivalente a mesero) | Toma pedidos y los ingresa al sistema |

### **Clientes y Delivery**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **CLIENTES** | Persona que realiza pedidos de delivery o se registra en el sistema | María González |
| **DOMICILIOS** | Dirección de entrega para pedidos de delivery | Av. Corrientes 1234, CABA |
| **Delivery** | Modalidad de entrega de pedidos en el DOMICILIOS del CLIENTES | PEDIDOS entregado en 45 minutos |
| **DOMICILIOS Principal** | Dirección preferencial de un CLIENTES para entregas | Marcado como dirección por defecto |

---

## **TÉRMINOS TÉCNICOS**

### **Base de Datos**

| **Término** | **Definición** | **Implementación en EsbirrosDB** |
|-------------|----------------|----------------------------------|
| **IDENTITY** | Campo autoincremental que genera valores únicos automáticamente | Todos los IDs principales (pedido_id, cliente_id, etc.) |
| **NOT NULL** | Restricción que impide valores nulos en un campo | plato_id en DETALLES_PEDIDOS (obligatorio, sin XOR) |
| **DEFAULT** | Valor asignado automáticamente cuando no se especifica | fecha_pedido DEFAULT GETDATE() |
| **CHECK Constraint** | Restricción que valida condiciones específicas | PRECIOS >= 0, cantidad > 0 |
| **UNIQUE Constraint** | Restricción que garantiza valores únicos | email único, usuario único |
| **Trigger** | Código que se ejecuta automáticamente ante eventos en la BD | tr_ActualizarTotales, tr_AuditoriaPedidos |
| **XOR Constraint** | Restricción excluyente (solo uno de dos campos puede tener valor) | No aplicada en EsbirrosDB; `plato_id` es siempre obligatorio |

### **Desarrollo y Arquitectura**

| **Término** | **Definición** | **Uso en EsbirrosDB** |
|-------------|----------------|----------------------|
| **Normalización** | Proceso de organización de datos para eliminar redundancias | Implementado hasta 3FN |
| **3FN** | Tercera Forma Normal. Nivel de normalización de base de datos | Estándar aplicado en todas las tablas |
| **Integridad Referencial** | Mantenimiento de consistencia entre tablas relacionadas | 17 Foreign Keys implementadas |
| **Audit Trail** | Registro histórico de cambios realizados en el sistema | Tabla AUDITORIAS_SIMPLES |
| **JSON** | Formato de intercambio de datos estructurados | Almacenamiento de reportes en REPORTES_GENERADOS |
| **BULK INSERT** | Carga masiva de datos en SQL Server. En EsbirrosDB se implementa mediante generación T-SQL (loops, NEWID, CHECKSUM) sin archivos externos | Carga masiva de 10.000 pedidos en Bundle_F |

---

## **ROLES Y PERMISOS**

### **Roles del Sistema**

| **ROLES** | **Descripción** | **Permisos Principales** |
|---------|-----------------|--------------------------|
| **Administrador** | Control total del sistema | Crear usuarios, modificar configuraciones, acceso completo |
| **Gerente** | Gestión operativa del bodegón | Reportes, configuración de precios, gestión de personal |
| **Cajero** | Manejo de pagos y cierre de caja | Procesar pagos, consultar pedidos, reportes de ventas |
| **Mesero** | Atención de mesas y toma de pedidos | Crear pedidos, consultar estados, gestión de mesas |
| **Cocinero** | Gestión de preparación de pedidos | Actualizar estados de pedidos, consultar productos |
| **Delivery** | Gestión de entregas a DOMICILIOS | Consultar pedidos, actualizar estado de entrega |
| **Auditor** | Revisión y control de procesos | Solo lectura, acceso a reportes y auditoría |

### **Usuarios de Aplicación (sin login)**

| **Usuario** | **Propósito** |
|-------------|---------------|
| **app_esbirros_web** | Operaciones web: crear pedidos, gestión de mesas |
| **app_esbirros_reportes** | Solo lectura: dashboards y reportes |
| **app_esbirros_delivery** | Gestión de pedidos delivery |

---

## **ESTADOS Y FLUJOS**

### **Estados de Pedidos**

| **Estado** | **Orden** | **Descripción** | **Acción Requerida** |
|------------|-----------|-----------------|---------------------|
| **Pendiente** | 1 | PEDIDOS creado, esperando confirmación | Confirmar PEDIDOS |
| **Confirmado** | 2 | PEDIDOS confirmado, esperando preparación | Iniciar preparación |
| **En Preparación** | 3 | PEDIDOS siendo preparado por cocina | Finalizar preparación |
| **Listo** | 4 | PEDIDOS terminado, listo para entrega | Entregar al CLIENTES |
| **En Reparto** | 5 | PEDIDOS en camino (solo delivery) | Confirmar entrega |
| **Entregado** | 6 | PEDIDOS entregado al CLIENTES | Cobrar y cerrar |
| **Cerrado** | 7 | PEDIDOS pagado y cerrado | Proceso completado |
| **Cancelado** | - | PEDIDOS cancelado | No requiere acción |

### **Canales de Venta**

| **Canal** | **Descripción** | **Validaciones Específicas** |
|-----------|-----------------|-------------------------------|
| **MESAS** | PEDIDOS realizado en MESAS del restaurante | Requiere mesa_id válida |
| **Mostrador** | PEDIDOS para llevar en mostrador | No requiere MESAS ni CLIENTES |
| **Delivery** | PEDIDOS con entrega a DOMICILIOS | Requiere cliente_id y domicilio_id |

---

## **ABREVIACIONES Y ACRÓNIMOS**

### **Técnicas**

| **Abreviación** | **Significado** | **Contexto** |
|-----------------|-----------------|--------------|
| **BD** | Base de Datos | Documentación técnica |
| **CRUD** | Create, Read, Update, Delete | Operaciones básicas |
| **SQL** | Structured Query Language | Lenguaje de consulta |
| **ER** | Entity-Relationship | Modelado de datos |
| **API** | Application Programming Interface | Integración de sistemas |
| **RDS** | Relational Database Service | Servicio de BD en AWS |
| **DBaaS** | Database as a Service | BD gestionada en la nube |

### **De Negocio**

| **Abreviación** | **Significado** | **Contexto** |
|-----------------|-----------------|--------------|
| **POS** | Point of Sale | Sistema de punto de venta |
| **CRM** | Customer Relationship Management | Gestión de relaciones con clientes |
| **SKU** | Stock Keeping Unit | Identificador de producto |
| **KPI** | Key Performance Indicator | Indicador clave de rendimiento |

---

## **MÉTRICAS Y UNIDADES**

### **Tiempos**

| **Unidad** | **Descripción** | **Uso en EsbirrosDB** |
|------------|-----------------|----------------------|
| **Tiempo de Preparación** | Minutos desde PEDIDOS hasta listo | Medición de eficiencia de cocina |
| **Tiempo de Entrega** | Minutos desde listo hasta entregado | Control de calidad de servicio |
| **Tiempo Total** | Duración completa del proceso | KPI principal de satisfacción |

### **Financieras**

| **Término** | **Descripción** | **Formato** |
|-------------|-----------------|-------------|
| **Subtotal** | Cantidad × PRECIOS unitario por ítem | DECIMAL(10,2) |
| **Total** | Suma de todos los subtotales del PEDIDOS (calculado por trigger) | DECIMAL(10,2) |
| **PRECIOS Vigente** | PRECIOS actual aplicable según fecha (tabla PRECIOS con vigencia) | Consultado en tiempo real |

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — 2026**  
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**
