USE [AdventureWorks2017]
GO

/*------------------------------------------------------------------------------------
Purpose: DELETE data

-- delete data
-- truncate
-- delete vs truncate
-- output rows
-- transactions
-- batch deletions
-- DELETE with OUTPUT

---------------------------------------------------------------------------------------*/

/* DELETE 
-------------------------------------*/
SELECT *
FROM dbo.SalesAssistant;

/* delete where there are no sales from last year 
-- first specify the table targeted for deletion
-- the join creates a table with the lookup information
---------------------------------------------------------*/
DELETE ss
FROM Sales.vSalesPerson sp
  INNER JOIN dbo.SalesAssistant ss
  ON sp.BusinessEntityID = ss.StaffID
WHERE sp.SalesLastYear = 0;

/* Could also use a CTE
-----------------------------------------------*/

WITH cteSalesPerson
  AS
  (
    SELECT BusinessEntityID
    FROM Sales.vSalesPerson
    WHERE SalesLastYear = 0 
  )
DELETE ss
FROM cteSalesPerson sp
  INNER JOIN dbo.SalesAssistant ss
  ON sp.BusinessEntityID = ss.StaffID;

/* Could also reference the CTE in a subquery 
------------------------------------------------*/

WITH cteSalesPerson
  AS
  (
    SELECT BusinessEntityID
    FROM Sales.vSalesPerson
    WHERE SalesLastYear = 0 
  )
DELETE dbo.SalesAssistant
WHERE StaffID IN 
  (SELECT* FROM cteSalesPerson);


/* DELETE vs TRUNCATE 

-- TRUNCATE reseeds identity values, whereas DELETE doesn't. 
-- TRUNCATE removes all records and doesn't fire triggers. 
-- TRUNCATE is faster compared to DELETE as it makes less use of the transaction log.

-- DELETE 
-- fully logged, therefore large deletes are time consuming and impact the transaction log
-- use predicates
-- split into blocks e.g. TOP ... while 1=1 BEGIN ....<DELETE query> ... END, use @@Rowcount to check rows deleted
-- could also use a cursor
-- when deleting based on a join, the second FROM clause is mandatory, (filter predicate)
-----------------------------*/

/* OUTPUT deleted data 
------------------------*/

DECLARE @Output table
(
  StaffID INT,
  FirstName NVARCHAR(50),
  LastName NVARCHAR(50),
  CountryRegion NVARCHAR(50)
);
DELETE ss
OUTPUT DELETED.* INTO @Output
FROM Sales.vSalesPerson sp
  INNER JOIN [dbo].[SalesAssistant] ss
  ON sp.BusinessEntityID = ss.StaffID
WHERE sp.SalesLastYear = 0;
SELECT * FROM @output;

RETURN;

/* DELETE by batch in a transaction

-- Delete in batches of 100,000 rows 
-- Each batch is in its own transaction
-- So if the batch stops, previous batches will have been committed
-- add CHECKPOINT or BACKUP LOG options to minimise transaction log impacts

---------------------------------------*/

SET NOCOUNT ON;
 
DECLARE @row INT;
 
SET @row = 1;
 
WHILE @row > 0
BEGIN
  BEGIN TRANSACTION;
 
  DELETE TOP (100000) 
   -- dbo.SalesOrderDetailHeader
    WHERE ProductID IN (712, 870, 873);
 
  SET @row = @@ROWCOUNT;
 
  COMMIT TRANSACTION;

END



---------------------------------------------------------------------
-- Deleting data
---------------------------------------------------------------------

-- sample data
DROP TABLE IF EXISTS Sales.MyOrderDetails, Sales.MyOrders, Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;
ALTER TABLE Sales.MyCustomers
  ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;
ALTER TABLE Sales.MyOrderDetails
  ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);

-- DELETE statement
DELETE FROM Sales.MyOrderDetails
WHERE productid = 11;

/*
DELETE FROM dbo.MyTable WHERE CURRENT OF MyCursor;
*/

-- delete in chuncks
WHILE 1 = 1
BEGIN
  DELETE TOP (1000) FROM Sales.MyOrderDetails
  WHERE productid = 12;

  IF @@rowcount < 1000 BREAK;
END

-- TRUNCATE statement
TRUNCATE TABLE Sales.MyOrderDetails;

-- With partitions
TRUNCATE TABLE MyTable WITH ( PARTITIONS(1, 2, 11 TO 20) );

-- DELETE based on a join
DELETE FROM O
FROM Sales.MyOrders AS O
  INNER JOIN Sales.MyCustomers AS C
    ON O.custid = C.custid
WHERE C.country = N'USA';

-- cleanup
DROP TABLE IF EXISTS Sales.MyOrderDetails, Sales.MyOrders, Sales.MyCustomers;

---------------------------------------------------------------------
-- DELETE with OUTPUT
---------------------------------------------------------------------

DELETE FROM Sales.MyOrders
  OUTPUT deleted.orderid
WHERE empid = 1;

