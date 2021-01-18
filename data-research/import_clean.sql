
-- Script for first steps on DB.

-- Initial Cleanup:

DROP SCHEMA IF EXISTS tiger CASCADE;
DROP SCHEMA IF EXISTS tiger_data CASCADE;


-- Alter tables / create index etc.
ALTER TABLE dta_sblock
ADD CONSTRAINT pk_dta_sblock PRIMARY KEY (sblock_id);