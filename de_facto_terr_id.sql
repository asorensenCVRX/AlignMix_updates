WITH E AS (
    SELECT
        *,
        CASE
            WHEN OVERLAP_FLAG = 1 THEN (
                SELECT
                    top 1 y.TERR_ID
                FROM
                    tblAct_Exceptions y
                WHERE
                    y.SFDC_ID = a.SFDC_ID
                    AND Y.COVERAGE_TYPE = 'Ownership Override'
                ORDER BY
                    Y.START
            )
        END AS OWNERSHIP_OVERRIDE_TERR_ID
    FROM
        (
            SELECT
                r.*,
                CASE
                    WHEN EXISTS (
                        SELECT
                            1
                        FROM
                            tblAct_Exceptions AS x
                        WHERE
                            x.SFDC_ID = r.SFDC_ID
                            AND x.START <= COALESCE(r.[END], CONVERT(date, '9999-12-31'))
                            AND r.START <= COALESCE(x.[END], CONVERT(date, '9999-12-31'))
                            AND NOT (
                                ISNULL(x.TERR_ID, '') = ISNULL(r.TERR_ID, '')
                                AND ISNULL(x.COVERAGE_TYPE, '') = ISNULL(r.COVERAGE_TYPE, '')
                                AND x.START = r.START
                                AND ISNULL(x.[END], '9999-12-31') = ISNULL(r.[END], '9999-12-31')
                            )
                    ) THEN 1
                    ELSE 0
                END AS OVERLAP_FLAG
            FROM
                tblAct_Exceptions AS r
        ) AS A
),
Q AS (
    SELECT
        A.NAME AS ACT_NAME,
        A.ID AS ACT_ID,
        CASE
            WHEN P.Tier IS NULL THEN 4
            ELSE P.Tier
        END AS TIER,
        A.DHC_IDN_NAME__C AS IDN,
        U.EMAIL AS SFDC_OWNER,
        R.TERRITORY_ID AS REP_TERR,
        R.DOT,
        R.TERRITORY,
        Z.REP_EMAIL AS ZIP_OWNER,
        Z.TERR_ID AS ZIP_TERR,
        Z.TERR_NAME AS ZIP_TERR_NM,
        CASE
            WHEN ISNULL(
                E.TERR_ID,
                CASE
                    WHEN COVERAGE_TYPE = 'Ownership Override' THEN E.TERR_ID
                    ELSE Z.TERR_ID
                END
            ) <> R.TERRITORY_ID
            OR R.TERRITORY_ID IS NULL THEN 1
            ELSE 0
        END AS [TERRITORY_MISMATCH?],
        E.TERR_ID AS OVERRIDE_TERR,
        E.COVERAGE_TYPE,
        CASE
            WHEN COVERAGE_TYPE = 'Ownership Override' THEN E.TERR_ID
            WHEN COVERAGE_TYPE = 'Open Territory'
            AND OVERLAP_FLAG = 1 THEN E.OWNERSHIP_OVERRIDE_TERR_ID
            ELSE Z.TERR_ID
        END AS DE_FACTO_TERR,
        CASE
            WHEN P.[STATUS] NOT IN ('Active', 'Dormant', 'Churned', 'At-Risk') THEN NULL
            ELSE P.[STATUS]
        END AS STAGE
    FROM
        sfdcAccount A
        LEFT JOIN sfdcUser U ON A.OWNERID = U.ID
        LEFT JOIN qryRoster R ON U.EMAIL = R.REP_EMAIL
        AND R.[isLATEST?] = 1
        AND R.ROLE = 'REP'
        LEFT JOIN qryZipAlign Z ON CAST(
            CASE
                WHEN LEN(LEFT(SHIPPINGPOSTALCODE, 5)) = 4 THEN CONCAT(0, LEFT(SHIPPINGPOSTALCODE, 5))
                ELSE LEFT(SHIPPINGPOSTALCODE, 5)
            END AS VARCHAR(5)
        ) = Z.ZIP_CODE
        LEFT JOIN E ON A.ID = E.SFDC_ID
        AND(
            E."END" IS NULL
            OR E."END" > GETDATE()
        )
        AND CASE
            WHEN E.OVERLAP_FLAG = 1 THEN 'Open Territory'
            ELSE E.COVERAGE_TYPE
        END = E.COVERAGE_TYPE
        LEFT JOIN tmpProgram_KPI P ON A.ID = P.SFDC_ID
        AND P.[EXCLUDE?] = 'NO'
    WHERE
        A.RECORDTYPEID = '012700000009c1fAAA'
        AND UPPER(A.NAME) NOT LIKE '%TEST%'
        AND PRIVACY_REGION__C = 'North America'
        AND U.EMAIL <> 'forcedev1@cvrx.com'
)
SELECT
    Q.ACT_ID AS ID,
    Q.DE_FACTO_TERR,
    CASE
        WHEN P.Tier IS NULL THEN 4
        ELSE P.Tier
    END AS TIER
FROM
    Q
    LEFT JOIN tmpProgram_KPI P ON Q.ACT_ID = P.SFDC_ID