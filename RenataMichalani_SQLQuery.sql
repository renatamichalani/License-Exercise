
--Procedure for cleansing names and addresses
CREATE PROCEDURE cleansing
AS SET NOCOUNT ON
BEGIN 
 
	-- Preparing database
	ALTER TABLE LiquorLic ALTER COLUMN "Expiration Date" date
	ALTER TABLE Main_db DROP COLUMN F7, F8, F9, F10, F11, F12, F13, F14, F15, F16
	ALTER TABLE LiquorLic ADD ID_Store char(26)
	ALTER TABLE Main_db ADD ID_Store char(26)

	-- Cleaning Liquor Licenses table
	UPDATE LiquorLic
		-- Cleaning Address
		SET Address = replace (replace (replace (replace (replace (replace (replace (replace (replace (replace (replace (Address, 'AVENUE', 'AVE'), 'STREET', 'ST'), 'BOULEVARD', 'BLVD'), 'LANE', 'LN'), 'DRIVE', 'DR'), ' NORTH ', ' N '), ' EAST ', ' E '), ' SOUTH ', ' S '), ' WEST ', ' W '), 'SUITE', 'STE'), ' , ', ', ')

	UPDATE LiquorLic
		-- Taking way apostrophes, 'LLC', 'INC', etc on Names in Liquor Licenses table
		SET [Premises Name] = replace (replace (replace (replace (replace (replace ([Premises Name], ' CORP', ''), 'CORPORATION', ''), ' LLC', ''), ' INC', ''), ' LTD', ''), '''', ' ')

	-- Cleaning Main Database table
	UPDATE Main_db
		-- Cleaning Address using same criteria as above 
		SET Street = replace (replace (replace (replace (replace (replace (replace (replace (replace (replace (replace (Street, 'AVENUE', 'AVE'), 'STREET', 'ST'), 'BOULEVARD', 'BLVD'), 'LANE', 'LN'), 'DRIVE', 'DR'), ' NORTH ', ' N '), ' EAST ', ' E '), ' SOUTH ', ' S '), ' WEST ', ' W '), 'SUITE', 'STE'), ' , ', ', ')
		
	UPDATE Main_db
		-- Taking way apostrophes, 'LLC', 'INC', etc on Names in Main Database table
		SET Name = replace (replace (replace (replace (replace (replace (Name, ' CORP', ''), 'CORPORATION', ''), ' LLC', ''), ' INC', ''), ' LTD', ''), '''', ' ')
	
	-- To organize results
	SELECT [Premises Name], Address, [License Class], [License Type], [Expiration Date], [License Status] FROM LiquorLic
	SELECT Name, Street, City, State, [Zip Code], [Unique ID] FROM Main_db
END


-- To execute procedure for cleansing names and adresses
EXEC cleansing



-- Procedure to remove duplicates and create a table with matched 
CREATE PROCEDURE RemoveDupl
AS SET NOCOUNT ON
BEGIN 

	-- To create an ID_Store at Liquor Licenses table by concatenating 10 first characters of cleaned Name + 10 first characters of cleaned Address + Zip Code
	UPDATE LiquorLic
		SET LiquorLic.ID_Store = CONCAT (LEFT([Premises Name],10), LEFT(Address,10), RIGHT(Address,5)) from LiquorLic
	
	-- To create an ID_Store at Main Database table by concatenating 10 first characters of cleaned Name + 10 first characters of cleaned Address + Zip Code
	UPDATE Main_db
		SET ID_Store = CONCAT (LEFT(Name, 10), LEFT(Street, 10), LEFT("Zip Code",5)) from Main_db;

	--To remove duplicates deleting old licenses
	WITH ct1 AS (SELECT ID_Store, "Expiration Date", ROW_NUMBER () OVER (PARTITION BY ID_Store ORDER BY "Expiration Date" DESC) AS r_count FROM LiquorLic)
	DELETE 
	FROM ct1
	WHERE r_count>1;

	--To remove duplicates with same Expiration Date
	WITH ct2 AS (SELECT ID_Store, ROW_NUMBER () OVER (PARTITION BY ID_Store ORDER BY [Unique ID] DESC) AS r_count2 FROM Main_db)
	DELETE
	FROM ct2
	WHERE r_count2>1;

END


-- To execute procedure to remove duplicates
EXEC RemoveDupl



-- Function to have matched rows with all columns from the original tables
CREATE FUNCTION Match()
	RETURNS @values Table ([Premises Name] varchar(100), Address varchar(100), [License Class] varchar(3), [License Type] varchar(2), [Expiration Date] date, [License Status] varchar(30), Name varchar(100),
							Street varchar(100), City varchar(50), State char(2), [Zip Code] int, [Unique ID] char(36))
AS
BEGIN
	INSERT @values ([Premises Name], Address, [License Class], [License Type], [Expiration Date], [License Status], Name, Street, City, State, [Zip Code], [Unique ID])

	SELECT L.[Premises Name], L.Address, L.[License Class], L.[License Type], L.[Expiration Date], L.[License Status], M.Name, M.Street, M.City, M.State, M.[Zip Code], M.[Unique ID] from LiquorLic AS L 
	inner join Main_db AS M
	ON L.ID_Store = M.ID_Store 

	RETURN 
END 


-- To insert results as a new table
SELECT * INTO MatchedTable FROM Match()