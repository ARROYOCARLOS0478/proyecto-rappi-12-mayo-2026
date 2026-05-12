-- =============================================================
--  BASE DE DATOS: RAPPI
--  Descripción  : Script de creación de esquema para plataforma
--                 de delivery tipo Rappi.
--  Motor        : MySQL 8.0+ / MariaDB 10.6+
--  Codificación : UTF-8
--  Generado     : 2026
-- =============================================================

CREATE DATABASE IF NOT EXISTS bdrappi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bdrappi;

-- -------------------------------------------------------------
-- 0. EXTENSIONES / CONFIGURACIÓN
-- -------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


-- =============================================================
-- DOMINIO 1: USUARIOS Y ACCESO
-- =============================================================

-- -------------------------------------------------------------
-- Tabla: USUARIO
-- Almacena clientes, repartidores y administradores.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuario (
    id               CHAR(36)        NOT NULL DEFAULT (UUID()),
    nombre           VARCHAR(100)    NOT NULL,
    apellido         VARCHAR(100)    NOT NULL,
    email            VARCHAR(255)    NOT NULL,
    telefono         VARCHAR(20)     NOT NULL,
    password_hash    VARCHAR(255)    NOT NULL,
    rol              ENUM('cliente','repartidor','admin') NOT NULL DEFAULT 'cliente',
    activo           BOOLEAN         NOT NULL DEFAULT TRUE,
    creado_en        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_usuario          PRIMARY KEY (id),
    CONSTRAINT uq_usuario_email    UNIQUE      (email),
    CONSTRAINT uq_usuario_telefono UNIQUE      (telefono)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Usuarios del sistema: clientes, repartidores y administradores.';

CREATE INDEX idx_usuario_rol    ON usuario (rol);
CREATE INDEX idx_usuario_activo ON usuario (activo);


-- -------------------------------------------------------------
-- Tabla: DIRECCION
-- Direcciones de entrega asociadas a un usuario.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS direccion (
    id           CHAR(36)        NOT NULL DEFAULT (UUID()),
    usuario_id   CHAR(36)        NOT NULL,
    alias        VARCHAR(50)              DEFAULT NULL COMMENT 'Casa, Oficina, etc.',
    calle        VARCHAR(255)    NOT NULL,
    numero_ext   VARCHAR(20)              DEFAULT NULL,
    numero_int   VARCHAR(20)              DEFAULT NULL,
    colonia      VARCHAR(100)             DEFAULT NULL,
    ciudad       VARCHAR(100)    NOT NULL,
    estado       VARCHAR(100)             DEFAULT NULL,
    codigo_postal VARCHAR(10)             DEFAULT NULL,
    latitud      DECIMAL(10,7)   NOT NULL,
    longitud     DECIMAL(10,7)   NOT NULL,
    predeterminada BOOLEAN       NOT NULL DEFAULT FALSE,
    activa       BOOLEAN         NOT NULL DEFAULT TRUE,
    creado_en    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_direccion        PRIMARY KEY (id),
    CONSTRAINT fk_direccion_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Direcciones de entrega por usuario.';

CREATE INDEX idx_direccion_usuario ON direccion (usuario_id);
CREATE INDEX idx_direccion_coords  ON direccion (latitud, longitud);


-- =============================================================
-- DOMINIO 2: CATÁLOGO
-- =============================================================

-- -------------------------------------------------------------
-- Tabla: COMERCIO
-- Restaurantes, tiendas o cualquier establecimiento en la app.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comercio (
    id                   CHAR(36)       NOT NULL DEFAULT (UUID()),
    nombre               VARCHAR(150)   NOT NULL,
    descripcion          TEXT                    DEFAULT NULL,
    categoria            VARCHAR(80)    NOT NULL,
    logo_url             VARCHAR(500)            DEFAULT NULL,
    telefono             VARCHAR(20)             DEFAULT NULL,
    email                VARCHAR(255)            DEFAULT NULL,
    latitud              DECIMAL(10,7)  NOT NULL,
    longitud             DECIMAL(10,7)  NOT NULL,
    radio_entrega_km     DECIMAL(5,2)   NOT NULL DEFAULT 5.00,
    tiempo_entrega_min   SMALLINT       NOT NULL DEFAULT 30,
    calificacion_promedio DECIMAL(3,2)  NOT NULL DEFAULT 0.00,
    activo               BOOLEAN        NOT NULL DEFAULT TRUE,
    creado_en            TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_comercio PRIMARY KEY (id),
    CONSTRAINT chk_calificacion CHECK (calificacion_promedio BETWEEN 0 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Establecimientos registrados en la plataforma.';

CREATE INDEX idx_comercio_categoria ON comercio (categoria);
CREATE INDEX idx_comercio_activo    ON comercio (activo);
CREATE INDEX idx_comercio_coords    ON comercio (latitud, longitud);


-- -------------------------------------------------------------
-- Tabla: CATEGORIA_PRODUCTO
-- Agrupaciones de productos dentro de un comercio.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categoria_producto (
    id          CHAR(36)      NOT NULL DEFAULT (UUID()),
    comercio_id CHAR(36)      NOT NULL,
    nombre      VARCHAR(100)  NOT NULL,
    descripcion VARCHAR(255)           DEFAULT NULL,
    orden       SMALLINT      NOT NULL DEFAULT 0 COMMENT 'Posición de despliegue',
    activa      BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_categoria_producto PRIMARY KEY (id),
    CONSTRAINT fk_catprod_comercio
        FOREIGN KEY (comercio_id) REFERENCES comercio (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorías de productos por comercio.';

CREATE INDEX idx_catprod_comercio ON categoria_producto (comercio_id);


-- -------------------------------------------------------------
-- Tabla: PRODUCTO
-- Ítems disponibles en el menú / catálogo de un comercio.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS producto (
    id           CHAR(36)       NOT NULL DEFAULT (UUID()),
    comercio_id  CHAR(36)       NOT NULL,
    categoria_id CHAR(36)                DEFAULT NULL,
    nombre       VARCHAR(150)   NOT NULL,
    descripcion  TEXT                    DEFAULT NULL,
    precio       DECIMAL(10,2)  NOT NULL,
    imagen_url   VARCHAR(500)            DEFAULT NULL,
    disponible   BOOLEAN        NOT NULL DEFAULT TRUE,
    orden        SMALLINT       NOT NULL DEFAULT 0,
    creado_en    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_producto       PRIMARY KEY (id),
    CONSTRAINT chk_precio        CHECK (precio >= 0),
    CONSTRAINT fk_producto_comercio
        FOREIGN KEY (comercio_id)  REFERENCES comercio          (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id) REFERENCES categoria_producto (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Productos o platillos ofrecidos por los comercios.';

CREATE INDEX idx_producto_comercio   ON producto (comercio_id);
CREATE INDEX idx_producto_categoria  ON producto (categoria_id);
CREATE INDEX idx_producto_disponible ON producto (disponible);


-- =============================================================
-- DOMINIO 3: LOGÍSTICA
-- =============================================================

-- -------------------------------------------------------------
-- Tabla: REPARTIDOR
-- Perfil operativo del repartidor (extiende usuario).
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS repartidor (
    id                   CHAR(36)      NOT NULL DEFAULT (UUID()),
    usuario_id           CHAR(36)      NOT NULL,
    tipo_vehiculo        ENUM('bicicleta','moto','auto','caminando') NOT NULL DEFAULT 'moto',
    placa_vehiculo       VARCHAR(20)            DEFAULT NULL,
    foto_url             VARCHAR(500)           DEFAULT NULL,
    disponible           BOOLEAN       NOT NULL DEFAULT FALSE,
    lat_actual           DECIMAL(10,7)          DEFAULT NULL,
    lng_actual           DECIMAL(10,7)          DEFAULT NULL,
    calificacion_promedio DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_entregas       INTEGER       NOT NULL DEFAULT 0,
    activo               BOOLEAN       NOT NULL DEFAULT TRUE,
    creado_en            TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_repartidor       PRIMARY KEY (id),
    CONSTRAINT uq_repartidor_usr   UNIQUE      (usuario_id),
    CONSTRAINT chk_cal_repartidor  CHECK (calificacion_promedio BETWEEN 0 AND 5),
    CONSTRAINT fk_repartidor_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Perfil operativo de los repartidores.';

CREATE INDEX idx_repartidor_disponible ON repartidor (disponible);
CREATE INDEX idx_repartidor_coords     ON repartidor (lat_actual, lng_actual);


-- =============================================================
-- DOMINIO 4: PEDIDOS
-- =============================================================

-- -------------------------------------------------------------
-- Tabla: CUPON
-- Cupones de descuento aplicables a pedidos.
-- (Se crea antes que PEDIDO por la FK)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cupon (
    id                  CHAR(36)      NOT NULL DEFAULT (UUID()),
    codigo              VARCHAR(30)   NOT NULL,
    tipo                ENUM('porcentaje','monto_fijo','envio_gratis') NOT NULL,
    valor               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    minimo_pedido       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    uso_maximo          INTEGER                DEFAULT NULL COMMENT 'NULL = ilimitado',
    uso_actual          INTEGER       NOT NULL DEFAULT 0,
    un_uso_por_usuario  BOOLEAN       NOT NULL DEFAULT TRUE,
    activo              BOOLEAN       NOT NULL DEFAULT TRUE,
    expira_en           TIMESTAMP              DEFAULT NULL,
    creado_en           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_cupon      PRIMARY KEY (id),
    CONSTRAINT uq_cupon_cod  UNIQUE      (codigo),
    CONSTRAINT chk_cupon_val CHECK (valor >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cupones y promociones de descuento.';

CREATE INDEX idx_cupon_activo ON cupon (activo);


-- -------------------------------------------------------------
-- Tabla: PEDIDO
-- Nodo central del sistema; conecta cliente, comercio y repartidor.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedido (
    id             CHAR(36)       NOT NULL DEFAULT (UUID()),
    cliente_id     CHAR(36)       NOT NULL,
    comercio_id    CHAR(36)       NOT NULL,
    repartidor_id  CHAR(36)                DEFAULT NULL,
    direccion_id   CHAR(36)       NOT NULL,
    cupon_id       CHAR(36)                DEFAULT NULL,
    estado         ENUM('pendiente','confirmado','preparando','en_camino','entregado','cancelado')
                                  NOT NULL DEFAULT 'pendiente',
    subtotal       DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    costo_envio    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    descuento      DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    total          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    notas          TEXT                    DEFAULT NULL,
    creado_en      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    entregado_en   TIMESTAMP               DEFAULT NULL,

    CONSTRAINT pk_pedido          PRIMARY KEY (id),
    CONSTRAINT chk_pedido_total   CHECK (total >= 0),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (cliente_id)    REFERENCES usuario     (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_comercio
        FOREIGN KEY (comercio_id)   REFERENCES comercio    (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_repartidor
        FOREIGN KEY (repartidor_id) REFERENCES repartidor  (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_direccion
        FOREIGN KEY (direccion_id)  REFERENCES direccion   (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_cupon
        FOREIGN KEY (cupon_id)      REFERENCES cupon       (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pedidos realizados por los clientes.';

CREATE INDEX idx_pedido_cliente     ON pedido (cliente_id);
CREATE INDEX idx_pedido_comercio    ON pedido (comercio_id);
CREATE INDEX idx_pedido_repartidor  ON pedido (repartidor_id);
CREATE INDEX idx_pedido_estado      ON pedido (estado);
CREATE INDEX idx_pedido_creado      ON pedido (creado_en);


-- -------------------------------------------------------------
-- Tabla: ITEM_PEDIDO
-- Líneas de detalle de cada pedido.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS item_pedido (
    id               CHAR(36)       NOT NULL DEFAULT (UUID()),
    pedido_id        CHAR(36)       NOT NULL,
    producto_id      CHAR(36)                DEFAULT NULL,
    nombre_producto  VARCHAR(150)   NOT NULL COMMENT 'Snapshot del nombre al momento del pedido',
    cantidad         SMALLINT       NOT NULL DEFAULT 1,
    precio_unitario  DECIMAL(10,2)  NOT NULL COMMENT 'Snapshot del precio al momento del pedido',
    subtotal         DECIMAL(10,2)  NOT NULL,
    notas            VARCHAR(255)            DEFAULT NULL,

    CONSTRAINT pk_item_pedido      PRIMARY KEY (id),
    CONSTRAINT chk_item_cantidad   CHECK (cantidad > 0),
    CONSTRAINT chk_item_precio     CHECK (precio_unitario >= 0),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (pedido_id)   REFERENCES pedido   (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_item_producto
        FOREIGN KEY (producto_id) REFERENCES producto  (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Detalle de productos en cada pedido.';

CREATE INDEX idx_item_pedido   ON item_pedido (pedido_id);
CREATE INDEX idx_item_producto ON item_pedido (producto_id);


-- =============================================================
-- DOMINIO 5: PAGOS Y CALIDAD
-- =============================================================

-- -------------------------------------------------------------
-- Tabla: PAGO
-- Registro de transacciones financieras por pedido.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pago (
    id                  CHAR(36)       NOT NULL DEFAULT (UUID()),
    pedido_id           CHAR(36)       NOT NULL,
    metodo              ENUM('efectivo','tarjeta','wallet','transferencia') NOT NULL,
    estado              ENUM('pendiente','aprobado','rechazado','reembolsado') NOT NULL DEFAULT 'pendiente',
    monto               DECIMAL(10,2)  NOT NULL,
    moneda              CHAR(3)        NOT NULL DEFAULT 'MXN',
    referencia_externa  VARCHAR(255)            DEFAULT NULL COMMENT 'ID de pasarela de pago',
    procesado_en        TIMESTAMP               DEFAULT NULL,
    creado_en           TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_pago         PRIMARY KEY (id),
    CONSTRAINT uq_pago_pedido  UNIQUE      (pedido_id),
    CONSTRAINT chk_pago_monto  CHECK (monto >= 0),
    CONSTRAINT fk_pago_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedido (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Transacciones de pago asociadas a pedidos.';

CREATE INDEX idx_pago_estado ON pago (estado);


-- -------------------------------------------------------------
-- Tabla: CALIFICACION
-- Reseñas del cliente al comercio o al repartidor.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calificacion (
    id             CHAR(36)    NOT NULL DEFAULT (UUID()),
    pedido_id      CHAR(36)    NOT NULL,
    autor_id       CHAR(36)    NOT NULL COMMENT 'FK a usuario (cliente)',
    tipo_objetivo  ENUM('comercio','repartidor') NOT NULL,
    objetivo_id    CHAR(36)    NOT NULL COMMENT 'ID del comercio o repartidor calificado',
    puntuacion     TINYINT     NOT NULL,
    comentario     TEXT                 DEFAULT NULL,
    creado_en      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_calificacion     PRIMARY KEY (id),
    CONSTRAINT chk_puntuacion      CHECK (puntuacion BETWEEN 1 AND 5),
    CONSTRAINT uq_cal_pedido_tipo  UNIQUE (pedido_id, tipo_objetivo) COMMENT 'Una calificación por tipo por pedido',
    CONSTRAINT fk_cal_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedido   (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_cal_autor
        FOREIGN KEY (autor_id)  REFERENCES usuario  (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Calificaciones de clientes a comercios y repartidores.';

CREATE INDEX idx_cal_objetivo   ON calificacion (tipo_objetivo, objetivo_id);
CREATE INDEX idx_cal_pedido     ON calificacion (pedido_id);


-- =============================================================
-- RE-HABILITAR VERIFICACIÓN DE CLAVES FORÁNEAS
-- =============================================================
SET FOREIGN_KEY_CHECKS = 1;


-- =============================================================
-- DATOS INICIALES DE PRUEBA (SEED)
-- =============================================================

-- Usuario administrador
INSERT INTO usuario (id, nombre, apellido, email, telefono, password_hash, rol)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Admin', 'Sistema',
    'admin@bdrappi.com',
    '+525500000000',
    '$2b$12$placeholderHashAdmin',
    'admin'
);

-- Usuario cliente de prueba
INSERT INTO usuario (id, nombre, apellido, email, telefono, password_hash, rol)
VALUES (
    'a0000000-0000-0000-0000-000000000002',
    'Juan', 'Pérez',
    'juan@ejemplo.com',
    '+525511111111',
    '$2b$12$placeholderHashCliente',
    'cliente'
);

-- Usuario repartidor de prueba
INSERT INTO usuario (id, nombre, apellido, email, telefono, password_hash, rol)
VALUES (
    'a0000000-0000-0000-0000-000000000003',
    'Carlos', 'López',
    'carlos@ejemplo.com',
    '+525522222222',
    '$2b$12$placeholderHashRepartidor',
    'repartidor'
);

-- Repartidor asociado
INSERT INTO repartidor (id, usuario_id, tipo_vehiculo, disponible)
VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000003',
    'moto',
    TRUE
);

-- Dirección del cliente
INSERT INTO direccion (id, usuario_id, alias, calle, numero_ext, colonia, ciudad, latitud, longitud, predeterminada)
VALUES (
    'c0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    'Casa',
    'Av. Tecnológico',
    '100',
    'Centro',
    'Ciudad Juárez',
    31.6904,
    -106.4245,
    TRUE
);

-- Comercio de prueba
INSERT INTO comercio (id, nombre, categoria, latitud, longitud, tiempo_entrega_min)
VALUES (
    'd0000000-0000-0000-0000-000000000001',
    'Tacos El Norteño',
    'Comida mexicana',
    31.6850,
    -106.4300,
    25
);

-- Categoría de productos
INSERT INTO categoria_producto (id, comercio_id, nombre, orden)
VALUES (
    'e0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000001',
    'Tacos',
    1
);

-- Productos de prueba
INSERT INTO producto (id, comercio_id, categoria_id, nombre, precio)
VALUES
    ('f0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'Taco de pastor', 25.00),
    ('f0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'Taco de bistec', 28.00);

-- Cupón de prueba
INSERT INTO cupon (id, codigo, tipo, valor, minimo_pedido, uso_maximo)
VALUES (
    'g0000000-0000-0000-0000-000000000001',
    'BIENVENIDO20',
    'porcentaje',
    20.00,
    100.00,
    500
);


-- =============================================================
-- VISTAS ÚTILES
-- =============================================================

CREATE OR REPLACE VIEW v_pedidos_detalle AS
SELECT
    p.id              AS pedido_id,
    p.estado,
    p.total,
    p.creado_en,
    CONCAT(u.nombre, ' ', u.apellido) AS cliente,
    u.telefono        AS tel_cliente,
    c.nombre          AS comercio,
    CONCAT(r_usr.nombre, ' ', r_usr.apellido) AS repartidor,
    d.calle           AS direccion_entrega,
    d.ciudad
FROM pedido p
JOIN usuario   u     ON u.id = p.cliente_id
JOIN comercio  c     ON c.id = p.comercio_id
JOIN direccion d     ON d.id = p.direccion_id
LEFT JOIN repartidor rep   ON rep.id = p.repartidor_id
LEFT JOIN usuario    r_usr ON r_usr.id = rep.usuario_id;


CREATE OR REPLACE VIEW v_comercio_calificaciones AS
SELECT
    c.id,
    c.nombre,
    c.categoria,
    ROUND(AVG(cal.puntuacion), 2) AS promedio,
    COUNT(cal.id)                 AS total_resenas
FROM comercio c
LEFT JOIN calificacion cal ON cal.objetivo_id = c.id AND cal.tipo_objetivo = 'comercio'
GROUP BY c.id, c.nombre, c.categoria;


-- =============================================================
-- FIN DEL SCRIPT - bdrappi.sql
-- =============================================================
