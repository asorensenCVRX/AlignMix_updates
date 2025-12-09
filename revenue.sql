DECLARE @C12 VARCHAR(7) = FORMAT(DATEADD(MONTH, -12, GETDATE()), 'yyyy_MM'),
@P12 VARCHAR(7) = FORMAT(DATEADD(MONTH, -24, GETDATE()), 'yyyy_MM'),
@LAST_MONTH VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM'),
@P12_END VARCHAR(7) = FORMAT(DATEADD(MONTH, -13, GETDATE()), 'yyyy_MM');


WITH OPPS AS (
    SELECT
        *
    FROM
        tmpOpps
    WHERE
        OPP_STATUS = 'CLOSED'
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
),
C12 AS (
    SELECT
        ACT_ID,
        SUM(
            CASE
                WHEN CLOSE_YYYYMM BETWEEN @C12
                AND @LAST_MONTH THEN SALES
                ELSE 0
            END
        ) AS C12_SALES,
        SUM(
            CASE
                WHEN CLOSE_YYYYMM BETWEEN @C12
                AND @LAST_MONTH THEN REVENUE_UNITS
                ELSE 0
            END
        ) AS C12_REV_UNITS,
        SUM(
            CASE
                WHEN IMPLANTED_YYYYMM BETWEEN @C12
                AND @LAST_MONTH THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS C12_IMPLANTS
    FROM
        OPPS
    GROUP BY
        ACT_ID
),
P12 AS (
    SELECT
        ACT_ID,
        SUM(
            CASE
                WHEN CLOSE_YYYYMM BETWEEN @P12
                AND @P12_END THEN SALES
                ELSE 0
            END
        ) AS P12_SALES,
        SUM(
            CASE
                WHEN CLOSE_YYYYMM BETWEEN @P12
                AND @P12_END THEN REVENUE_UNITS
                ELSE 0
            END
        ) AS P12_REV_UNITS,
        SUM(
            CASE
                WHEN IMPLANTED_YYYYMM BETWEEN @P12
                AND @P12_END THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS P12_IMPLANTS
    FROM
        OPPS
    GROUP BY
        ACT_ID
),
CY AS (
    SELECT
        ACT_ID,
        SUM(
            CASE
                WHEN CLOSE_YYYY = YEAR(GETDATE())
                AND CLOSE_YYYYMM <= @LAST_MONTH THEN SALES
                ELSE 0
            END
        ) AS CY_SALES,
        SUM(
            CASE
                WHEN CLOSE_YYYY = YEAR(GETDATE())
                AND CLOSE_YYYYMM <= @LAST_MONTH THEN REVENUE_UNITS
                ELSE 0
            END
        ) AS CY_REV_UNITS,
        SUM(
            CASE
                WHEN IMPLANTED_YYYY = YEAR(GETDATE())
                AND IMPLANTED_YYYYMM <= @LAST_MONTH THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS CY_IMPLANTS
    FROM
        OPPS
    GROUP BY
        ACT_ID
),
PY AS (
    SELECT
        ACT_ID,
        SUM(
            CASE
                WHEN CLOSE_YYYY = YEAR(GETDATE()) - 1 THEN SALES
                ELSE 0
            END
        ) AS PY_SALES,
        SUM(
            CASE
                WHEN CLOSE_YYYY = YEAR(GETDATE()) - 1 THEN REVENUE_UNITS
                ELSE 0
            END
        ) AS PY_REV_UNITS,
        SUM(
            CASE
                WHEN IMPLANTED_YYYY = YEAR(GETDATE()) - 1 THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS PY_IMPLANTS
    FROM
        OPPS
    GROUP BY
        ACT_ID
)
SELECT
    A.ID AS ACT_ID,
    C12.C12_SALES,
    C12.C12_REV_UNITS,
    C12.C12_IMPLANTS,
    P12.P12_SALES,
    P12.P12_REV_UNITS,
    P12.P12_IMPLANTS,
    CY.CY_SALES,
    CY.CY_REV_UNITS,
    CY.CY_IMPLANTS,
    PY.PY_SALES,
    PY.PY_REV_UNITS,
    PY.PY_IMPLANTS
FROM
    sfdcAccount A
    LEFT JOIN C12 ON A.ID = C12.ACT_ID
    LEFT JOIN P12 ON A.ID = P12.ACT_ID
    LEFT JOIN CY ON A.ID = CY.ACT_ID
    LEFT JOIN PY ON A.ID = PY.ACT_ID;