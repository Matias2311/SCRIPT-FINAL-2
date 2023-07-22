create database Marketplace;

use Marketplace;
create table comprador(

id_comprador INT PRIMARY KEY,-- AUTO_INCREMENT,

telefono VARCHAR(32),

nombre_completo VARCHAR (32),

email VARCHAR(32),

estado_de_linea VARCHAR(32),

reputacion VARCHAR (32)

);

select *from comprador;

create table vendedor(

id_vendedor INT PRIMARY KEY,-- AUTO_INCREMENT,

telefono VARCHAR(32),

nombre_completo VARCHAR (32),

email VARCHAR(32),

estado_de_linea VARCHAR(32),

reputacion VARCHAR (32)

);

create table producto(

nombre VARCHAR(100),

id_producto INT PRIMARY KEY,-- AUTO_INCREMENT,
estado VARCHAR(32),

descripcion VARCHAR(100),

categoria VARCHAR(32)

);

create table orden(

id_orden INT PRIMARY KEY,

precio INT,

cantidad FLOAT,

id_comprador INT,

id_vendedor INT,

id_producto INT,

FOREIGN KEY(id_comprador)

REFERENCES comprador(id_comprador),

FOREIGN KEY(id_vendedor)

REFERENCES vendedor(id_vendedor),

FOREIGN KEY (id_producto)

REFERENCES producto(id_producto)

);

INSERT INTO comprador(id_comprador,telefono,nombre_completo,email,estado_de_linea,reputacion) VALUES

(1,'1145678901','Sergio Oscar Godoy', 'SergioGodoy14@gmail.com','activo cada seis horas','buena'),

(2,'1185377955','Javier Nicolas Ramirez', 'JaviiiR230@gmail.com','activo cada tres horas','muy buena'),

(3,'1191882340','Manuela Sofia Fernandez', 'SofiaFer02@gmail.com','activo cada doce horas','neutral');

INSERT INTO vendedor(id_vendedor,telefono,nombre_completo,email,estado_de_linea,reputacion) VALUES

(1,'1190872344','Rocio Sanchez', 'RocioSanchezz@gmail.com','activo cada dos horas','excelente'),

(2,'1147659102','Braian Franco Juarez', 'Juarez9970@gmail.com','activo cada dos dias','mala'),

(3,'1150289423','Florencia Yessica Lopez', 'FlorYesii@gmail.com','activo cada tres dias','buena');

INSERT INTO producto(nombre,id_producto,estado,descripcion,categoria) VALUES

('Shampoo anticaspa 3en1',1,'nuevo','Shampoo de reconocida marca para la higiene masculina','Belleza y cuidados'),

('Mueble usado de pino',2,'poco uso','mueble de pino impecable,lo estoy vendiendo por mudanza','armarios y muebles'),

('Guitara criolla a estrenar',3,'nuevo','Guitarra criolla nueva de la marca Pirulo incluye tres puas','Instrumentos');

INSERT INTO orden(id_orden,precio,cantidad,id_comprador,id_vendedor,id_producto) VALUES

(1,'1000','1',1,1,1),

(2,'9000','1',2,2,2),

(3,'12000','1',3,3,3);


CREATE VIEW producto_mas_vendido AS
SELECT p.id_producto, p.nombre AS nombre_producto, SUM(o.cantidad) AS total_vendido
FROM producto p
INNER JOIN orden o ON p.id_producto = o.id_producto
GROUP BY p.id_producto, p.nombre
ORDER BY total_vendido DESC
LIMIT 1;


CREATE VIEW detalles_ventas AS
SELECT p.id_producto, p.nombre AS nombre_producto,
       v.id_vendedor, v.nombre_completo AS nombre_vendedor,
       c.id_comprador, c.nombre_completo AS nombre_comprador
FROM producto p
INNER JOIN orden o ON p.id_producto = o.id_producto
INNER JOIN vendedor v ON o.id_vendedor = v.id_vendedor
INNER JOIN comprador c ON o.id_comprador = c.id_comprador;

CREATE VIEW compras_por_categoria AS
SELECT p.categoria, SUM(o.cantidad) AS total_compras
FROM producto p
INNER JOIN orden o ON p.id_producto = o.id_producto
GROUP BY p.categoria;


CREATE VIEW comprador_con_mas_compras AS
SELECT c.id_comprador, c.nombre_completo AS nombre_comprador, COUNT(o.id_orden) AS total_compras
FROM comprador c
INNER JOIN orden o ON c.id_comprador = o.id_comprador
GROUP BY c.id_comprador, c.nombre_completo
ORDER BY total_compras DESC
LIMIT 1;


CREATE VIEW vendedor_con_mas_ventas AS
SELECT v.id_vendedor, v.nombre_completo AS nombre_vendedor, COUNT(o.id_orden) AS total_ventas
FROM vendedor v
INNER JOIN orden o ON v.id_vendedor = o.id_vendedor
GROUP BY v.id_vendedor, v.nombre_completo
ORDER BY total_ventas DESC
LIMIT 1;



DELIMITER //

CREATE FUNCTION total_de_usuarios()

RETURNS INT

DETERMINISTIC

BEGIN

DECLARE total_compradores INT;

DECLARE total_vendedores INT;

SELECT COUNT(*) INTO total_compradores FROM comprador;

SELECT COUNT(*) INTO total_vendedores FROM vendedor;

RETURN total_compradores + total_vendedores;

END//

DELIMITER ;

DELIMITER //

CREATE FUNCTION producto_mas_vendido_por_vendedor(vendedor_id INT)

RETURNS VARCHAR(100)

DETERMINISTIC

BEGIN

 DECLARE producto_nombre VARCHAR(100);

 SELECT p.nombre INTO producto_nombre

 FROM producto p

 INNER JOIN (

  SELECT id_producto, SUM(cantidad) as total_vendido

  FROM orden

  WHERE id_vendedor = vendedor_id

  GROUP BY id_producto

  ORDER BY total_vendido DESC

  LIMIT 1

 ) o ON p.id_producto = o.id_producto;

 RETURN producto_nombre;

END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE total_usuarios()
BEGIN
    DECLARE total_comprador INT;
    DECLARE total_vendedor INT;
    
    SELECT COUNT(*) INTO total_comprador FROM comprador;
    SELECT COUNT(*) INTO total_vendedor FROM vendedor;
    
    SELECT total_comprador + total_vendedor AS total_usuarios;
END //

DELIMITER ;

DELIMITER //


CREATE PROCEDURE OrdenarProductosPorFacturacion(IN orden_ordenamiento VARCHAR(10))
BEGIN
    SET @query = CONCAT('SELECT p.*, (o.cantidad * o.precio) AS facturacion 
                        FROM producto p
                        INNER JOIN orden o ON p.id_producto = o.id_producto 
                        ORDER BY facturacion ', orden_ordenamiento, ';');
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER actualiza_reputacion_vendedor
AFTER INSERT ON orden
FOR EACH ROW
BEGIN
  DECLARE total_facturacion INT;
  
  SELECT SUM(precio * cantidad) INTO total_facturacion
  FROM orden
  WHERE id_vendedor = NEW.id_vendedor;
  
  UPDATE vendedor
  SET reputacion =
    CASE
      WHEN total_facturacion > 10000 THEN 'muy buena'
      WHEN total_facturacion > 5000 THEN 'buena'
      ELSE 'regular'
    END
  WHERE id_vendedor = NEW.id_vendedor;
END //

DELIMITER ;


DELIMITER //

CREATE TRIGGER verificar_stock_antes_de_ordenar
AFTER INSERT ON orden
FOR EACH ROW
BEGIN
  DECLARE stock_actual FLOAT;
  
  SELECT cantidad INTO stock_actual FROM producto WHERE id_producto = NEW.id_producto;
  
  IF stock_actual < NEW.cantidad THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No hay suficiente stock disponible';
  ELSE
    UPDATE producto SET cantidad = cantidad - NEW.cantidad WHERE id_producto = NEW.id_producto;
  END IF;
END //

DELIMITER ;





