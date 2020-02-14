DROP VIEW IF EXISTS logex.random_view;
GO

CREATE VIEW logex.random_view AS SELECT checksum(newid()) as random;
GO

DROP FUNCTION IF EXISTS logex.generate_random_string;
GO

CREATE FUNCTION logex.generate_random_string (@length int)
RETURNS varchar(1000)
AS
BEGIN
    DECLARE @whitelist varchar(26) = 'abcdefghijklmnopqrstuvwxyz';
    DECLARE @randomInt integer; /* 1-26 */
    DECLARE @result varchar(1000) = '';

    WHILE len(@result) < @length
    BEGIN
        SELECT @randomInt = 1 + abs(random) % 26 FROM logex.random_view;
        SELECT @result = @result + substring(@whitelist, @randomInt, 1);
    END;
    RETURN @result;
END;

