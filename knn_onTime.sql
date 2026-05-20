- Input values for the parameters (detention, distance, k)
WITH Params AS (
    SELECT 
        130 AS input_detention,
        1200 AS input_distance,
        10 AS k_neighbors
),
-- Stadardize the variables and the inputs
MinMax AS (
    SELECT 
        MIN(de.detention_minutes) AS min_dm, 
        MAX(de.detention_minutes) AS max_dm,
        MIN(t.actual_distance_miles) AS min_adm, 
        MAX(t.actual_distance_miles) AS max_adm
    FROM delivery_events de
    JOIN trips t 
        ON de.trip_id = t.trip_id
),

NormalizedData AS (
    SELECT 
        de.on_time_flag, 
        de.detention_minutes, 
        t.actual_distance_miles,

        (de.detention_minutes - m.min_dm) / 
            NULLIF(m.max_dm - m.min_dm, 0) AS scaled_dm,

        (t.actual_distance_miles - m.min_adm) / 
            NULLIF(m.max_adm - m.min_adm, 0) AS scaled_adm,

        (p.input_detention - m.min_dm) / 
            NULLIF(m.max_dm - m.min_dm, 0) AS target_dm,

        (p.input_distance - m.min_adm) / 
            NULLIF(m.max_adm - m.min_adm, 0) AS target_adm,

        p.k_neighbors

    FROM delivery_events de
    JOIN trips t 
        ON de.trip_id = t.trip_id
    CROSS JOIN MinMax m
    CROSS JOIN Params p
),
-- Get the 10 nearest rows closest to target variable
RankedNeighbors AS (
    SELECT 
        on_time_flag,
        detention_minutes,
        actual_distance_miles,

        SQRT(
            POWER(scaled_dm - target_dm, 2) + 
            POWER(scaled_adm - target_adm, 2)
        ) AS normalized_distance,

        k_neighbors,

        ROW_NUMBER() OVER (
            ORDER BY 
                SQRT(
                    POWER(scaled_dm - target_dm, 2) + 
                    POWER(scaled_adm - target_adm, 2)
                )
        ) AS rn

    FROM NormalizedData
)

SELECT 
    on_time_flag,
    detention_minutes,
    actual_distance_miles,
    normalized_distance

FROM RankedNeighbors
WHERE rn <= k_neighbors
ORDER BY normalized_distance ASC;
-- Predicted results is False for a trip of 
-- 130- dentention minutes and 1200 miles of actual distance
