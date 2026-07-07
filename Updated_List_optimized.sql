-- =====================================================================
-- Optimized query: Active LACA locations with a send AND/OR pay
-- transaction in the last month, flagging termination and account status
-- =====================================================================

SELECT
    A.BRAND,
    A.NWKREF                       AS NAID,
    A.LOCATIONID,
    A.PRIAGNTID,
    A.RGN                          AS REGION,
    A.CONTRY                       AS COUNTRY_CODE,
    P.CTYNAME                      AS COUNTRY_NAME,
    A.CTGRY,
    A.CUSTLSTIND                   AS CLI,
    A.AGTNME                       AS AGENT_NAME,
    A.AGTSTS                       AS AGENT_STATUS,
    A.PASTATUS                     AS PRIMARY_AGENT_ID_STATUS,
    A.ASTRDT                       AS AGENT_START_DATE,
    A.AADDR1,
    A.AADDR2,
    A.ACITY                        AS CITY,
    A.ASTATE                       AS STATE,
    A.ASTPRV                       AS PROVINCE,
    A.ZIPCDE                       AS ZIP_CODE,
    A.CLSDES                       AS CLASS_DESCRIPTION,
    CASE
        WHEN A.SWBFLG = 'N' THEN 'NON-SWB'
        ELSE 'SWB'
    END                             AS SWB_NON_SWB,
    A.VOLUME_INDICATOR,
    A.AHOMON                       AS OPEN_MON,
    A.AHCMON                       AS CLOSE_MON,
    A.AHOSAT                       AS OPEN_SAT,
    A.AHCSAT                       AS CLOSE_SAT,
    A.AHOSUN                       AS OPEN_SUN,
    A.AHCSUN                       AS CLOSE_SUN,
    A.AGLSTMTPAY                   AS LAST_MONEY_TRANSFER_PAY,
    A.AGLSTMTSND                   AS LAST_MONEY_TRANSFER_SEND,
    A.TERMINATION_CODE,

    -- Termination flag (based on TERMINATION_CODE, as in your original query)
    CASE
        WHEN A.TERMINATION_CODE IS NOT NULL
             AND TRIM(A.TERMINATION_CODE) <> ''
        THEN 'Terminada'
        ELSE 'Activa'
    END                             AS STATUS,

    -- NEW: explicit account-status flag, independent of termination code
    CASE
        WHEN A.AGTSTS <> 'A' THEN 'Cuenta NO activa - revisar'
        ELSE 'Cuenta activa'
    END                             AS ACCOUNT_STATUS_FLAG,

    -- NEW: shows which of the two transaction types happened last month
    CASE
        WHEN A.AGLSTMTPAY >= DATEADD(MONTH, -1, CURRENT_DATE())
             AND A.AGLSTMTSND >= DATEADD(MONTH, -1, CURRENT_DATE())
        THEN 'Envio y Pago'
        WHEN A.AGLSTMTPAY >= DATEADD(MONTH, -1, CURRENT_DATE())
        THEN 'Solo Pago'
        WHEN A.AGLSTMTSND >= DATEADD(MONTH, -1, CURRENT_DATE())
        THEN 'Solo Envio'
        ELSE 'Sin transaccion en el ultimo mes'
    END                             AS TXN_LAST_MONTH_TYPE

FROM ADH.AGENT_MASTER_PII.VW_AGENT_MT A
LEFT JOIN ADH.AGENT_MASTER_PII.VW_COUNTRY P
    ON P.CTYCODE = A.CONTRY

WHERE A.RGN IN ('LACA')
    AND A.LOCATIONID IS NOT NULL
    AND A.AGTSTS = 'A'                         -- only active accounts
    AND (
        A.AGLSTMTPAY >= DATEADD(MONTH, -1, CURRENT_DATE())   -- pay in last month
        OR A.AGLSTMTSND >= DATEADD(MONTH, -1, CURRENT_DATE()) -- send in last month
    )
    -- Optional filters — uncomment and fill in as needed:
    -- AND P.CTYNAME IN ('COSTA RICA','MEXICO')
    -- AND A.NWKREF IN ('...')
    -- AND A.PASTATUS IN ('...')
    -- AND A.LOCATIONID IN ('...')

ORDER BY A.LOCATIONID, A.CONTRY;

-- =====================================================================
-- If you ALSO want to see inactive/terminated locations in the same
-- result set instead of filtering them out, remove the
-- "AND A.AGTSTS = 'A'" line above — ACCOUNT_STATUS_FLAG and STATUS
-- will still tell you, per row, which ones are inactive or terminated.
-- =====================================================================
