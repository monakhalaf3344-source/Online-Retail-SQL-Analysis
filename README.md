---------------------------------------------------------
-- مشروع SQL لتحليل بيانات المبيعات Retail 2010-2011
-- إعداد وتنفيذ: [اسمك]
-- الهدف: تنظيف البيانات + تحليل استكشافي (EDA) + RFM Analysis
---------------------------------------------------------

---------------------------------------------------------
-- 1. تنظيف البيانات (Data Cleaning)
---------------------------------------------------------

-- إنشاء جدول جديد بدون التكرارات
CREATE TABLE retail_clean AS
SELECT DISTINCT *
FROM retail_2010_2011;

-- التأكد من عدد السجلات بعد التنظيف
SELECT COUNT(*) FROM retail_clean;

---------------------------------------------------------
-- 2. تحليل استكشافي (EDA)
---------------------------------------------------------

-- إجمالي الإيرادات
SELECT SUM(Quantity * UnitPrice) AS Total_Revenue
FROM retail_clean;

-- الإيرادات حسب الدولة
SELECT Country, SUM(Quantity * UnitPrice) AS Total_Revenue
FROM retail_clean
GROUP BY Country
ORDER BY Total_Revenue DESC;

-- عدد العملاء الفريدين
SELECT COUNT(DISTINCT "Customer ID") AS Unique_Customers
FROM retail_clean;

-- متوسط الإيراد لكل عميل
SELECT (SUM(Quantity*UnitPrice) * 1.0) / COUNT(DISTINCT "Customer ID") AS Avg_Revenue_Per_Customer
FROM retail_clean;

-- أكثر 10 منتجات مبيعًا بالكمية
SELECT StockCode, Description, SUM(Quantity) AS Qty_Sold
FROM retail_clean
GROUP BY StockCode, Description
ORDER BY Qty_Sold DESC
LIMIT 10;

-- أكثر 10 منتجات مساهمة في الإيراد
SELECT StockCode, Description, SUM(Quantity*UnitPrice) AS Revenue,
       ROUND(100.0 * SUM(Quantity*UnitPrice) / (SELECT SUM(Quantity*UnitPrice) FROM retail_clean),2) AS SharePct
FROM retail_clean
GROUP BY StockCode, Description
ORDER BY Revenue DESC
LIMIT 10;

-- عدد المنتجات البطيئة (Slow moving SKUs)
SELECT COUNT(DISTINCT StockCode) AS Num_Slow_SKUs
FROM retail_clean
WHERE StockCode NOT IN (
    SELECT StockCode FROM retail_clean
    GROUP BY StockCode HAVING SUM(Quantity) > 100
);

-- الإيراد شهريًا
SELECT strftime('%Y-%m', InvoiceDate) AS ym,
       SUM(Quantity*UnitPrice) AS Revenue
FROM retail_clean
GROUP BY ym
ORDER BY ym;

-- الإيراد حسب يوم الأسبوع
SELECT strftime('%w', InvoiceDate) AS DayOfWeek,
       SUM(Quantity*UnitPrice) AS Revenue
FROM retail_clean
GROUP BY DayOfWeek;

-- الإيراد حسب الساعة
SELECT strftime('%H', InvoiceDate) AS Hour,
       SUM(Quantity*UnitPrice) AS Revenue
FROM retail_clean
GROUP BY Hour
ORDER BY Hour;

---------------------------------------------------------
-- 3. تحليل العملاء (RFM Analysis)
---------------------------------------------------------

-- إنشاء جدول RFM
CREATE TABLE RFM_Segments AS
SELECT "Customer ID",
       MAX(InvoiceDate) AS LastPurchaseDate,
       julianday('2011-12-10') - julianday(MAX(InvoiceDate)) AS Recency,
       COUNT(DISTINCT InvoiceNo) AS Frequency,
       SUM(Quantity*UnitPrice) AS Monetary
FROM retail_clean
GROUP BY "Customer ID";

-- تقسيم العملاء حسب Recency
SELECT CASE
           WHEN Recency > 365 THEN 'Lost'
           ELSE 'Active'
       END AS Recency_Segment,
       COUNT(*) AS Num_Customers
FROM RFM_Segments
GROUP BY Recency_Segment;

-- تقسيم العملاء حسب Frequency
SELECT CASE
           WHEN Frequency = 1 THEN 'One-time'
           WHEN Frequency <= 5 THEN 'Low'
           WHEN Frequency <= 10 THEN 'Medium'
           ELSE 'High'
       END AS Frequency_Segment,
       COUNT(*) AS Num_Customers
FROM RFM_Segments
GROUP BY Frequency_Segment;

-- تقسيم العملاء حسب Monetary
SELECT CASE
           WHEN Monetary < 1000 THEN 'Low Spenders'
           WHEN Monetary < 5000 THEN 'Mid Spenders'
           ELSE 'High Spenders'
       END AS Monetary_Segment,
       COUNT(*) AS Num_Customers
FROM RFM_Segments
GROUP BY Monetary_Segment;

-- الدمج بين Recency و Monetary
SELECT Recency_Segment, Monetary_Segment, COUNT(*) AS Num_Customers
FROM (
    SELECT "Customer ID",
           CASE WHEN Recency > 365 THEN 'Lost' ELSE 'Active' END AS Recency_Segment,
           CASE WHEN Monetary < 1000 THEN 'Low Spenders'
                WHEN Monetary < 5000 THEN 'Mid Spenders'
                ELSE 'High Spenders' END AS Monetary_Segment
    FROM RFM_Segments
)
GROUP BY Recency_Segment, Monetary_Segment;

-- الدمج بين Frequency و Monetary
SELECT Frequency_Segment, Monetary_Segment, COUNT(*) AS Num_Customers
FROM (
    SELECT "Customer ID",
           CASE WHEN Frequency = 1 THEN 'One-time'
                WHEN Frequency <= 5 THEN 'Low'
                WHEN Frequency <= 10 THEN 'Medium'
                ELSE 'High' END AS Frequency_Segment,
           CASE WHEN Monetary < 1000 THEN 'Low Spenders'
                WHEN Monetary < 5000 THEN 'Mid Spenders'
                ELSE 'High Spenders' END AS Monetary_Segment
    FROM RFM_Segments
)
GROUP BY Frequency_Segment, Monetary_Segment;


/* ================================
   Summary of Key Insights
   ================================
   - UK هي أكبر سوق بإجمالي إيرادات ~8.1M
   - أعلى عميل واحد حقق مبيعات بـ1.19M
   - المنتجات الأكثر مبيعًا: WHITE HANGING HEART T-LIGHT HOLDER, WORLD WAR 2 GLIDERS ...
   - مواسم الذروة: نوفمبر هو الشهر الأعلى إيرادًا (~1.4M)
   - معظم الإيرادات بتيجي من أيام الاثنين والخميس والثلاثاء
   - الذروة اليومية في الساعات 11-13
   - ربحية العملاء: أغلب العملاء في شريحة Lost & Low Spenders
   - عملاء High Frequency & High Spenders = 205 (أهم شريحة للحفاظ عليها)
*/
