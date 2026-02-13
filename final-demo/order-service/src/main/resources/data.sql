-- Pre-load 10 products (matching Snowflake workshop data)
MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(1, 'Wireless Mouse', 'Electronics', 'TechBrand', 29.99, 'Ergonomic wireless mouse with USB receiver', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(2, 'Mechanical Keyboard', 'Electronics', 'KeyMaster', 79.99, 'RGB mechanical keyboard with Cherry MX switches', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(3, 'USB-C Hub', 'Accessories', 'ConnectPro', 49.99, '7-in-1 USB-C hub with HDMI and ethernet', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(4, 'Monitor Stand', 'Furniture', 'DeskCraft', 39.99, 'Adjustable monitor stand with storage drawer', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(5, 'Webcam HD', 'Electronics', 'VisionTech', 59.99, '1080p HD webcam with built-in microphone', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(6, 'Laptop Sleeve', 'Accessories', 'CarryAll', 24.99, 'Neoprene laptop sleeve for 15-inch laptops', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(7, 'Desk Lamp', 'Furniture', 'LightWorks', 34.99, 'LED desk lamp with adjustable brightness', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(8, 'Wireless Charger', 'Electronics', 'ChargeTech', 19.99, 'Qi wireless charging pad for smartphones', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(9, 'Noise Cancelling Headphones', 'Electronics', 'AudioMax', 149.99, 'Over-ear noise cancelling Bluetooth headphones', true);

MERGE INTO PRODUCT (ID, NAME, CATEGORY, BRAND, PRICE, DESCRIPTION, ACTIVE)
KEY (ID) VALUES
(10, 'Ergonomic Chair Cushion', 'Furniture', 'ComfortZone', 44.99, 'Memory foam seat cushion for office chairs', true);
