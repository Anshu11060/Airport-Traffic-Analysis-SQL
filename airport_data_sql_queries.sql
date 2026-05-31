-- ============================================================
-- US DOMESTIC AIR TRAFFIC ANALYSIS — JANUARY 2025
-- Data Source: US Bureau of Transportation Statistics
-- ============================================================

CREATE DATABASE flight_analysis;
USE flight_analysis;

-- ============================================================
-- SECTION 1: TABLE CREATION
-- ============================================================

CREATE TABLE AIRLINE (
    AIRLINE_ID INT PRIMARY KEY,
    UNIQUE_CARRIER VARCHAR(20),
    UNIQUE_CARRIER_NAME VARCHAR(50),
    UNIQUE_CARRIER_ENTITY VARCHAR(15)
);

CREATE TABLE AIRPORT (
    AIRPORT_ID INT PRIMARY KEY,
    AIRPORT_SEQ_ID INT,
    CITY_MARKET_ID INT,
    AIRPORT_CODE VARCHAR(10),
    CITY_NAME VARCHAR(50),
    STATE_FIPS INT,
    STATE_ABR CHAR(3),
    STATE_NM VARCHAR(100),
    WAC INT
);

CREATE TABLE FLIGHT (
    FLIGHT_ID INT AUTO_INCREMENT PRIMARY KEY,
    AIRLINE_ID INT,
    ORIGIN_AIRPORT_ID INT,
    DEST_AIRPORT_ID INT,
    DISTANCE FLOAT,
    DISTANCE_GROUP INT,
    YEAR INT,
    QUARTER INT,
    MONTH INT,
    CLASS CHAR(1),
    FOREIGN KEY (AIRLINE_ID) REFERENCES AIRLINE(AIRLINE_ID),
    FOREIGN KEY (ORIGIN_AIRPORT_ID) REFERENCES AIRPORT(AIRPORT_ID),
    FOREIGN KEY (DEST_AIRPORT_ID) REFERENCES AIRPORT(AIRPORT_ID)
);

CREATE TABLE FLIGHTMETRICS (
    FLIGHT_ID INT,
    PASSENGERS FLOAT,
    FREIGHT DOUBLE,
    MAIL FLOAT,
    FOREIGN KEY (FLIGHT_ID) REFERENCES FLIGHT(FLIGHT_ID)
);

CREATE TABLE CITY (
    CITY_ID INT AUTO_INCREMENT PRIMARY KEY,
    CITY_NAME VARCHAR(100),
    STATE_ABR CHAR(2),
    STATE_NM VARCHAR(100),
    UNIQUE (CITY_NAME, STATE_ABR)
);

-- ============================================================
-- SECTION 2: DATA INSERTION
-- ============================================================

-- Insert airlines
INSERT IGNORE INTO AIRLINE (AIRLINE_ID, UNIQUE_CARRIER, UNIQUE_CARRIER_NAME, UNIQUE_CARRIER_ENTITY)
SELECT DISTINCT AIRLINE_ID, UNIQUE_CARRIER, UNIQUE_CARRIER_NAME, UNIQUE_CARRIER_ENTITY
FROM META_DATA
WHERE AIRLINE_ID IS NOT NULL;

-- Insert origin airports
INSERT INTO AIRPORT (AIRPORT_ID, AIRPORT_SEQ_ID, CITY_MARKET_ID, AIRPORT_CODE, CITY_NAME, STATE_ABR, STATE_FIPS, STATE_NM, WAC)
SELECT DISTINCT
    ORIGIN_AIRPORT_ID, ORIGIN_AIRPORT_SEQ_ID, ORIGIN_CITY_MARKET_ID,
    ORIGIN, ORIGIN_CITY_NAME, ORIGIN_STATE_ABR, ORIGIN_STATE_FIPS,
    ORIGIN_STATE_NM, ORIGIN_WAC
FROM META_DATA;

-- Insert destination airports (only those not already inserted)
INSERT INTO AIRPORT (AIRPORT_ID, AIRPORT_SEQ_ID, CITY_MARKET_ID, AIRPORT_CODE, CITY_NAME, STATE_ABR, STATE_FIPS, STATE_NM, WAC)
SELECT DISTINCT
    DEST_AIRPORT_ID, DEST_AIRPORT_SEQ_ID, DEST_CITY_MARKET_ID,
    DEST, DEST_CITY_NAME, DEST_STATE_ABR, DEST_STATE_FIPS,
    DEST_STATE_NM, DEST_WAC
FROM META_DATA
WHERE DEST_AIRPORT_ID NOT IN (SELECT AIRPORT_ID FROM AIRPORT);

-- Insert flights
INSERT INTO FLIGHT (AIRLINE_ID, ORIGIN_AIRPORT_ID, DEST_AIRPORT_ID, DISTANCE, DISTANCE_GROUP, YEAR, QUARTER, MONTH, CLASS)
SELECT AIRLINE_ID, ORIGIN_AIRPORT_ID, DEST_AIRPORT_ID, DISTANCE, DISTANCE_GROUP,
       YEAR, QUARTER, MONTH, CLASS
FROM META_DATA;

-- Insert flight metrics
INSERT INTO FLIGHTMETRICS (FLIGHT_ID, PASSENGERS, FREIGHT, MAIL)
SELECT
    F.FLIGHT_ID, M.PASSENGERS,
    CAST(M.FREIGHT AS DECIMAL(15,2)), M.MAIL
FROM META_DATA M
JOIN FLIGHT F
    ON F.AIRLINE_ID = M.AIRLINE_ID
    AND F.ORIGIN_AIRPORT_ID = M.ORIGIN_AIRPORT_ID
    AND F.DEST_AIRPORT_ID = M.DEST_AIRPORT_ID
    AND F.YEAR = M.YEAR
    AND F.MONTH = M.MONTH
    AND F.QUARTER = M.QUARTER
    AND F.DISTANCE = M.DISTANCE;

-- Insert cities
INSERT INTO CITY (CITY_NAME, STATE_ABR, STATE_NM)
SELECT DISTINCT ORIGIN_CITY_NAME, ORIGIN_STATE_ABR, ORIGIN_STATE_NM
FROM META_DATA;

INSERT INTO CITY (CITY_NAME, STATE_ABR, STATE_NM)
SELECT DISTINCT DEST_CITY_NAME, DEST_STATE_ABR, DEST_STATE_NM
FROM META_DATA
WHERE DEST_CITY_NAME NOT IN (SELECT CITY_NAME FROM CITY);

-- ============================================================
-- SECTION 3: DATA CLEANING
-- ============================================================

-- Step 1: Check for non-numeric values in FREIGHT
-- Finding: No dirty records found — all non-null FREIGHT values are clean numbers
SELECT FREIGHT FROM META_DATA
WHERE FREIGHT IS NOT NULL
AND FREIGHT NOT REGEXP '^[0-9.]+$';

-- Step 2: Convert empty FREIGHT strings to NULL
SET SQL_SAFE_UPDATES = 0;
UPDATE META_DATA
SET FREIGHT = NULL
WHERE TRIM(FREIGHT) = '';
SET SQL_SAFE_UPDATES = 1;

-- Step 3: Remove invalid records where origin = destination (113 records)
SET SQL_SAFE_UPDATES = 0;
DELETE FM FROM FLIGHTMETRICS FM
JOIN FLIGHT F ON FM.FLIGHT_ID = F.FLIGHT_ID
WHERE F.ORIGIN_AIRPORT_ID = F.DEST_AIRPORT_ID;

DELETE FROM FLIGHT
WHERE ORIGIN_AIRPORT_ID = DEST_AIRPORT_ID;
SET SQL_SAFE_UPDATES = 1;

-- Step 4: Replace NULL freight with 0 in FLIGHTMETRICS
SET SQL_SAFE_UPDATES = 0;
UPDATE FLIGHTMETRICS
SET FREIGHT = 0
WHERE FREIGHT IS NULL;
SET SQL_SAFE_UPDATES = 1;

-- Verify all cleaning steps — all three should return 0
SELECT COUNT(*) AS null_freight_remaining FROM FLIGHTMETRICS WHERE FREIGHT IS NULL;
SELECT COUNT(*) AS same_origin_dest_remaining FROM FLIGHT WHERE ORIGIN_AIRPORT_ID = DEST_AIRPORT_ID;
SELECT COUNT(*) AS empty_freight_in_metadata FROM META_DATA WHERE TRIM(FREIGHT) = '';

-- ============================================================
-- SECTION 4: DATA ANALYSIS
-- Business Problem: Evaluate US domestic air traffic patterns
-- for January 2025 to identify top performing airlines,
-- busiest hubs, high demand routes, and freight leaders
-- to support capacity planning and operational decisions.
-- ============================================================


-- ============================================================
-- SECTION 4A: AIRLINE PERFORMANCE
-- ============================================================

-- Q1: Which airlines carried the most passengers?
SELECT
    AL.UNIQUE_CARRIER_NAME,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRLINE AL ON F.AIRLINE_ID = AL.AIRLINE_ID
WHERE FM.PASSENGERS > 0
GROUP BY AL.UNIQUE_CARRIER_NAME
ORDER BY TOTAL_PASSENGERS DESC
LIMIT 5;
-- FINDING: Southwest (11.04M) and Delta (11.04M) are nearly tied at the top.
-- American (9.7M) and United (9.1M) follow closely.
-- These 4 airlines dominate domestic passenger traffic.


-- Q2: Which airlines have the highest average passengers per flight?
SELECT
    AL.UNIQUE_CARRIER_NAME,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS,
    ROUND(AVG(FM.PASSENGERS),0) AS AVG_PASSENGERS_PER_FLIGHT
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRLINE AL ON F.AIRLINE_ID = AL.AIRLINE_ID
WHERE FM.PASSENGERS > 0
GROUP BY AL.UNIQUE_CARRIER_NAME
ORDER BY AVG_PASSENGERS_PER_FLIGHT DESC
LIMIT 10;
-- FINDING: American Airlines leads with 11,041 avg passengers per flight,
-- followed by Hawaiian Airlines (10,169) and Delta (7,728).
-- Southwest despite highest total passengers averages only 4,473 per flight
-- indicating it operates more flights on shorter routes.


-- Q3: Airline market share by passenger volume
SELECT
    AL.UNIQUE_CARRIER_NAME,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    ROUND(SUM(FM.PASSENGERS) * 100.0 /
        (SELECT SUM(PASSENGERS) FROM FLIGHTMETRICS WHERE PASSENGERS > 0), 2)
    AS MARKET_SHARE_PCT
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRLINE AL ON F.AIRLINE_ID = AL.AIRLINE_ID
WHERE FM.PASSENGERS > 0
GROUP BY AL.UNIQUE_CARRIER_NAME
ORDER BY MARKET_SHARE_PCT DESC
LIMIT 5;
-- FINDING: Southwest (17.36%) and Delta (17.35%) together control 34.71%
-- of all domestic passenger traffic in January 2025.
-- Top 4 airlines collectively hold over 64% market share.


-- ============================================================
-- SECTION 4B: AIRPORT & CITY TRAFFIC
-- ============================================================

-- Q4: Which cities are the busiest origin hubs?
SELECT
    A.CITY_NAME AS ORIGIN_CITY,
    A.STATE_ABR,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRPORT A ON F.ORIGIN_AIRPORT_ID = A.AIRPORT_ID
WHERE FM.PASSENGERS > 0
GROUP BY A.CITY_NAME, A.STATE_ABR
ORDER BY TOTAL_PASSENGERS DESC
LIMIT 10;
-- FINDING: Atlanta (3.34M) is the busiest origin city, followed by
-- Denver (2.9M) and Chicago (2.84M).
-- Dallas/Fort Worth (2.62M) and New York (2.17M) complete the top 5.


-- Q5: Which states generate the most outbound air traffic?
SELECT
    A.STATE_NM,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRPORT A ON F.ORIGIN_AIRPORT_ID = A.AIRPORT_ID
WHERE FM.PASSENGERS > 0
GROUP BY A.STATE_NM
ORDER BY TOTAL_PASSENGERS DESC
LIMIT 10;
-- FINDING: Florida leads all states with 7.51M outbound passengers,
-- ahead of California (6.84M) and Texas (6.55M).
-- These 3 states alone generate over 32% of all domestic outbound traffic.


-- ============================================================
-- SECTION 4C: ROUTE INTELLIGENCE
-- ============================================================

-- Q6: Which are the busiest routes by total passengers?
SELECT
    A1.CITY_NAME AS ORIGIN_CITY,
    A2.CITY_NAME AS DEST_CITY,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    COUNT(F.FLIGHT_ID) AS FLIGHT_COUNT
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRPORT A1 ON F.ORIGIN_AIRPORT_ID = A1.AIRPORT_ID
JOIN AIRPORT A2 ON F.DEST_AIRPORT_ID = A2.AIRPORT_ID
WHERE FM.PASSENGERS > 0
GROUP BY A1.CITY_NAME, A2.CITY_NAME
ORDER BY TOTAL_PASSENGERS DESC
LIMIT 10;
-- FINDING: Atlanta to Orlando (181,787) and Newark to San Francisco (181,683)
-- are the two busiest routes in January 2025.
-- Miami to New York (156,277) ranks third.
-- New York, Atlanta and Orlando appear repeatedly confirming their hub status.


-- Q7: Which routes have the highest flight frequency?
SELECT
    A1.CITY_NAME AS ORIGIN_CITY,
    A2.CITY_NAME AS DEST_CITY,
    COUNT(F.FLIGHT_ID) AS FLIGHT_COUNT,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRPORT A1 ON F.ORIGIN_AIRPORT_ID = A1.AIRPORT_ID
JOIN AIRPORT A2 ON F.DEST_AIRPORT_ID = A2.AIRPORT_ID
GROUP BY A1.CITY_NAME, A2.CITY_NAME
ORDER BY FLIGHT_COUNT DESC
LIMIT 10;
-- FINDING: Seattle to Los Angeles is the most frequent corridor (20 flights, 121,117 passengers).
-- San Francisco to Los Angeles (16 flights, 146,682 passengers) carries more passengers
-- per flight despite fewer flights, indicating use of larger aircraft.


-- Q8: Short haul vs medium haul vs long haul traffic
SELECT
    CASE
        WHEN F.DISTANCE_GROUP <= 2 THEN 'Short Haul (0-500 miles)'
        WHEN F.DISTANCE_GROUP <= 5 THEN 'Medium Haul (500-1500 miles)'
        ELSE 'Long Haul (1500+ miles)'
    END AS DISTANCE_CATEGORY,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
WHERE FM.PASSENGERS > 0
GROUP BY DISTANCE_CATEGORY
ORDER BY TOTAL_PASSENGERS DESC;
-- FINDING: Short haul dominates with 11,970 flights carrying 39.5M passengers.
-- Medium haul carries 21.9M passengers across 4,965 flights.
-- Long haul has only 348 flights but still moves 2.15M passengers.
-- 73% of all domestic passengers travel under 500 miles.


-- ============================================================
-- SECTION 4D: FREIGHT & CARGO ANALYSIS
-- ============================================================

-- Q9: Which airlines lead in freight operations?
SELECT
    AL.UNIQUE_CARRIER_NAME,
    ROUND(SUM(FM.FREIGHT),2) AS TOTAL_FREIGHT_LBS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
JOIN AIRLINE AL ON F.AIRLINE_ID = AL.AIRLINE_ID
WHERE FM.FREIGHT > 0
GROUP BY AL.UNIQUE_CARRIER_NAME
ORDER BY TOTAL_FREIGHT_LBS DESC
LIMIT 5;
-- FINDING: FedEx (630.8M lbs) and UPS (561.8M lbs) are the dominant cargo carriers.
-- Together they carry over 1.19 billion lbs of freight in January 2025 alone.
-- Air Transport International (154.7M) and Atlas Air (143.8M) are distant third and fourth.
-- Passenger airlines carry negligible freight by comparison.


-- Q10: Passenger vs cargo flight class breakdown
SELECT
    F.CLASS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    ROUND(SUM(FM.FREIGHT),2) AS TOTAL_FREIGHT
FROM FLIGHT F
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
GROUP BY F.CLASS
ORDER BY TOTAL_FLIGHTS DESC;
-- FINDING: Class F (full service passenger) dominates with most flights and passengers.
-- Class G (pure cargo) and Class P (postal) carry zero passengers but significant freight.
-- Class L (regional commuter) serves smaller markets with lower passenger volumes.


-- ============================================================
-- SECTION 5: VIEWS FOR REUSABLE ANALYSIS
-- ============================================================

-- View 1: Destination city traffic with population ratio
-- Purpose: Compare how many passengers each destination city attracts
-- relative to its population — identifies cities that punch above their weight
CREATE VIEW PASS_POP_DES AS
SELECT
    C.CITY_NAME,
    C.POPULATION,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS,
    ROUND(SUM(FM.PASSENGERS)/C.POPULATION, 2) AS PASS_POP_RATIO
FROM CITY C
JOIN AIRPORT A ON A.CITY_NAME = C.CITY_NAME
JOIN FLIGHT F ON F.DEST_AIRPORT_ID = A.AIRPORT_ID
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
GROUP BY C.CITY_NAME, C.POPULATION
ORDER BY TOTAL_PASSENGERS DESC;

-- View 2: Origin city traffic with population ratio
-- Purpose: Identifies cities generating the most outbound traffic per capita
CREATE VIEW PASS_POP_ORI AS
SELECT
    C.CITY_NAME,
    C.POPULATION,
    SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
    ROUND(SUM(FM.PASSENGERS)/C.POPULATION, 2) AS PASS_POP_RATIO
FROM CITY C
JOIN AIRPORT A ON A.CITY_NAME = C.CITY_NAME
JOIN FLIGHT F ON F.ORIGIN_AIRPORT_ID = A.AIRPORT_ID
JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
GROUP BY C.CITY_NAME, C.POPULATION
ORDER BY PASS_POP_RATIO DESC;


-- ============================================================
-- BONUS: STORED PROCEDURE FOR STATE LEVEL TRAFFIC FILTERING
-- ============================================================

DELIMITER //
CREATE PROCEDURE STATE_LEVEL_TRAFFIC(IN STATE_NAME VARCHAR(30))
BEGIN
    SELECT
        A.CITY_NAME AS DEST_CITY,
        SUM(FM.PASSENGERS) AS TOTAL_PASSENGERS,
        COUNT(F.FLIGHT_ID) AS TOTAL_FLIGHTS
    FROM FLIGHT F
    JOIN FLIGHTMETRICS FM ON F.FLIGHT_ID = FM.FLIGHT_ID
    JOIN AIRPORT A ON F.DEST_AIRPORT_ID = A.AIRPORT_ID
    WHERE A.STATE_NM = STATE_NAME
    GROUP BY A.CITY_NAME
    ORDER BY TOTAL_PASSENGERS DESC;
END //
DELIMITER ;

-- Example usage:
CALL STATE_LEVEL_TRAFFIC('Alaska');
CALL STATE_LEVEL_TRAFFIC('Texas');
CALL STATE_LEVEL_TRAFFIC('Florida');