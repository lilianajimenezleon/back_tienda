-- ============================================================
-- SCRIPT DE CREACION COMPLETA DE LA BASE DE DATOS
-- TiendaDB - Sistema de Inventario Multi-Tienda
-- PostgreSQL
-- ============================================================

-- 0. Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. TABLAS
-- ============================================================

-- 1.1 USUARIOS
CREATE TABLE public.usuarios (
    id_usuario               UUID DEFAULT uuid_generate_v4() NOT NULL,
    nombre_completo          VARCHAR(200) NOT NULL,
    usuario                  VARCHAR(100) NOT NULL,
    correo                   VARCHAR(150) NOT NULL,
    contraseña_hash          VARCHAR(255) NOT NULL,
    rol                      TEXT NOT NULL,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    intentos_fallidos        INTEGER NOT NULL DEFAULT 0,
    bloqueado_hasta          TIMESTAMP WITHOUT TIME ZONE,
    fecha_creacion           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_modificacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creado_por               UUID,
    CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario)
);

CREATE UNIQUE INDEX ix_usuarios_usuario ON public.usuarios (usuario);
CREATE UNIQUE INDEX ix_usuarios_correo ON public.usuarios (correo);

-- 1.2 TIENDAS
CREATE TABLE public.tiendas (
    id_tienda                UUID DEFAULT uuid_generate_v4() NOT NULL,
    nombre_tienda            VARCHAR(200) NOT NULL,
    direccion                TEXT,
    telefono                 VARCHAR(20),
    correo_tienda            VARCHAR(150),
    nit                      VARCHAR(50),
    id_dueño                 UUID NOT NULL,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_modificacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tiendas PRIMARY KEY (id_tienda),
    CONSTRAINT fk_tiendas_usuarios FOREIGN KEY (id_dueño)
        REFERENCES public.usuarios (id_usuario) ON DELETE RESTRICT
);

CREATE INDEX ix_tiendas_id_dueño ON public.tiendas (id_dueño);

-- 1.3 CATEGORIAS
CREATE TABLE public.categorias (
    id_categoria             UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    nombre_categoria         VARCHAR(100) NOT NULL,
    descripcion              TEXT,
    fecha_creacion           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_categorias PRIMARY KEY (id_categoria),
    CONSTRAINT fk_categorias_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE
);

CREATE UNIQUE INDEX ix_categorias_tienda_nombre ON public.categorias (id_tienda, nombre_categoria);

-- 1.4 EMPLEADOS_TIENDAS
CREATE TABLE public.empleados_tiendas (
    id_empleado_tienda       UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_empleado              UUID NOT NULL,
    id_tienda                UUID NOT NULL,
    puede_ver_reportes       BOOLEAN NOT NULL DEFAULT FALSE,
    puede_gestionar_inventario BOOLEAN NOT NULL DEFAULT TRUE,
    puede_registrar_ventas   BOOLEAN NOT NULL DEFAULT TRUE,
    puede_registrar_compras  BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_asignacion         TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_empleados_tiendas PRIMARY KEY (id_empleado_tienda),
    CONSTRAINT fk_empleados_tiendas_usuarios FOREIGN KEY (id_empleado)
        REFERENCES public.usuarios (id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_empleados_tiendas_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE
);

CREATE UNIQUE INDEX ix_empleados_tiendas_empleado_tienda ON public.empleados_tiendas (id_empleado, id_tienda);
CREATE INDEX ix_empleados_tiendas_id_tienda ON public.empleados_tiendas (id_tienda);

-- 1.5 PROVEEDORES
CREATE TABLE public.proveedores (
    id_proveedor             UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    nombre_proveedor         VARCHAR(200) NOT NULL,
    nit                      VARCHAR(50),
    telefono                 VARCHAR(20),
    correo                   VARCHAR(150),
    direccion                TEXT,
    fecha_creacion           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_proveedores PRIMARY KEY (id_proveedor),
    CONSTRAINT fk_proveedores_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE
);

CREATE UNIQUE INDEX ix_proveedores_tienda_nombre ON public.proveedores (id_tienda, nombre_proveedor);

-- 1.6 PRODUCTOS
CREATE TABLE public.productos (
    id_producto              UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    id_categoria             UUID,
    codigo_producto          VARCHAR(100),
    nombre_producto          VARCHAR(200) NOT NULL,
    descripcion              TEXT,
    precio_venta             NUMERIC(12,2) NOT NULL,
    precio_compra            NUMERIC(12,2),
    stock_actual             INTEGER NOT NULL DEFAULT 0,
    stock_minimo             INTEGER NOT NULL DEFAULT 0,
    unidad_medida            VARCHAR(50) NOT NULL DEFAULT 'UNIDAD',
    fecha_creacion           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_modificacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_productos PRIMARY KEY (id_producto),
    CONSTRAINT fk_productos_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_productos_categorias FOREIGN KEY (id_categoria)
        REFERENCES public.categorias (id_categoria) ON DELETE SET NULL
);

CREATE UNIQUE INDEX ix_productos_tienda_codigo ON public.productos (id_tienda, codigo_producto);
CREATE INDEX ix_productos_id_categoria ON public.productos (id_categoria);

-- 1.7 VENTAS
CREATE TABLE public.ventas (
    id_venta                 UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    id_usuario               UUID NOT NULL,
    fecha_venta              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_venta              NUMERIC(12,2) NOT NULL DEFAULT 0,
    metodo_pago              VARCHAR(50),
    observaciones            TEXT,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_ventas PRIMARY KEY (id_venta),
    CONSTRAINT fk_ventas_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_ventas_usuarios FOREIGN KEY (id_usuario)
        REFERENCES public.usuarios (id_usuario) ON DELETE RESTRICT
);

CREATE INDEX ix_ventas_id_tienda ON public.ventas (id_tienda);
CREATE INDEX ix_ventas_id_usuario ON public.ventas (id_usuario);

-- 1.8 DETALLE_VENTAS
CREATE TABLE public.detalle_ventas (
    id_detalle_venta         UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_venta                 UUID NOT NULL,
    id_producto              UUID NOT NULL,
    cantidad                 INTEGER NOT NULL,
    precio_unitario          NUMERIC(12,2) NOT NULL,
    subtotal                 NUMERIC(12,2) NOT NULL,
    CONSTRAINT pk_detalle_ventas PRIMARY KEY (id_detalle_venta),
    CONSTRAINT fk_detalle_ventas_ventas FOREIGN KEY (id_venta)
        REFERENCES public.ventas (id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_ventas_productos FOREIGN KEY (id_producto)
        REFERENCES public.productos (id_producto) ON DELETE CASCADE
);

CREATE INDEX ix_detalle_ventas_id_venta ON public.detalle_ventas (id_venta);
CREATE INDEX ix_detalle_ventas_id_producto ON public.detalle_ventas (id_producto);

-- 1.9 COMPRAS
CREATE TABLE public.compras (
    id_compra                UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    id_proveedor             UUID,
    id_usuario               UUID NOT NULL,
    numero_factura           VARCHAR(100),
    fecha_compra             TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_compra             NUMERIC(12,2) NOT NULL DEFAULT 0,
    observaciones            TEXT,
    estado                   TEXT NOT NULL DEFAULT 'ACTIVO',
    puede_editar             BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_limite_edicion     TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT pk_compras PRIMARY KEY (id_compra),
    CONSTRAINT fk_compras_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_compras_proveedores FOREIGN KEY (id_proveedor)
        REFERENCES public.proveedores (id_proveedor) ON DELETE SET NULL,
    CONSTRAINT fk_compras_usuarios FOREIGN KEY (id_usuario)
        REFERENCES public.usuarios (id_usuario) ON DELETE RESTRICT
);

CREATE INDEX ix_compras_id_tienda ON public.compras (id_tienda);
CREATE INDEX ix_compras_id_proveedor ON public.compras (id_proveedor);
CREATE INDEX ix_compras_id_usuario ON public.compras (id_usuario);

-- 1.10 DETALLE_COMPRAS
CREATE TABLE public.detalle_compras (
    id_detalle_compra        UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_compra                UUID NOT NULL,
    id_producto              UUID NOT NULL,
    cantidad                 INTEGER NOT NULL,
    precio_unitario          NUMERIC(12,2) NOT NULL,
    subtotal                 NUMERIC(12,2) NOT NULL,
    CONSTRAINT pk_detalle_compras PRIMARY KEY (id_detalle_compra),
    CONSTRAINT fk_detalle_compras_compras FOREIGN KEY (id_compra)
        REFERENCES public.compras (id_compra) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_compras_productos FOREIGN KEY (id_producto)
        REFERENCES public.productos (id_producto) ON DELETE CASCADE
);

CREATE INDEX ix_detalle_compras_id_compra ON public.detalle_compras (id_compra);
CREATE INDEX ix_detalle_compras_id_producto ON public.detalle_compras (id_producto);

-- 1.11 DEVOLUCIONES
CREATE TABLE public.devoluciones (
    id_devolucion            UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_venta                 UUID NOT NULL,
    id_producto              UUID NOT NULL,
    id_usuario               UUID NOT NULL,
    cantidad                 INTEGER NOT NULL,
    motivo                   TEXT,
    fecha_devolucion         TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto_devuelto           NUMERIC(12,2),
    CONSTRAINT pk_devoluciones PRIMARY KEY (id_devolucion),
    CONSTRAINT fk_devoluciones_ventas FOREIGN KEY (id_venta)
        REFERENCES public.ventas (id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_devoluciones_productos FOREIGN KEY (id_producto)
        REFERENCES public.productos (id_producto) ON DELETE CASCADE,
    CONSTRAINT fk_devoluciones_usuarios FOREIGN KEY (id_usuario)
        REFERENCES public.usuarios (id_usuario) ON DELETE CASCADE
);

-- 1.12 MERMAS
CREATE TABLE public.mermas (
    id_merma                 UUID DEFAULT uuid_generate_v4() NOT NULL,
    id_tienda                UUID NOT NULL,
    id_producto              UUID NOT NULL,
    id_usuario               UUID NOT NULL,
    cantidad                 INTEGER NOT NULL,
    motivo                   VARCHAR(100),
    descripcion              TEXT,
    fecha_merma              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mermas PRIMARY KEY (id_merma),
    CONSTRAINT fk_mermas_tiendas FOREIGN KEY (id_tienda)
        REFERENCES public.tiendas (id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_mermas_productos FOREIGN KEY (id_producto)
        REFERENCES public.productos (id_producto) ON DELETE CASCADE,
    CONSTRAINT fk_mermas_usuarios FOREIGN KEY (id_usuario)
        REFERENCES public.usuarios (id_usuario) ON DELETE CASCADE
);

-- ============================================================
-- 2. DATOS INICIALES
-- ============================================================

-- 2.1 USUARIOS ADMINISTRADORES (clave: 12345678)
-- Hash BCrypt generado con costo 10
INSERT INTO public.usuarios (id_usuario, nombre_completo, usuario, correo, contraseña_hash, rol, estado)
VALUES
    (uuid_generate_v4(), 'Administrador Sistema', 'admin', 'admin@tiendadb.com',
     '$2b$10$bdpfhSQ6hjMAEKTVZ1hmnO.mt.RhSpvkKoffJ8OUf9z3DGWh.4PVG',
     'ADMIN_SISTEMA', 'ACTIVO'),
    (uuid_generate_v4(), 'Super Administrador', 'superadmin', 'superadmin@tiendadb.com',
     '$2b$10$bdpfhSQ6hjMAEKTVZ1hmnO.mt.RhSpvkKoffJ8OUf9z3DGWh.4PVG',
     'ADMIN_SISTEMA', 'ACTIVO');
