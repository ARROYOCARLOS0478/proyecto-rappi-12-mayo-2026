Actúa como un administrador de base de datos; proyecto rappi, que entidades se necesitan para su gestión.

Como administrador de base de datos para un proyecto tipo Rappi, aquí tienes el análisis de entidades y un diagrama ERD:

Las entidades principales se agrupan en 5 dominios: **usuarios y autenticación**, **catálogo de productos**, **gestión de pedidos**, **logística y entrega**, y **pagos y finanzas**.---
<img width="1057" height="940" alt="image" src="https://github.com/user-attachments/assets/9b4eca93-2f12-4760-957b-584cac1908ee" />


Aquí el resumen de los 5 dominios y la justificación de cada entidad:

**Usuarios y autenticación** — `USUARIO` es la entidad central; el campo `rol` distingue clientes, repartidores y administradores. `DIRECCION` es separada para permitir múltiples direcciones por usuario y facilitar el cálculo de rutas.

**Catálogo** — `COMERCIO` representa restaurantes o tiendas. `PRODUCTO` pertenece a un comercio y a una `CATEGORIA_PRODUCTO` (comida rápida, bebidas, etc.), lo que facilita filtros y búsquedas.

**Pedidos** — `PEDIDO` es el nodo más conectado del sistema. `ITEM_PEDIDO` es la tabla intermedia que descompone el pedido en líneas individuales con precio unitario (importante: el precio puede cambiar, por eso se persiste al momento del pedido).

**Logística** — `REPARTIDOR` extiende a `USUARIO` y almacena la ubicación en tiempo real (`lat_actual`, `lng_actual`) para el tracking. Su asignación al pedido se gestiona directamente desde `PEDIDO`.

**Pagos y adicionales** — `PAGO` se mantiene como entidad separada de `PEDIDO` para soportar reintentos, múltiples métodos y auditoría. `CALIFICACION` permite valorar tanto al comercio como al repartidor. `CUPON` es independiente y se asocia al pedido en el momento de aplicarse.

---

**Entidades opcionales** que suelen agregarse en fases posteriores: `NOTIFICACION`, `HISTORIAL_UBICACION` (tracking granular del repartidor), `COMISION`, `REEMBOLSO`, y `HORARIO_COMERCIO`.

Las entidades con sus atributos y tipo en forma de tabla para cada una de las entidades

TABLAS
<img width="918" height="517" alt="image" src="https://github.com/user-attachments/assets/a3076d3f-94e7-4ee5-a188-92603ceb1689" />
<img width="922" height="571" alt="image" src="https://github.com/user-attachments/assets/523f5718-2333-43e0-86e2-5066b4abc9b0" />
<img width="462" height="404" alt="image" src="https://github.com/user-attachments/assets/729ccc4d-9275-4ac1-85e8-f6e0f0e9eb47" />
<img width="732" height="543" alt="image" src="https://github.com/user-attachments/assets/ef0ca535-da34-4092-9033-1bb0692b770c" />
<img width="912" height="498" alt="image" src="https://github.com/user-attachments/assets/4a438e37-ce45-4a7c-a161-9c9c743041ac" />
<img width="914" height="455" alt="image" src="https://github.com/user-attachments/assets/20de0ee7-2ab3-4fe4-b284-1bf81fed1771" />
<img width="457" height="334" alt="image" src="https://github.com/user-attachments/assets/b9bad55b-73d2-4239-addb-74e1975eb943" />

Algunas notas de diseño relevantes para la implementación:

`nombre_producto` en `ITEM_PEDIDO` se persiste como texto aunque ya existe la FK al producto, porque el nombre puede cambiar en el catálogo y el historial del pedido debe quedar inmutable.

`objetivo_id` en `CALIFICACION` es un UUID genérico (patrón polymorphic association) junto con `tipo_objetivo`, lo que permite calificar tanto al comercio como al repartidor desde la misma tabla sin duplicar la entidad.

Los campos `lat_actual` / `lng_actual` en `REPARTIDOR` son para el snapshot en tiempo real; si se necesita historial de trayectoria, se agrega una tabla `HISTORIAL_UBICACION` separada para no inflar este registro con cada actualización de GPS.

`DECIMAL(10,7)` en coordenadas geográficas da precisión de ~1 cm, suficiente para cualquier caso de uso de delivery. `DECIMAL(10,2)` en precios soporta hasta $99,999,999.99.

¿Quieres que genere el script SQL `CREATE TABLE` para alguna de estas entidades, o definimos índices y restricciones adicionales?

De acuerdo a tu respuesta anterior puedes generar un script en SQL para descargar con el nombre de bdrappi.sql para las 11 entidades con sus relaciones

