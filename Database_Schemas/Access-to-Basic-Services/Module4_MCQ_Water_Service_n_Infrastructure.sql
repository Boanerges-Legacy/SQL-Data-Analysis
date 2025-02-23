-- Find the percentage of each country land area by their sub-region
-- To do that, fisrt calculate the area of each sub-region and use it to find the percentage
SELECT 
	Sub_region,
    SUM(Land_area) AS TotalLandArea
FROM
	united_nations.geographical_location
GROUP BY 
	Sub_region;

-- Land area
SELECT 
	gloc.Country_name,
	gloc.Land_area,
	gloc.Sub_region,
    ROUND(Land_area *100/ RegionalLandArea.TotalLandArea) AS Pct_Total_CountryLand
FROM
	united_nations.geographical_location AS gloc
JOIN
	(
    SELECT 
		Sub_region,
		SUM(Land_area) AS TotalLandArea
	FROM
		united_nations.geographical_location
	GROUP BY 
		Sub_region
    ) AS RegionalLandArea
ON
gloc.Sub_region = RegionalLandArea.Sub_region
;

SELECT
Sub_region,
SUM(Land_area) AS Land_Area_per_Region
FROM united_nations.geographical_location
GROUP BY Sub_region
;

SELECT 
	geol.Country_name,
    geol.Land_area,
    geol.Sub_region,
    ROUND(Land_area/land_per_region.Land_Area_per_Region)*100 AS Pct_regional_land
FROM 
	united_nations.geographical_location AS geol
JOIN
	(
    SELECT
		Sub_region,
		SUM(Land_area) AS Land_Area_per_Region
	FROM united_nations.geographical_location
	GROUP BY Sub_region
	) AS land_per_region
ON geol.Sub_region = land_per_region.Pct_regional_land
;

SELECT * FROM united_nations.economic_indicators;
-- where Pct_unemployment is above 5%
SELECT 
	Country_name,
    Est_gdp_in_billions,
    Est_population_in_millions
    Pct_unemployment
FROM 
	united_nations.economic_indicators
WHERE
	Pct_unemployment > 5 AND Time_period = 2020
; 

-- USE md_water_services;
SELECT 
loc.province_name, loc.town_name, loc.location_id, 
vis.visit_count, ws.type_of_water_source, ws.number_of_people_served,
loc.location_type, vis.time_in_queue, wp.results
FROM 
visits vis
INNER JOIN
water_source ws
ON vis.source_id = ws.source_id
INNER JOIN
location loc
ON vis.location_id = loc.location_id
LEFT JOIN
well_pollution wp
ON vis.source_id = wp.source_id
WHERE vis.visit_count = 1
;

CREATE TABLE combined_analysis_table AS
SELECT 
loc.province_name, loc.town_name, loc.location_id, 
vis.visit_count, ws.type_of_water_source, ws.number_of_people_served,
loc.location_type, vis.time_in_queue, wp.results
FROM 
visits vis
INNER JOIN
water_source ws
ON vis.source_id = ws.source_id
INNER JOIN
location loc
ON vis.location_id = loc.location_id
LEFT JOIN
well_pollution wp
ON vis.source_id = wp.source_id
WHERE vis.visit_count = 1
;

-- 
SELECT 
	Country_name,
	(
    SELECT
		AVG(Est_gdp_in_billions) AS AvgGDP2020
	FROM united_nations.economic_indicators
	WHERE Time_period = 2020
    ) AS GlobalPopulation
FROM
	united_nations.economic_indicators
WHERE
	Time_period = 2020 and Est_gdp_in_billions = GlobalPopulation.AvgGDP2020
;
    
--  
SELECT
	ei.Country_name,
	ei.Est_gdp_in_billions,
	ei.Est_population_in_millions,
	bs.Pct_managed_drinking_water_services
FROM
	united_nations.economic_indicators ei
INNER JOIN	
	united_nations.basic_servces bs
ON
	ei.Country_name = bs.Country_name and ei.Time_period = bs.Time_period
WHERE
	ei.Time_period = 2020 AND bs.Pct_managed_drinking_water_services < 90 AND ei.Est_gdp_in_billions > (SELECT
AVG(Est_gdp_in_billions) AS AvgGDP
FROM united_nations.economic_indicators
WHERE Time_period = 2020)
;

-- WORKING WIHT CTE IN ACTION
WITH province_total AS (
	SELECT
		province_name,
		SUM(number_of_number_of_people_served) AS Total_ppl_served
	FROM
		combined_analysis_table
	GROUP BY province_name
)
	SELECT
		cat.province_name,
        ROUND(SUM(CASE WHEN (type_of_water_source = "river") THEN number_of_number_of_people_served ELSE 0 END)*100/Total_ppl_served) AS river,
        ROUND(SUM(CASE WHEN (type_of_water_source = "shared_tap") THEN number_of_number_of_people_served ELSE 0 END)*100/Total_ppl_served) AS shared_tap,
        ROUND(SUM(CASE WHEN (type_of_water_source = "tap_in_home") THEN number_of_number_of_people_served ELSE 0 END)*100/Total_ppl_served) AS tap_in_home,
        ROUND(SUM(CASE WHEN (type_of_water_source = "tap_in_home_broken") THEN number_of_number_of_people_served ELSE 0 END)*100/Total_ppl_served) AS tap_in_home_broken,
        ROUND(SUM(CASE WHEN (type_of_water_source = "well") THEN number_of_number_of_people_served ELSE 0 END)*100/Total_ppl_served) AS well
	FROM
		combined_analysis_table cat
	JOIN
		province_total pt
	ON 
		pt.province_name = cat.province_name
    GROUP BY 
		cat.province_name
	ORDER BY 
		cat.province_name;
        
-- 
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
-- This cat calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT 
	province_name, town_name, 
    SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name, town_name
)
SELECT
	cat.province_name,
	cat.town_name,
	ROUND((SUM(CASE WHEN type_of_water_source = 'river' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table cat
JOIN -- Since the town names are not unique, we have to join on a composite key
	town_totals tt 
ON 
	cat.province_name = tt.province_name AND cat.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
	cat.province_name, cat.town_name
ORDER BY
	cat.town_name;
    
SELECT * FROM town_aggregated_water_access;

-- This query creates the Project_progress table:
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
)

-- To make this simpler, we can start with this query: Project_progress_query
SELECT
	loc.address,
	loc.town_name,
	loc.province_name,
	ws.source_id,
	ws.type_of_water_source,
	wp.results,
    wp.biological
FROM
	water_source ws
LEFT JOIN
	well_pollution wp ON ws.source_id = wp.source_id
INNER JOIN
	visits vis ON ws.source_id = vis.source_id
INNER JOIN
	location loc ON loc.location_id = vis.location_id
WHERE
	vis.visit_count = 1 -- This must always be true
AND ( -- AND one of the following (OR) options must be true as well.
	wp.results != 'Clean'
	OR ws.type_of_water_source IN ('tap_in_home_broken', 'river')
	OR (ws.type_of_water_source = 'shared_tap' AND vis.time_in_queue >= 30)
);

-- Same as the above BUT Removed in-line comments from the middle of the query to avoid clutter.
SELECT
    loc.address,
    loc.town_name,
    loc.province_name,
    ws.source_id,
    ws.type_of_water_source,
    wp.results
FROM
    water_source ws
LEFT JOIN
    well_pollution wp ON ws.source_id = wp.source_id
INNER JOIN
    visits vis ON ws.source_id = vis.source_id
INNER JOIN
    location loc ON loc.location_id = vis.location_id
WHERE
    vis.visit_count = 1
    AND (
        wp.results != 'Clean' OR 
        ws.type_of_water_source IN ('tap_in_home_broken', 'river') OR
        (ws.type_of_water_source = 'shared_tap' AND vis.time_in_queue >= 30)
    );

-- CREATE A TABLE THAT KEEP TRACK OF MEASURE TAKEN TO ADDRESS THE WATER SITUATION
CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY, -- Auto-increment ID
    province_name VARCHAR(30), -- Data available
    town_name VARCHAR(30), -- Data available
    results VARCHAR(30), -- Data available
    source_id VARCHAR(20) NOT NULL REFERENCES ws(source_id) ON DELETE CASCADE ON UPDATE CASCADE, -- Data available
    type_of_water_source VARCHAR(30), -- Data available
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')), -- Default is 'Backlog'
    Improvement VARCHAR(50), -- Data available, though it may contain NULL for now
    Date_of_completion DATE -- NULL allowed for now since you may update later
);

-- THIS QUERY INSERT DATA INTO THE Project_progress TABLE AND WILL BE UPDATE WHER NECESSARY
INSERT INTO Project_progress (
    province_name,
    town_name,
    results,
    source_id,
    type_of_water_source,
    Improvement
)
SELECT 
	cat.province_name,
    cat.town_name,
    ws.source_id,
    cat.type_of_water_source,
    cat.results,
    CASE
		WHEN (cat.type_of_water_source = 'well' AND cat.results = 'Contaminated: Biological') THEN 'Install UV filter'
        WHEN (cat.type_of_water_source = 'well' AND cat.results = 'Contaminated: Chemical') THEN 'Install RO filter'
        WHEN (cat.type_of_water_source = 'well' AND cat.results = ('Contaminated: Biological and Chemical')) THEN 'Install UV and RO filter'
        WHEN (cat.type_of_water_source = 'river') THEN 'Drill well'
        WHEN (cat.type_of_water_source = 'shared_tap' AND cat.time_in_queue >= 30) THEN CONCAT("Install ", FLOOR(cat.time_in_queue/30), " taps nearby")
        WHEN (cat.type_of_water_source = 'tap_in_home_broken') THEN 'Diagnose local infrastructure'
        ELSE 'No improvement needed' 
	END
    AS Improvement
FROM md_water_services.combined_analysis_table cat
LEFT JOIN md_water_services.visits vis
ON cat.location_id = vis.location_id
LEFT JOIN water_source ws
ON vis.source_id = ws.source_id
LEFT JOIN location loc
ON vis.location_id = loc.location_id
;

-- QUERY WITH COMMENT FOR BETTER UNDERSTANDING SIMILLAR AS THE ABOVE QUERY Same as the above with comment.
SELECT 
    location_id,
    type_of_water_source,
    results,
    CASE
        -- Logic for wells (Step 1)
        WHEN (type_of_water_source = 'well' AND results = 'Contaminated: Biological') THEN 'Install UV filter'
        WHEN (type_of_water_source = 'well' AND results = 'Contaminated: Chemical') THEN 'Install RO filter'
        WHEN (type_of_water_source = 'well' AND results = 'Contaminated: Biological and Chemical') THEN 'Install UV and RO filter'
        -- Logic for rivers (Step 2)
        WHEN (type_of_water_source = 'river') THEN 'Drill well'
        -- Logic for shared taps (Step 3)
        WHEN (type_of_water_source = 'shared_tap' AND time_in_queue >= 30) THEN 
            CONCAT('Install ', FLOOR(time_in_queue / 30), ' taps nearby')
        -- Logic for broken taps (Step 4)
        WHEN (type_of_water_source = 'tap_in_home_broken') THEN 'Diagnose local infrastructure'
        -- Default case: Ensure no NULL values
        ELSE 'No improvement needed'
    END AS Improvement
FROM 
    md_water_services.combined_analysis_table;


-- THIS QUERY UPDATE THE Project_progress TABLE WHEN ANY CHANGES HAPPEN
UPDATE Project_progress
SET Date_of_completion = '2024-12-31' -- Example date
WHERE source_id = 'WS12345'; -- Filter by specific source_id

