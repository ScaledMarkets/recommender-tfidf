create database test;
use test;

CREATE TABLE UserPrefs ( UserID BIGINT PRIMARY KEY, ItemID BIGINT, Preference FLOAT );
GRANT ALL PRIVILEGES ON test.* to test;
