create database test;
use test;

CREATE TABLE UserPrefs
(
UserID BIGINT,
ItemID BIGINT,
Preference FLOAT
PRIMARY KEY (UserID)
) COMMENT='User preferences for items';
