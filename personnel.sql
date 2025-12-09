SELECT
    A.*,
    E.[ADDRESS LINE 1],
    E.[ADDRESS LINE 2],
    E.CITY,
    E.[STATE/PROVINCE],
    E.[ZIP CODE/POSTAL CODE]
FROM
    (
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
    ) AS A
    LEFT JOIN tblEmployee E ON A.[Personnel ID] = E.[WORK E-MAIL]