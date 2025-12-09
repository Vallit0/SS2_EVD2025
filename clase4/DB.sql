-- DIMENSIONES
CREATE TABLE dim_fecha (
    id_fecha    INT PRIMARY KEY,
    anio        INT NOT NULL,
    nombre_mes  NVARCHAR(20),
    trimestre   NVARCHAR(20),
    dia         NVARCHAR(20),
    mes         INT NOT NULL
);

CREATE TABLE dim_producto (
    CodProducto     NVARCHAR(50) PRIMARY KEY,
    NombreProducto  NVARCHAR(200),
    MarcaProducto   NVARCHAR(100),
    Categoria       NVARCHAR(100)
);

CREATE TABLE dim_sucursal (
    CodSucursal     NVARCHAR(50) PRIMARY KEY,
    NombreSucursal  NVARCHAR(200),
    Region          NVARCHAR(100),
    Departamento    NVARCHAR(100)
);

CREATE TABLE dim_cliente (
    CodCliente      NVARCHAR(50) PRIMARY KEY,
    NombreCliente   NVARCHAR(200),
    TipoCliente     NVARCHAR(100)
);

CREATE TABLE dim_vendedor (
    CodVendedor     NVARCHAR(50) PRIMARY KEY,
    NombreVendedor  NVARCHAR(200)
);

CREATE TABLE dim_proveedor (
    CodProveedor    NVARCHAR(50) PRIMARY KEY,
    NombreProveedor NVARCHAR(200)
);

-- HECHOS
CREATE TABLE fac_ventas (
    id_venta        INT IDENTITY(1,1) PRIMARY KEY,
    id_fecha        INT NOT NULL,
    CodProducto     NVARCHAR(50) NOT NULL,
    CodSucursal     NVARCHAR(50) NOT NULL,
    CodCliente      NVARCHAR(50) NOT NULL,
    CodVendedor     NVARCHAR(50) NOT NULL,
    unidades        INT NOT NULL,
    precioUnitario  DECIMAL(10,2),
    total_venta     AS (unidades * precioUnitario) PERSISTED,

);

CREATE TABLE fac_compras (
    id_compra       INT IDENTITY(1,1) PRIMARY KEY,
    id_fecha        INT NOT NULL,
    CodProducto     NVARCHAR(50) NOT NULL,
    CodSucursal     NVARCHAR(50) NOT NULL,
    CodProveedor    NVARCHAR(50) NOT NULL,
    unidades        INT NOT NULL,
    costoUnitario   DECIMAL(10,2),
    total_compra    AS (unidades * costoUnitario) PERSISTED,
    FOREIGN KEY (id_fecha)     REFERENCES dim_fecha(id_fecha),
    FOREIGN KEY (CodProducto)  REFERENCES dim_producto(CodProducto),
    FOREIGN KEY (CodSucursal)  REFERENCES dim_sucursal(CodSucursal),
    FOREIGN KEY (CodProveedor) REFERENCES dim_proveedor(CodProveedor)
);