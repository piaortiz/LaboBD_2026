# GLOSARIO DE TÉRMINOS - SISTEMA ESBIRROSDB

## **INFORMACIÓN DEL DOCUMENTO**

| **Campo** | **Descripción** |
|-----------|-----------|
| **Documento** | Glosario de Términos - Sistema EsbirrosDB |
| **Proyecto** | Sistema de Gestión de Pedidos — Bodegón Porteño |
| **Cliente** | Bodegón Los Esbirros de Claudio |
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
| **Cubiertos** | Servicio básico de mesa en bodegones tradicionales | Incluido en el precio del menú |

### **Gestión de Pedidos**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **Pedido** | Solicitud de productos realizada por un cliente en el restaurante | Pedido #1001 con 2 platos principales |
| **Detalle de Pedido** | Línea individual dentro de un pedido que especifica producto, cantidad y precio | 2x Milanesa Napolitana - $12.000 |
| **Canal de Venta** | Modalidad por la cual se realiza el pedido | Mesa, Mostrador, Delivery |
| **Estado de Pedido** | Situación actual en el flujo operativo del pedido | Pendiente → En Preparación → Listo → Entregado |
| **Comensales** | Número de personas que consumirán en un pedido de mesa | Mesa para 4 comensales |
| **QR Token** | Código QR único asignado a cada mesa para identificación | QR: MESA001-SUCURSAL1 |

### **Productos y Precios**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **Plato** | Producto individual del menú del restaurante | Bife de Chorizo a la Leña, Fideos con Tuco |
| **Categoría** | Clasificación de productos del menú | Entradas, Pastas, Carnes, Guarniciones, Postres, Bebidas |
| **Vigencia** | Período de tiempo en que un precio está activo | Desde 01/01/2026 sin vencimiento |
| **Precio Unitario** | Costo individual de un producto al momento de la venta | $7.800 por Bife de Chorizo |
| **Subtotal** | Cantidad × Precio unitario por ítem del pedido | 2 × $7.800 = $15.600 |

> **Nota:** EsbirrosDB no maneja combos ni promociones. El menú solo incluye platos individuales.

### **Organización y Personal**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **Sucursal** | Ubicación física del bodegón | San Telmo (Defensa 742), Palermo (Thames 1850) |
| **Empleado** | Personal del restaurante con acceso al sistema | Claudio (administrador), mozos, cocineros |
| **Rol** | Función o cargo que define los permisos de un empleado | Administrador, Mesero, Cocinero, Cajero |
| **Mesa** | Ubicación física donde se atienden clientes en el restaurante | Mesa 5 — Capacidad 6 personas |
| **Mozo** | Empleado que atiende las mesas (equivalente a mesero) | Toma pedidos y los ingresa al sistema |

### **Clientes y Delivery**

| **Término** | **Definición** | **Ejemplo** |
|-------------|----------------|-------------|
| **Cliente** | Persona que realiza pedidos de delivery o se registra en el sistema | María González |
| **Domicilio** | Dirección de entrega para pedidos de delivery | Av. Corrientes 1234, CABA |
| **Delivery** | Modalidad de entrega de pedidos en el domicilio del cliente | Pedido entregado en 45 minutos |
| **Domicilio Principal** | Dirección preferencial de un cliente para entregas | Marcado como dirección por defecto |

---

## **TÉRMINOS TÉCNICOS**

### **Base de Datos**

| **Término** | **Definición** | **Implementación en EsbirrosDB** |
|-------------|----------------|----------------------------------|
| **IDENTITY** | Campo autoincremental que genera valores únicos automáticamente | Todos los IDs principales (pedido_id, cliente_id, etc.) |
| **NOT NULL** | Restricción que impide valores nulos en un campo | plato_id en DETALLE_PEDIDO (obligatorio, sin XOR) |
| **DEFAULT** | Valor asignado automáticamente cuando no se especifica | fecha_pedido DEFAULT GETDATE() |
| **CHECK Constraint** | Restricción que valida condiciones específicas | precio >= 0, cantidad > 0 |
| **UNIQUE Constraint** | Restricción que garantiza valores únicos | email único, usuario único |
| **Trigger** | Código que se ejecuta automáticamente ante eventos en la BD | tr_ActualizarTotales, tr_AuditoriaPedidos |
| **XOR Constraint** | Restricción excluyente (solo uno de dos campos puede tener valor) | No aplicada en EsbirrosDB; `plato_id` es siempre obligatorio |

### **Desarrollo y Arquitectura**

| **Término** | **Definición** | **Uso en EsbirrosDB** |
|-------------|----------------|----------------------|
| **Normalización** | Proceso de organización de datos para eliminar redundancias | Implementado hasta 3FN |
| **3FN** | Tercera Forma Normal. Nivel de normalización de base de datos | Estándar aplicado en todas las tablas |
| **Integridad Referencial** | Mantenimiento de consistencia entre tablas relacionadas | 17 Foreign Keys implementadas |
| **Audit Trail** | Registro histórico de cambios realizados en el sistema | Tabla AUDITORIA_SIMPLE |
| **JSON** | Formato de intercambio de datos estructurados | Almacenamiento de reportes en REPORTES_GENERADOS |
| **BULK INSERT** | Carga masiva de datos desde archivos externos | Requisito académico: 10.000+ registros desde CSV |

---

## **ROLES Y PERMISOS**

### **Roles del Sistema**

| **Rol** | **Descripción** | **Permisos Principales** |
|---------|-----------------|--------------------------|
| **Administrador** | Control total del sistema | Crear usuarios, modificar configuraciones, acceso completo |
| **Gerente** | Gestión operativa del bodegón | Reportes, configuración de precios, gestión de personal |
| **Cajero** | Manejo de pagos y cierre de caja | Procesar pagos, consultar pedidos, reportes de ventas |
| **Mesero** | Atención de mesas y toma de pedidos | Crear pedidos, consultar estados, gestión de mesas |
| **Cocinero** | Gestión de preparación de pedidos | Actualizar estados de pedidos, consultar productos |
| **Delivery** | Gestión de entregas a domicilio | Consultar pedidos, actualizar estado de entrega |
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
| **Pendiente** | 1 | Pedido creado, esperando confirmación | Confirmar pedido |
| **Confirmado** | 2 | Pedido confirmado, esperando preparación | Iniciar preparación |
| **En Preparación** | 3 | Pedido siendo preparado por cocina | Finalizar preparación |
| **Listo** | 4 | Pedido terminado, listo para entrega | Entregar al cliente |
| **En Reparto** | 5 | Pedido en camino (solo delivery) | Confirmar entrega |
| **Entregado** | 6 | Pedido entregado al cliente | Cobrar y cerrar |
| **Cerrado** | 7 | Pedido pagado y cerrado | Proceso completado |
| **Cancelado** | - | Pedido cancelado | No requiere acción |

### **Canales de Venta**

| **Canal** | **Descripción** | **Validaciones Específicas** |
|-----------|-----------------|-------------------------------|
| **Mesa** | Pedido realizado en mesa del restaurante | Requiere mesa_id válida |
| **Mostrador** | Pedido para llevar en mostrador | No requiere mesa ni cliente |
| **Delivery** | Pedido con entrega a domicilio | Requiere cliente_id y domicilio_id |

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
| **Tiempo de Preparación** | Minutos desde pedido hasta listo | Medición de eficiencia de cocina |
| **Tiempo de Entrega** | Minutos desde listo hasta entregado | Control de calidad de servicio |
| **Tiempo Total** | Duración completa del proceso | KPI principal de satisfacción |

### **Financieras**

| **Término** | **Descripción** | **Formato** |
|-------------|-----------------|-------------|
| **Subtotal** | Cantidad × Precio unitario por ítem | DECIMAL(10,2) |
| **Total** | Suma de todos los subtotales del pedido (calculado por trigger) | DECIMAL(10,2) |
| **Precio Vigente** | Precio actual aplicable según fecha (tabla PRECIO con vigencia) | Consultado en tiempo real |

---

**Documento generado por SQLeaders S.A.**  
**Versión: 2.0 — 2026**  
**EsbirrosDB v2.0 — Proyecto Educativo ISTEA**
