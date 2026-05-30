# Airport-Traffic-Analysis-SQL
# US Domestic Air Traffic Analysis — January 2025

## Project Overview
This project analyzes 19,926 US domestic flight records from January 2025 
sourced from the US Bureau of Transportation Statistics. The goal was to 
evaluate airline performance, identify the busiest airport hubs, uncover 
high-demand routes, and assess cargo operations — insights that support 
capacity planning and operational decision-making in the aviation industry.

---

## Business Problem
> An aviation authority wants to understand domestic air traffic patterns 
> for January 2025 to identify high-performing airlines, congested hubs, 
> and high-demand routes — enabling smarter resource allocation, capacity 
> planning, and competitive benchmarking.

---

## Dataset
| Detail | Info |
|--------|------|
| Source | US Bureau of Transportation Statistics |
| Period | January 2025 |
| Records | 19,926 flight records |
| Tables | AIRLINE, AIRPORT, FLIGHT, FLIGHTMETRICS, CITY |
| Key Columns | PASSENGERS, FREIGHT, MAIL, DISTANCE, CLASS, ORIGIN, DESTINATION |

---

## Tools Used
- **MySQL** — database design, data cleaning, analysis
- **MySQL Workbench** — query execution and schema management


## Database Schema
META_DATA (raw source)
|
├── AIRLINE (101 unique airlines)
├── AIRPORT (origin + destination airports)
├── FLIGHT (one row per route operated)
├── FLIGHTMETRICS (passengers, freight, mail per flight)
└── CITY (city-level reference data)

---

## Data Cleaning Steps
1. Verified FREIGHT column for non-numeric values — no dirty records found
2. Converted empty FREIGHT strings to NULL
3. Removed 113 invalid records where origin = destination city
4. Replaced NULL freight values with 0 in FLIGHTMETRICS
5. Fixed column name typo (DUSTANCE_GROUP → DISTANCE_GROUP)

---

## Analysis Sections
- **Section 4A** — Airline Performance
- **Section 4B** — Airport & City Traffic
- **Section 4C** — Route Intelligence
- **Section 4D** — Freight & Cargo Analysis
- **Section 5** — Views for reusable analysis
- **Bonus** — Stored procedure for state-level traffic filtering

---

## Key Findings

### Airline Performance
- Southwest Airlines (11.04M) and Delta Air Lines (11.04M) are virtually 
  tied as the top domestic carriers in January 2025
- Together Southwest and Delta control **34.71%** of all domestic passenger traffic
- Top 4 airlines (Southwest, Delta, American, United) collectively hold **over 64% market share**
- American Airlines leads in average passengers per flight (**11,041**), 
  indicating larger aircraft and fuller flights than competitors

### Airport & City Traffic
- **Atlanta, GA** is the busiest origin hub with **3.34M passengers** in January 2025
- Top 5 cities — Atlanta, Denver, Chicago, Dallas/Fort Worth, New York — 
  dominate domestic departures
- **Florida** leads all states with **7.51M outbound passengers**, 
  followed by California (6.84M) and Texas (6.55M)
- These 3 states alone generate over **32% of all domestic outbound traffic**

### Route Intelligence
- **Atlanta → Orlando** (181,787 passengers) and 
  **Newark → San Francisco** (181,683 passengers) are the two busiest routes
- **Seattle → Los Angeles** is the most frequently operated corridor with 20 flights
- **73% of all domestic passengers** travel under 500 miles (short haul)
- Short haul (0–500 miles) carries 39.5M passengers across 11,970 flights

### Freight & Cargo
- **FedEx (630.8M lbs)** and **UPS (561.8M lbs)** dominate cargo operations
- Together they moved over **1.19 billion lbs** of freight in January 2025 alone
- Dedicated cargo carriers (Class G, Class P) carry zero passengers — 
  completely separate from passenger operations

---

## Project Structure
├── airport_analysis.sql       # Complete SQL file (setup + cleaning + analysis)
├── Airport_Project_Data.csv   # Raw dataset
└── README.md

---

## How to Run
1. Import `Airport_Project_Data.csv` into MySQL as `META_DATA`
2. Run `airport_analysis.sql` section by section in MySQL Workbench
3. Verify cleaning steps return 0 before running analysis queries

---

## Author
**Anshu Singh**  
[LinkedIn](https://linkedin.com/in/anshusingh11060) | 
[GitHub](https://github.com/anshu11060)


---

## Database Schema
