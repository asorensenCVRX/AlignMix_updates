SELECT
    'Territory Manager' AS [Job Title],
    REP_EMAIL AS [Personnel ID],
    NAME_REP AS [Name],
    TERRITORY_ID,
    TERR_NM,
    REGION_ID,
    REGION_NM
FROM
    qryRoster
WHERE
    [ROLE] = 'REP'
    AND [isLATEST?] = 1
    AND [STATUS] = 'ACTIVE'
UNION
ALL
SELECT
    'Area Sales Director' AS [Job Title],
    EMP_EMAIL,
    CONCAT(FNAME, ' ', LNAME) AS NAME_REP,
    NULL,
    NULL,
    TERRITORY_ID,
    NULL
FROM
    qryRoster_RM