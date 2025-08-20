-- إنشاء جدول لتجميع قيم RFM
CREATE TABLE RFM_Segments AS
SELECT 
    CustomerID,
    MAX(InvoiceDate) AS LastPurchaseDate,
    JULIANDAY('2011-12-10') - JULIANDAY(MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    SUM(TotalAmount) AS Monetary
FROM OnlineRetail
GROUP BY CustomerID;

-- تقسيم العملاء حسب Recency
SELECT 
    CASE
        WHEN Recency <= 30 THEN 'Active'
        WHEN Recency BETWEEN 31 AND 90 THEN 'Warm'
        ELSE 'Lost'
    END AS Recency_Segment,
    COUNT(CustomerID) AS Num_Customers
FROM RFM_Segments
GROUP BY Recency_Segment;

-- تقسيم العملاء حسب Frequency
SELECT 
    CASE
        WHEN Frequency = 1 THEN 'One-time'
        WHEN Frequency BETWEEN 2 AND 5 THEN 'Low'
        WHEN Frequency BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'High'
    END AS Frequency_Segment,
    COUNT(CustomerID) AS Num_Customers
FROM RFM_Segments
GROUP BY Frequency_Segment;

-- تقسيم العملاء حسب Monetary
SELECT 
    CASE
        WHEN Monetary < 100 THEN 'Low Spenders'
        WHEN Monetary BETWEEN 100 AND 500 THEN 'Mid Spenders'
        ELSE 'High Spenders'
    END AS Monetary_Segment,
    COUNT(CustomerID) AS Num_Customers
FROM RFM_Segments
GROUP BY Monetary_Segment;

-- التحليل المزدوج: Recency × Monetary
SELECT 
    CASE
        WHEN Recency <= 30 THEN 'Active'
        WHEN Recency BETWEEN 31 AND 90 THEN 'Warm'
        ELSE 'Lost'
    END AS Recency_Segment,
    CASE
        WHEN Monetary < 100 THEN 'Low Spenders'
        WHEN Monetary BETWEEN 100 AND 500 THEN 'Mid Spenders'
        ELSE 'High Spenders'
    END AS Monetary_Segment,
    COUNT(CustomerID) AS Num_Customers
FROM RFM_Segments
GROUP BY Recency_Segment, Monetary_Segment;

-- التحليل المزدوج: Frequency × Monetary
SELECT 
    CASE
        WHEN Frequency = 1 THEN 'One-time'
        WHEN Frequency BETWEEN 2 AND 5 THEN 'Low'
        WHEN Frequency BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'High'
    END AS Frequency_Segment,
    CASE
        WHEN Monetary < 100 THEN 'Low Spenders'
        WHEN Monetary BETWEEN 100 AND 500 THEN 'Mid Spenders'
        ELSE 'High Spenders'
    END AS Monetary_Segment,
    COUNT(CustomerID) AS Num_Customers
FROM RFM_Segments
GROUP BY Frequency_Segment, Monetary_Segment;
