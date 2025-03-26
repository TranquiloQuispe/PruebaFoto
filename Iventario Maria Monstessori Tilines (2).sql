-- Crear la base de datos "CONEXCION CON LA BASE DE DATOS: "DESKTOP-QR0D1P2"
CREATE DATABASE InventarioInstitutoMariaMontessori;
GO

-- Usar la base de datos creada
USE InventarioInstitutoMariaMontessori;
GO

-- Tabla: Encargado
CREATE TABLE Encargado (
    ID_Encargado INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100) NOT NULL,
    Cargo NVARCHAR(100),
    Departamento NVARCHAR(100)
);
GO

-- Tabla: Categoría
CREATE TABLE Categoria (
    ID_Categoria INT PRIMARY KEY IDENTITY,
    NombreCategoria NVARCHAR(100) NOT NULL
);
GO

-- Tabla: Proveedor
CREATE TABLE Proveedor (
    ID_Proveedor INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100) NOT NULL,
    Direccion NVARCHAR(255),
    Telefono NVARCHAR(15),
    Email NVARCHAR(100),
    PersonaDeContacto NVARCHAR(100)
);
GO

-- Tabla: Ubicación
CREATE TABLE Ubicacion (
    ID_Ubicacion INT PRIMARY KEY IDENTITY,
    UbicacionFisica NVARCHAR(100) NOT NULL,
    EspacioEspecifico NVARCHAR(100)
);
GO

-- Tabla: Roles
CREATE TABLE Roles (
    ID_Rol INT PRIMARY KEY IDENTITY,
    NombreRol NVARCHAR(50) NOT NULL
);
GO

-- Tabla: Usuario
CREATE TABLE Usuario (
    ID_Usuario INT PRIMARY KEY IDENTITY,
    NombreUsuario NVARCHAR(50) NOT NULL,
    Contraseña NVARCHAR(255) NOT NULL, -- Se debe almacenar la contraseña con hashing en la aplicación
    ID_Rol INT NOT NULL,
    FOREIGN KEY (ID_Rol) REFERENCES Roles(ID_Rol) ON DELETE CASCADE
);
GO

-- Tabla: Producto
CREATE TABLE Producto (
    ID_Producto INT PRIMARY KEY IDENTITY,
    CodigoPatrimonio NVARCHAR(50) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad >= 0),
    Estado NVARCHAR(50),
    Precio DECIMAL(18, 2),
    FechaAdquisicion DATE,
    ID_Proveedor INT,
    Descripcion NVARCHAR(255),
    ID_Categoria INT,
    ID_Ubicacion INT,
    Modelo NVARCHAR(100),
    Serie NVARCHAR(100),
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedor(ID_Proveedor) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ID_Categoria) REFERENCES Categoria(ID_Categoria) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ID_Ubicacion) REFERENCES Ubicacion(ID_Ubicacion) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Tabla: Mantenimiento
CREATE TABLE Mantenimiento (
    ID_Mantenimiento INT PRIMARY KEY IDENTITY,
    FechaMantenimiento DATE NOT NULL,
    DescripcionActividad NVARCHAR(255),
    Costo DECIMAL(18, 2),
    ID_Producto INT NOT NULL,
    ID_Encargado INT NOT NULL,
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto),
    FOREIGN KEY (ID_Encargado) REFERENCES Encargado(ID_Encargado)
);
GO

-- Tabla: Pedido
CREATE TABLE Pedido (
    ID_Pedido INT PRIMARY KEY IDENTITY,
    FechaPedido DATE NOT NULL,
    CantidadProductos INT NOT NULL,
    EstadoPedido NVARCHAR(50) CHECK (EstadoPedido IN ('Pendiente', 'Enviado', 'Recibido')),
    ID_Proveedor INT NOT NULL,
    ID_Producto INT NOT NULL,
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedor(ID_Proveedor),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto)
);
GO

-- Tabla: MovimientoInventario
CREATE TABLE MovimientoInventario (
    ID_Movimiento INT PRIMARY KEY IDENTITY,
    ID_Producto INT NOT NULL,
    FechaMovimiento DATETIME NOT NULL,
    TipoMovimiento NVARCHAR(50) CHECK (TipoMovimiento IN ('Entrada', 'Salida', 'Ajuste', 'Transferencia')) NOT NULL,
    Cantidad INT NOT NULL,
    ID_Usuario INT NOT NULL,
    Motivo NVARCHAR(255),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto) ON DELETE CASCADE,
    FOREIGN KEY (ID_Usuario) REFERENCES Usuario(ID_Usuario) ON DELETE CASCADE
);
GO

-- Tabla: Alertas
CREATE TABLE Alertas (
    ID_Alerta INT PRIMARY KEY IDENTITY,
    TipoAlerta NVARCHAR(50) CHECK (TipoAlerta IN ('Bajo Inventario', 'Próximo Mantenimiento')) NOT NULL,
    Descripcion NVARCHAR(255),
    FechaGeneracion DATETIME NOT NULL DEFAULT GETDATE(),
    Estado NVARCHAR(50) CHECK (Estado IN ('Pendiente', 'Resuelto')) NOT NULL
);
GO

-- Tabla: Permisos
CREATE TABLE Permisos (
    ID_Permiso INT PRIMARY KEY IDENTITY,
    NombrePermiso NVARCHAR(100) NOT NULL
);
GO

-- Tabla: RolPermiso
CREATE TABLE RolPermiso (
    ID_Rol INT NOT NULL,
    ID_Permiso INT NOT NULL,
    PRIMARY KEY (ID_Rol, ID_Permiso),
    FOREIGN KEY (ID_Rol) REFERENCES Roles(ID_Rol) ON DELETE CASCADE,
    FOREIGN KEY (ID_Permiso) REFERENCES Permisos(ID_Permiso) ON DELETE CASCADE
);
GO

-- Índices para optimizar las consultas
CREATE INDEX IDX_Producto_Nombre ON Producto(Nombre);
CREATE INDEX IDX_Producto_CodigoPatrimonio ON Producto(CodigoPatrimonio);
CREATE INDEX IDX_MovimientoInventario_Fecha ON MovimientoInventario(FechaMovimiento);
GO

-- Procedimientos almacenados para operaciones comunes
-- Procedimiento para actualizar el inventario después de un movimiento
CREATE PROCEDURE ActualizarInventario
    @ID_Producto INT,
    @Cantidad INT,
    @TipoMovimiento NVARCHAR(50)
AS
BEGIN
    IF @TipoMovimiento = 'Entrada'
    BEGIN
        UPDATE Producto SET Cantidad = Cantidad + @Cantidad WHERE ID_Producto = @ID_Producto;
    END
    ELSE IF @TipoMovimiento = 'Salida' OR @TipoMovimiento = 'Ajuste'
    BEGIN
        UPDATE Producto SET Cantidad = Cantidad - @Cantidad WHERE ID_Producto = @ID_Producto;
    END
END;
GO

-- Procedimiento para registrar un movimiento de inventario
CREATE PROCEDURE RegistrarMovimientoInventario
    @ID_Producto INT,
    @TipoMovimiento NVARCHAR(50),
    @Cantidad INT,
    @ID_Usuario INT,
    @Motivo NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO MovimientoInventario (ID_Producto, FechaMovimiento, TipoMovimiento, Cantidad, ID_Usuario, Motivo)
    VALUES (@ID_Producto, GETDATE(), @TipoMovimiento, @Cantidad, @ID_Usuario, @Motivo);

    -- Llamar al procedimiento para actualizar el inventario
    EXEC ActualizarInventario @ID_Producto, @Cantidad, @TipoMovimiento;
END;
GO

-- Tabla: ReportesGenerales
CREATE TABLE ReportesGenerales (
    ID_Reporte INT PRIMARY KEY IDENTITY,
    ID_Producto INT NOT NULL,
    FechaGeneracion DATETIME NOT NULL DEFAULT GETDATE(),
    Descripcion NVARCHAR(255),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto) ON DELETE CASCADE
);
GO
