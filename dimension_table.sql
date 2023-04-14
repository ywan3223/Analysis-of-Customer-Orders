
CREATE DATABASE Project_9017
GO

USE Project_9017
GO

create table dbo.Dimcustomers (
  customerkey     integer not null,
  email_address   NVARCHAR(255) NULL,
  full_name       NVARCHAR(255) NULL,
  CONSTRAINT PK_Dimcustomers PRIMARY KEY CLUSTERED (customerkey)
  );
 
GO
create table dbo.Dimstores (
  storekey          integer not null,
  store_name        NVARCHAR(255) NOT NULL,
  web_address       NVARCHAR(100) NULL,
  physical_address  NVARCHAR(512) NULL,
  latitude          decimal(10,7),
  longitude         decimal(10,7),
  logo_mime_type    NVARCHAR(512),
  logo_filename     NVARCHAR(512),
  logo_charset      NVARCHAR(512),
  logo_last_updated date,
  CONSTRAINT PK_Dimstores PRIMARY KEY CLUSTERED (storekey)
  );

GO
create table dbo.Dimproducts (
  productkey         integer not null,
  product_name       NVARCHAR(255) not null,
  unit_price         decimal(10,2),
  product_details    NVARCHAR(512),
  image_mime_type    NVARCHAR(512),
  image_filename     NVARCHAR(512),
  image_charset      NVARCHAR(512),
  image_last_updated date,
  CONSTRAINT PK_Dimproducts PRIMARY KEY CLUSTERED (productkey)
  );

GO
create table dbo.Dimshipments (
  shipmentkey          integer not null,
  delivery_address     NVARCHAR(512) not null,
  shipment_status      NVARCHAR(255) not null,
  CONSTRAINT PK_Dimshipments PRIMARY KEY CLUSTERED (shipmentkey)
  );

 GO
create table dbo.Diminventory (
  inventorykey          integer not null,
  product_inventory     integer not null,
  CONSTRAINT PK_Diminventory PRIMARY KEY CLUSTERED (inventorykey)
  );

 GO
create table FactOrders (
  customerkey     integer not null,
  storekey        integer not null,
  productkey      integer not null,
  shipmentkey     integer not null,
  inventorykey	  integer not null,
  order_datetime  timestamp not null,
  order_status    NVARCHAR(10) not null,
  unit_price      decimal(10,2) not null,
  quantity        integer not null,
  --HERE WILL INFLUENCE THE DATA DISPLAY.
  CONSTRAINT FK_FactOrders_Dimcustomers FOREIGN KEY(customerkey) REFERENCES dbo.Dimcustomers (customerkey),
  CONSTRAINT FK_FactOrders_Dimstores FOREIGN KEY(storekey) REFERENCES dbo.Dimstores (storekey),
  CONSTRAINT FK_FactOrders_Dimproducts FOREIGN KEY(productkey) REFERENCES dbo.DimProducts (productkey),
  CONSTRAINT FK_FactOrders_Dimshipments FOREIGN KEY(shipmentkey) REFERENCES dbo.Dimshipments (shipmentkey),
  CONSTRAINT FK_FactOrders_Diminventory FOREIGN KEY(inventorykey) REFERENCES dbo.Diminventory (inventorykey)
  )
;

GO
CREATE INDEX IX_DimCustomers_full_name ON dbo.DimCustomers(full_name);
CREATE INDEX IX_Dimstores_store_name ON dbo.Dimstores(store_name);
CREATE INDEX IX_DimProducts_product_name ON dbo.DimProducts(product_name);
CREATE INDEX IX_Dimshipments_delivery_address ON dbo.Dimshipments(delivery_address);
CREATE INDEX IX_Diminventory_product_inventory ON dbo.Diminventory(product_inventory);
--Factorders index
CREATE INDEX IX_FactOrders_storekey ON dbo.FactOrders(storekey);
CREATE INDEX IX_FactOrders_customerkey ON dbo.FactOrders(customerkey);
CREATE INDEX IX_FactOrders_productkey ON dbo.FactOrders(productkey);
CREATE INDEX IX_FactOrders_shipmentkey ON dbo.FactOrders(shipmentkey);
CREATE INDEX IX_FactOrders_inventorykey ON dbo.FactOrders(inventorykey);
