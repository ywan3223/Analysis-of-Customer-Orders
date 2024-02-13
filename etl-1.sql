

USE CO
GO

create table dbo.DimCustomers (
  customerkey     integer not null,
  email_address   NVARCHAR(255) NULL,
  full_name       NVARCHAR(255) NULL,
  StartDate         DATE NOT NULL,
  EndDate           DATE NULL,
  CONSTRAINT PK_DimCustomers PRIMARY KEY CLUSTERED (customerkey)
  );
 
GO
create table dbo.DimStores (
  storekey          integer not null,
  store_name        NVARCHAR(255) NOT NULL,
  web_address       NVARCHAR(100) NULL,
  physical_address  NVARCHAR(512) NULL,
  latitude          NUMERIC(10,7),
  longitude         NUMERIC(10,7),
  logo_mime_type    NVARCHAR(512),
  logo_filename     NVARCHAR(512),
  logo_charset      NVARCHAR(512),
  CONSTRAINT PK_DimStores PRIMARY KEY CLUSTERED (storekey)
  );

GO
create table dbo.DimProducts (
  productkey         integer not null,
  product_name       NVARCHAR(255) not null,
  unit_price         NUMERIC(10,2),
  product_details    NVARCHAR(512),
  image_mime_type    NVARCHAR(512),
  image_filename     NVARCHAR(512),
  image_charset      NVARCHAR(512),
  StartDate         DATE NOT NULL,
	EndDate           DATE NULL,
  CONSTRAINT PK_DimProducts PRIMARY KEY CLUSTERED (productkey)
  );

GO
create table dbo.DimOrderStatus (
  orderstatuskey	integer IDENTITY not null,
  order_status    NVARCHAR(10) not null,
  CONSTRAINT PK_DimOrderStatus PRIMARY KEY CLUSTERED (orderstatuskey)
  );

GO
create table dbo.DimShipments (
  shipmentkey          integer not null,
  delivery_address     NVARCHAR(512) not null,
  shipment_status      NVARCHAR(255) not null,
  CONSTRAINT PK_DimShipments PRIMARY KEY CLUSTERED (shipmentkey)
  );

 GO
 CREATE TABLE dbo.DimDate(
	datekey INT NOT NULL,
	date_value DATE NOT NULL,
	c_year SMALLINT NOT NULL,
	c_qtr TINYINT NOT NULL,
	c_month TINYINT NOT NULL,
	day TINYINT NOT NULL,
	start_of_month DATE NOT NULL,
	end_of_month DATE NOT NULL,
	month_name VARCHAR(9) NOT NULL,
	day_of_week_name VARCHAR(9) NOT NULL,
  CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED ( datekey )
);

Go
create table dbo.FactOrders (
  customerkey     integer not null,
  storekey        integer not null,
  productkey      integer not null,
  shipmentkey     integer not null,
  datekey         integer not null,
  orderstatuskey  integer not null,
  unit_price      NUMERIC(10,2) not null,
  quantity        integer not null,
  --HERE WILL INFLUENCE THE DATA DISPLAY.
  CONSTRAINT FK_FactOrders_DimCustomers FOREIGN KEY(customerkey) REFERENCES dbo.DimCustomers (customerkey),
  CONSTRAINT FK_FactOrders_DimStores FOREIGN KEY(storekey) REFERENCES dbo.DimStores (storekey),
  CONSTRAINT FK_FactOrders_DimProducts FOREIGN KEY(productkey) REFERENCES dbo.DimProducts (productkey),
  CONSTRAINT FK_FactOrders_DimShipments FOREIGN KEY(shipmentkey) REFERENCES dbo.DimShipments (shipmentkey),
  CONSTRAINT FK_FactOrders_DimDate FOREIGN KEY(datekey) REFERENCES dbo.DimDate (datekey),
  CONSTRAINT FK_FactOrders_DimOrderStatus FOREIGN KEY(orderstatuskey) REFERENCES dbo.DimOrderStatus (orderstatuskey)
  )
;

GO
CREATE INDEX IX_DimCustomers_full_name ON dbo.DimCustomers(full_name);
CREATE INDEX IX_Dimstores_store_name ON dbo.Dimstores(store_name);
CREATE INDEX IX_DimProducts_product_name ON dbo.DimProducts(product_name);
CREATE INDEX IX_Dimshipments_delivery_address ON dbo.Dimshipments(delivery_address);
--Factorders index
CREATE INDEX IX_FactOrders_storekey ON dbo.FactOrders(storekey);
CREATE INDEX IX_FactOrders_customerkey ON dbo.FactOrders(customerkey);
CREATE INDEX IX_FactOrders_productkey ON dbo.FactOrders(productkey);
CREATE INDEX IX_FactOrders_shipmentkey ON dbo.FactOrders(shipmentkey);

GO
CREATE PROCEDURE dbo.DimDate_Load 
    @DateValue DATE
AS
BEGIN
    INSERT INTO dbo.DimDate
    SELECT CAST( YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),
           @DateValue,
           YEAR(@DateValue),
           DATEPART(qq,@DateValue),
           MONTH(@DateValue),
           DAY(@DateValue),
           DATEADD(DAY,1,EOMONTH(@DateValue,-1)),
           EOMONTH(@DateValue),
           DATENAME(mm,@DateValue),
           DATENAME(dw,@DateValue);
END
GO

CREATE PROCEDURE dbo.DimDate_YearLoad 
    @StartYear NVARCHAR(4),
	@EndYear NVARCHAR(4)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @StartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @StartYear), 0);
	DECLARE @EndDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @EndYear) + 1, 0);

    WHILE (@StartDate < @EndDate)
		BEGIN
		EXEC dbo.DimDate_Load @DateValue = @StartDate;
		set @StartDate = DATEADD(day, 1, @StartDate);
		END;
END
GO
EXEC dbo.DimDate_YearLoad @StartYear = '2018', @EndYear = '2019';
GO


----------stage--------
USE CO
GO
create table dbo.Customers_stage (
  email_address   NVARCHAR(255) NULL,
  full_name       NVARCHAR(255) NULL,
  );
 
GO
create table dbo.Stores_stage (
  store_name        NVARCHAR(255) NOT NULL,
  web_address       NVARCHAR(100) NULL,
  physical_address  NVARCHAR(512) NULL,
  latitude          NUMERIC(10,7),
  longitude         NUMERIC(10,7),
  logo_mime_type    NVARCHAR(512),
  logo_filename     NVARCHAR(512),
  logo_charset      NVARCHAR(512),
  );

GO
create table dbo.Products_stage (
  product_name       NVARCHAR(255) not null,
  unit_price         NUMERIC(10,2),
  product_details    NVARCHAR(512),
  image_mime_type    NVARCHAR(512),
  image_filename     NVARCHAR(512),
  image_charset      NVARCHAR(512),
  );

 
 --------extract------
 /*Create Customers Extract/Store Procedure */
GO
CREATE PROCEDURE dbo.Customers_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Customers_stage;

    INSERT INTO dbo.Customers_stage ( 
        email_address,
  		full_name
        )
    SELECT c.email_address,
  		   c.full_name 
    FROM CO.dbo.customers c

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END
END
GO
--END OF PROCEDURE Customers_Extract

--Execute and show the results 
--EXECUTE dbo.Customers_Extract;
--SELECT * FROM dbo.Customers_stage;


GO
CREATE PROCEDURE dbo.Stores_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Stores_stage;

    INSERT INTO dbo.Stores_stage (
        store_name,
   		web_address,
  		physical_address,
  		latitude,
  		longitude,
  		logo_mime_type,
  		logo_filename,
  		logo_charset
        )
    SELECT s.store_name,
   		s.web_address,
  		s.physical_address,
  		s.latitude,
  		s.longitude,
  		s.logo_mime_type,
  		s.logo_filename,
  		s.logo_charset
    FROM CO.dbo.stores s
    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END
END
GO
--END OF PROCEDURE Customers_Extract

--Execute and show the results 
--EXECUTE dbo.Stores_Extract;
--SELECT * FROM dbo.Stores_stage;


GO
CREATE PROCEDURE dbo.Products_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Products_stage;

    INSERT INTO dbo.Products_stage ( 
        product_name,
  		unit_price,
  		product_details,
  		image_mime_type,
  		image_filename,
  		image_charset
        )
    SELECT p.product_name,
  		   p.unit_price,
  		   p.product_details,
  		   p.image_mime_type,
  		   p.image_filename,
  		   p.image_charset
    FROM CO.dbo.products p

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END
END
GO
--END OF PROCEDURE Customers_Extract

--Execute and show the results 
--EXECUTE dbo.Products_Extract;
--SELECT * FROM dbo.Products_stage;

----preload-----
create table dbo.Customers_Preload (
  customerkey     INT NOT NULL,
  email_address   NVARCHAR(255) NULL,
  full_name       NVARCHAR(255) NULL,
  StartDate       DATE NOT NULL,
  EndDate         DATE NULL,
  CONSTRAINT PK_Customers_Preload PRIMARY KEY CLUSTERED (customerkey)
  );
 
 create table dbo.Stores_Preload (
  storekey          INT NOT NULL,
  store_name        NVARCHAR(255) NOT NULL,
  web_address       NVARCHAR(100) NULL,
  physical_address  NVARCHAR(512) NULL,
  latitude          NUMERIC(10,7),
  longitude         NUMERIC(10,7),
  logo_mime_type    NVARCHAR(512),
  logo_filename     NVARCHAR(512),
  logo_charset      NVARCHAR(512),
  CONSTRAINT PK_Stores_Preload PRIMARY KEY CLUSTERED (storekey)
  );

create table dbo.Products_Preload (
  productkey         integer not null,
  product_name       NVARCHAR(255) not null,
  unit_price         NUMERIC(10,2),
  product_details    NVARCHAR(512),
  image_mime_type    NVARCHAR(512),
  image_filename     NVARCHAR(512),
  image_charset      NVARCHAR(512),
  StartDate         DATE NOT NULL,
  EndDate           DATE NULL,
  CONSTRAINT PK_Products_Preload PRIMARY KEY CLUSTERED (productkey)
  );

GO
/* CREATING SEQUENCE TO MAINTAIN THE SURROGATE KEY */
CREATE SEQUENCE dbo.customerkey START WITH 1;
CREATE SEQUENCE dbo.storekey START WITH 1;
CREATE SEQUENCE dbo.productkey START WITH 1;

/*CREATE SEQUENCE dbo.shipmentkey START WITH 1;
CREATE SEQUENCE dbo.datekey START WITH 1;
CREATE SEQUENCE dbo.orderstatuskey START WITH 1;*/

---------transform-------
/* Create Customers Transform */
GO
CREATE PROCEDURE dbo.Customers_Transform    -- Type 2 SCD
	@StartDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
	
    TRUNCATE TABLE dbo.Customers_Preload;

    --DECLARE @StartDate DATE = GETDATE();
	--DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
    DECLARE @EndDate DATE = DATEADD(dd,-1,@StartDate);

    BEGIN TRANSACTION;

	/*ADD UPDATED RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT NEXT VALUE FOR dbo.customerkey AS customerkey,
           stg.email_address,
           stg.full_name,
           @StartDate,
           NULL
    FROM dbo.Customers_stage stg
    JOIN dbo.DimCustomers cu
        ON stg.full_name = cu.full_name
        --AND cu.EndDate IS NULL
    WHERE stg.email_address  <> cu.email_address
          OR stg.full_name <> cu.full_name;

	/*ADD EXISTING RECORDS, AND EXPIRE AS NECESSARY*/
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.customerkey,
           cu.email_address,
           cu.full_name,
           cu.StartDate,
           CASE 
               WHEN pl.full_name IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimCustomers cu
    LEFT JOIN dbo.Customers_Preload pl
        ON pl.full_name = cu.full_name
        AND cu.EndDate IS NULL;
    
	/*CREATE NEW RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT NEXT VALUE FOR dbo.customerkey AS customerkey,
           stg.email_address,
           stg.full_name,
           @StartDate,
           NULL
    FROM dbo.Customers_stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimCustomers cu WHERE stg.full_name = cu.full_name );

	/*EXPRIRE MISSING RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.customerkey,
           cu.email_address,
           cu.full_name,
           cu.StartDate,
           @EndDate
    FROM dbo.DimCustomers cu
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.Customers_stage stg WHERE stg.full_name = cu.full_name )
          AND cu.EndDate IS NULL;
	
    COMMIT TRANSACTION;
END; 
GO
--END OF PROCEDURE Customers_Transform


CREATE PROCEDURE dbo.Stores_Transform --Salespeople is SCD 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
   
    TRUNCATE TABLE dbo.Stores_Preload;

    BEGIN TRANSACTION;
 
    /*CREATE NEW RECORD*/
    INSERT INTO dbo.Stores_Preload
    SELECT NEXT VALUE FOR dbo.storekey AS storekey,
         ss.store_name,
         ss.web_address,
         ss.physical_address,
         ss.latitude,
         ss.longitude ,
         ss.logo_mime_type,
         ss.logo_filename,
         ss.logo_charset
    FROM dbo.Stores_stage ss
    WHERE NOT EXISTS ( SELECT 1 
                       FROM dbo.DimStores ds
                       WHERE ss.store_name = ds.store_name
                        AND ss.web_address = ds.web_address 
						AND ss.physical_address = ds.physical_address 
						AND ss.latitude = ds.latitude 
						AND ss.longitude = ds.longitude 
						AND ss.logo_mime_type = ds.logo_mime_type 
						AND ss.logo_filename = ds.logo_filename 
						AND ss.logo_charset = ds.logo_charset);
           
    /*UPDATE EXITING RECORDS*/
    INSERT INTO dbo.Stores_Preload
    SELECT  ds.storekey,
    		ss.store_name,
         	ss.web_address,
         	ss.physical_address,
         	ss.latitude,
         	ss.longitude ,
         	ss.logo_mime_type,
         	ss.logo_filename,
         	ss.logo_charset
    FROM dbo.Stores_stage ss
    JOIN dbo.DimStores ds
        ON ss.store_name = ds.store_name
        AND ss.web_address = ds.web_address 
		AND ss.physical_address = ds.physical_address 
		AND ss.latitude = ds.latitude 
		AND ss.longitude = ds.longitude 
		AND ss.logo_mime_type = ds.logo_mime_type 
		AND ss.logo_filename = ds.logo_filename 
		AND ss.logo_charset = ds.logo_charset;
       
        COMMIT TRANSACTION;
END; 
GO
--END OF PROCEDURE SalesPerson_Transform


CREATE PROCEDURE dbo.Products_Transform    -- Type 2 SCD
@StartDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    TRUNCATE TABLE dbo.Products_Preload;

    DECLARE @EndDate DATE = DATEADD(dd,-1,@StartDate);

    BEGIN TRANSACTION;

	/*ADD UPDATED RECORDS*/
    INSERT INTO dbo.Products_Preload 
    SELECT NEXT VALUE FOR dbo.productkey AS productkey,  
    	   stg.product_name,
  		   stg.unit_price,
  		   stg.product_details,
 		   stg.image_mime_type,
		   stg.image_filename,
 		   stg.image_charset,
           @StartDate,
           NULL
    FROM dbo.Products_stage stg
    JOIN dbo.DimProducts dp
        ON stg.product_name = dp.product_name
        AND dp.EndDate IS NULL
    WHERE stg.unit_price <> dp.unit_price
          OR stg.product_details <> dp.product_details
          OR stg.image_mime_type <> dp.image_mime_type
          OR stg.image_filename <> dp.image_filename
          OR stg.image_charset <> dp.image_charset;

 /*ADD EXISTING RECORDS, AND EXPIRE AS NECESSARY*/
    INSERT INTO dbo.Products_Preload 
    SELECT dp.productkey,
    	   dp.product_name,
  		   dp.unit_price,
  		   dp.product_details,
 		   dp.image_mime_type,
		   dp.image_filename,
 		   dp.image_charset,
           dp.StartDate,
           CASE 
               WHEN pp.product_name IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimProducts dp
    LEFT JOIN dbo.Products_Preload pp    
        ON pp.product_name = dp.product_name
        AND dp.EndDate IS NULL;
    
 /*CREATE NEW RECORDS*/
    INSERT INTO dbo.Products_Preload 
    SELECT NEXT VALUE FOR dbo.ProductKey AS ProductKey,
           stg.product_name,
  		   stg.unit_price,
  		   stg.product_details,
 		   stg.image_mime_type,
		   stg.image_filename,
 		   stg.image_charset,
           @StartDate,
           NULL
    FROM dbo.Products_stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimProducts dp WHERE stg.product_name = dp.product_name );

	/*EXPRIRE MISSING RECORDS*/
	INSERT INTO dbo.Products_Preload 
    SELECT dp.productkey,
    	   dp.product_name,
  		   dp.unit_price,
  		   dp.product_details,
 		   dp.image_mime_type,
		   dp.image_filename,
 		   dp.image_charset,
           dp.StartDate,
           @EndDate
	FROM dbo.DimProducts dp
	WHERE NOT EXISTS ( SELECT 1 FROM dbo.Products_stage stg WHERE stg.product_name = dp.product_name )
          AND dp.EndDate IS NULL;
  
    COMMIT TRANSACTION;
END;
GO
--END OF PROCEDURE Products_Transform


/* Create Cities Load Stored Procedures */
GO
CREATE PROCEDURE dbo.Customers_Load
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE cu
    FROM dbo.DimCustomers cu
    JOIN dbo.Customers_Preload pl
        ON cu.customerkey = pl.customerkey;

    INSERT INTO dbo.DimCustomers
    SELECT * 
    FROM dbo.Customers_Preload;

    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE dbo.Stores_Load
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE ds
    FROM dbo.DimStores ds
    JOIN dbo.Stores_Preload pl
        ON ds.storekey = pl.storekey;

    INSERT INTO dbo.DimStores
    SELECT * 
    FROM dbo.Stores_Preload;

    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE dbo.Products_Load
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE dp
    FROM dbo.DimProducts dp
    JOIN dbo.Products_Preload pl
        ON dp.productkey = pl.productkey ;

    INSERT INTO dbo.DimProducts
    SELECT * 
    FROM dbo.Products_Preload;

    COMMIT TRANSACTION;
END;


/* execute */
GO
DECLARE @Date DATE;
DECLARE @StartDate DATE = '2013-01-01';
DECLARE @EndDate DATE = '2013-01-04';

WHILE @StartDate <= @EndDate
BEGIN
    SET @Date = @StartDate;

    --Execute Extract
    EXEC dbo.Customers_Extract;
    EXEC dbo.Stores_Extract;
    EXEC dbo.Products_Extract;

    --Execute Transform
    EXEC dbo.Customers_Transform @Date;
    EXEC dbo.Stores_Transform;
    EXEC dbo.Products_Transform @Date;

    --Execute Load
    EXEC dbo.Customers_Load;
    EXEC dbo.Stores_Load;
    EXEC dbo.Products_Load;
 
    -- Increment the date
    SET @StartDate = DATEADD(day, 1, @StartDate);
END;
GO
