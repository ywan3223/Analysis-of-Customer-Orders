# Analysis of Customer Orders in Retail Application  

As the business bloom nowadays, the analysis of customer behavior becomes more and more important. By analysing the orders of customers, it will provide massive information for decision-makers. This project aims to harness these insights by creating a **database** and **data mart** within **SQL Server** to track custom orders and related information.   

By analyzing **custom order data**, the initiative seeks to enhance inventory management and production efficiency, increase customer satisfaction through precise order status tracking, and forecast future demand. The deliverables encompass the development and deployment of an **operational database** and **data mart**, automation of the **ETL process**(Extract, Transform, and Load) via **SSIS** (SQL Server Integration Services), and the construction of a multi-dimensional cube using **SSAS** (SQL Server Analysis Services).   

This endeavor represents a synthesis of technological innovation and strategic business analysis, designed to leverage data to inform decision-making and operational strategies, thereby fostering market competitiveness and customer engagement.  

## Database
Before starting, make sure to download the dataset from [Oracle Database](https://docs.oracle.com/en/database/oracle/oracle-database/21/comsc/introduction-to-sample-schemas.html#GUID-E1EE89C5-2D4E-4C74-835C-74F775BAE4A0 "悬停显示")  

## Operational Database
<img src="/image/ob.png" width = "250" height = "250" alt="cmo" />  

## Star Schema
<img src="/image/starschema.jpg" width = "350" height = "250" alt="cmo" />  

## ETL Model Diagram
### 1. T-SQL & Stored Procedures
**DimStores (SCD Type 1)**: Records in the dimension table are directly updated without retaining the historical changes when the source data changes. Such an approach finds its utility in scenarios like the updating of store-related information, where the current state of data holds precedence over its historical iterations.  

**DimProducts (SCD Type 2)**: This strategy facilitates the insertion of new records within the dimension table to maintain a ledger of historical changes, concurrently retaining older records. This methodology is instrumental in chronicling the evolution of product information over time, catering to use cases that necessitate the retention of historical data integrity.
<img src="/image/etl.png" width = "700" height = "200" alt="cmo" />  

### 2. SSIS Packages  
**DimCustomer (SCD Type 2)**: DimCustomer dimension delineates the utilization of SSIS for managing SCD Type 2 alterations, showcasing the efficacy of SSIS in orchestrating the nuanced management and tracking of data modifications.  

**DimShipment (SCD Type 1)**: DimShipment dimension illustrates the application of SSIS in managing SCD Type 1 modifications, highlighting the methodology of direct record updates without historical data preservation.  
<img src="/image/ssis.png" width = "700" height = "250" alt="cmo" />  

## SSAS
SSAS focused on utilizing **multi-dimensional analysis** to gain deeper insights into customer data, which included average pricing, pricing strategies, supplier performance, sales goal tracking, performance gap identification, areas for improvement, and **overall business goal monitoring**. The approach involved creating a data source view, defining dimension hierarchies and cube structure, establishing measures and measure groups, using dimensions for data analysis, defining **calculated measures and KPIs** for advanced analysis, and utilizing **MDX queries** for data retrieval and analysis. This comprehensive analysis contributed significantly to understanding and improving business operations.  


