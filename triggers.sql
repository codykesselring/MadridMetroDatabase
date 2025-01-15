CREATE TRIGGER CalculateAge
ON Clients
AFTER INSERT, UPDATE
AS
BEGIN
    -- Declare a variable to store the calculated age
    DECLARE @ClientID VARCHAR(10);
    DECLARE @DateOfBirth DATE;
    DECLARE @Age INT;

    -- Select the inserted or updated records
    SELECT 
        @ClientID = ClientID,
        @DateOfBirth = DateOfBirth
    FROM inserted;

    -- Calculate the age based on DateOfBirth and current date
    SET @Age = DATEDIFF(YEAR, @DateOfBirth, GETDATE()) - 
                CASE 
                    WHEN MONTH(@DateOfBirth) > MONTH(GETDATE()) OR 
                         (MONTH(@DateOfBirth) = MONTH(GETDATE()) AND DAY(@DateOfBirth) > DAY(GETDATE()))
                    THEN 1 
                    ELSE 0 
                END;

    -- Update the 'age' field for the client
    UPDATE Clients
    SET age = @Age
    WHERE ClientID = @ClientID;
END;
----------------------------------------------------

drop TRIGGER AssignFinalPrice
CREATE TRIGGER AssignFinalPriceForRecharge
ON MonthlyRecharges
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @ClientID VARCHAR(10);
    DECLARE @ZoneCode VARCHAR(5);
    DECLARE @FinalPrice DECIMAL(10, 2);
    DECLARE @Amount DECIMAL(5, 2);

    -- Select cardNumber and amount from the inserted record
    SELECT @CardNumber = cardNumber, @Amount = amount FROM inserted;

    -- Get the clientID associated with the cardNumber from MonthlyMetroCard table
    SELECT @ClientID = clientID
    FROM MonthlyMetroCard
    WHERE cardNumber = @CardNumber;

    -- Get the ZoneCode associated with the client from the Clients table
    SELECT @ZoneCode = ZoneCode
    FROM Clients
    WHERE ClientID = @ClientID;

    -- Retrieve the price associated with the zone from the zonePrices table
    SELECT @FinalPrice = priceNormal 
    FROM zonePrices 
    WHERE zoneID = @ZoneCode;

    -- Update the finalPrice in the MonthlyRecharges table based on the zone price
    UPDATE MonthlyRecharges
    SET amount = @FinalPrice
    WHERE cardNumber = @CardNumber AND rechargeID = (SELECT rechargeID FROM inserted);
END;

-------------
----------------------------------------------------


drop trigger AssignZoneCodeBasedOnAge
CREATE TRIGGER AssignZoneCodeBasedOnAge
ON Clients
AFTER INSERT, UPDATE
AS
BEGIN
    -- Declare variables
    DECLARE @ClientID VARCHAR(10);
    DECLARE @Age INT;
    DECLARE @ZoneCode VARCHAR(5);
    DECLARE @CurrentZoneCode VARCHAR(5);

    -- Select the client ID and age from the inserted row(s)
    SELECT @ClientID = ClientID, @Age = age
    FROM inserted;

    -- Get the current ZoneCode for the client
    SELECT @CurrentZoneCode = ZoneCode FROM Clients WHERE ClientID = @ClientID;

    -- Assign the ZoneCode based on the age
    IF @Age < 26
    BEGIN
        SET @ZoneCode = 'J';  -- Assign 'J' for age less than 26
    END
    ELSE IF @Age > 65
    BEGIN
        SET @ZoneCode = 'M';  -- Assign 'M' for age greater than 65
    END
    ELSE
    BEGIN
        SET @ZoneCode = @CurrentZoneCode;  -- Keep the existing ZoneCode
    END

    -- Only update the ZoneCode if it's different from the current one
    IF @ZoneCode <> @CurrentZoneCode
    BEGIN
        -- Update the ZoneCode in the Clients table
        UPDATE Clients
        SET ZoneCode = @ZoneCode
        WHERE ClientID = @ClientID;
    END
END;
----------------------------------------------------

DROP TRIGGER ApplyDiscountToCharges
CREATE TRIGGER ApplyDiscountToMonthlyRecharges
ON MonthlyRecharges
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @ClientID VARCHAR(10);
    DECLARE @ZoneCode VARCHAR(5);
    DECLARE @ZonePrice DECIMAL(10, 2);
    DECLARE @DiscountCode VARCHAR(10);
    DECLARE @DiscountRate DECIMAL(5, 2);
    DECLARE @FinalPrice DECIMAL(10, 2);

    -- Fetch the cardNumber and amount from the inserted row
    SELECT @CardNumber = cardNumber
    FROM inserted;

    -- Get the clientID from MonthlyMetroCard based on cardNumber
    SELECT @ClientID = clientID
    FROM MonthlyMetroCard
    WHERE cardNumber = @CardNumber;

    -- Get the ZoneCode for the client from the Clients table
    SELECT @ZoneCode = ZoneCode
    FROM Clients
    WHERE ClientID = @ClientID;

    -- Retrieve the price associated with the zone from the zonePrices table
    SELECT @ZonePrice = priceNormal
    FROM zonePrices
    WHERE zoneID = @ZoneCode;

    -- Get the discount ID for the client from the Clients table
    SELECT @DiscountCode = DiscountID
    FROM Clients
    WHERE ClientID = @ClientID;

    -- Get the discount rate from the discounts table, default to 0 if no discount
    SELECT @DiscountRate = ISNULL(appliedDiscount, 0)
    FROM discounts
    WHERE discountID = @DiscountCode;

    -- Calculate the final price after applying the discount
    SET @FinalPrice = @ZonePrice * (1 - @DiscountRate);

    -- Update the finalPrice in the MonthlyRecharges table
    UPDATE MonthlyRecharges
    SET amount = @FinalPrice
    WHERE cardNumber = @CardNumber;
END;

----------------------------------------------------


CREATE TRIGGER CheckFamilyType
ON Clients
AFTER INSERT
AS
BEGIN
    DECLARE @familyType VARCHAR(50);

    -- Get the familyType from the inserted row
    SELECT @familyType = familyType FROM inserted;

    -- Check if the familyType is valid
    IF @familyType NOT IN ('Normal', 'Big Family Normal', 'Big Family Special', 'Disabled', 'Senior')
    BEGIN
        -- Raise an error and inform the user
        RAISERROR('Invalid familyType. Valid options are: Normal, Big Family Normal, Big Family Special, Disabled, or Senior.', 16, 1);
        ROLLBACK TRANSACTION;  -- Rollback the insert if the familyType is invalid
    END
END;


drop trigger AssignDiscountIDBasedOnFamilyType
CREATE TRIGGER AssignDiscountIDBasedOnFamilyType
ON Clients
AFTER INSERT, UPDATE
AS
BEGIN
    -- Declare variables
    DECLARE @ClientID VARCHAR(10);
    DECLARE @FamilyType VARCHAR(50);
    DECLARE @DiscountID VARCHAR(5);
    DECLARE @CurrentDiscountID VARCHAR(5);

    -- Select the client ID and familyType from the inserted row(s)
    SELECT @ClientID = ClientID, @FamilyType = familyType
    FROM inserted;

    -- Get the current DiscountID for the client to avoid unnecessary updates
    SELECT @CurrentDiscountID = DiscountID
    FROM Clients
    WHERE ClientID = @ClientID;

    -- Assign DiscountID based on familyType
    IF @FamilyType = 'Big Family Normal'
    BEGIN
        SET @DiscountID = 'BFN';  -- Big Family Normal
    END
    ELSE IF @FamilyType = 'Big Family Special'
    BEGIN
        SET @DiscountID = 'BFS';  -- Big Family Special
    END
    ELSE IF @FamilyType = 'Disabled'
    BEGIN
        SET @DiscountID = 'DS';   -- Disabled
    END
    ELSE IF @FamilyType = 'Senior'
    BEGIN
        SET @DiscountID = 'DS';   -- Senior (same as Disabled)
    END
    ELSE IF @FamilyType = 'Normal'
    BEGIN
        SET @DiscountID = 'NA';   -- Normal (No discount)
    END

    -- Update the DiscountID only if it's NULL or different from the current one
    IF (@CurrentDiscountID IS NULL OR @DiscountID <> @CurrentDiscountID)
    BEGIN
        -- Update the DiscountID in the Clients table
        UPDATE Clients
        SET DiscountID = @DiscountID
        WHERE ClientID = @ClientID;
    END
END;
----------------------------------


CREATE TRIGGER SetExpirationDateOnCardCreation
ON MonthlyMetroCard
AFTER INSERT
AS
BEGIN
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @CreationDate DATE;

    -- Fetch cardNumber and creationDate from the inserted row
    SELECT @CardNumber = cardNumber, @CreationDate = creationDate
    FROM inserted;

    -- Set the expirationDate of the card to 30 days after the creationDate
    UPDATE MonthlyMetroCard
    SET expirationDate = DATEADD(DAY, 30, @CreationDate)
    WHERE cardNumber = @CardNumber;
END;
------------------------------------


CREATE TRIGGER UpdateExpirationDateOnRecharge
ON MonthlyRecharges
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @RechargeDate DATE;

    -- Fetch the cardNumber and rechargeDate from the inserted row
    SELECT @CardNumber = cardNumber, @RechargeDate = rechargeDate
    FROM inserted;

    -- Update the expirationDate of the card to 30 days after the rechargeDate
    UPDATE MonthlyMetroCard
    SET expirationDate = DATEADD(DAY, 30, @RechargeDate)
    WHERE cardNumber = @CardNumber;
END;
---------------------------------


CREATE TRIGGER EnforceInitialMultiEntryCardBalance
ON MultiEntryMetroCard
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @InitialBalance DECIMAL(5, 2);

    -- Fetch the card number and balance from the inserted row
    SELECT @CardNumber = cardNumber, @InitialBalance = balance
    FROM inserted;

    -- Check if the initial balance is less than 12 euros
    IF @InitialBalance < 12.00
    BEGIN
        -- Rollback the transaction and raise an error
        ROLLBACK TRANSACTION;
        RAISERROR ('Initial balance must be at least 12 euros.', 16, 1);
    END
END;
------------------------------------------

CREATE TRIGGER DeductBalanceOnCardUsage
ON MultiEntryCardUsage
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @CurrentBalance DECIMAL(5, 2);
    DECLARE @NewBalance DECIMAL(5, 2);

    -- Fetch the cardNumber from the inserted row
    SELECT @CardNumber = cardNumber
    FROM inserted;

    -- Get the current balance of the card
    SELECT @CurrentBalance = balance
    FROM MultiEntryMetroCard
    WHERE cardNumber = @CardNumber;

    -- Calculate the new balance after deducting 1.7 euros
    SET @NewBalance = @CurrentBalance - 1.7;

    -- Check if the balance is sufficient
    IF @NewBalance < 0
    BEGIN
        -- Rollback the transaction and raise an error
        ROLLBACK TRANSACTION;
        RAISERROR ('Insufficient balance for this transaction.', 16, 1);
    END
    ELSE
    BEGIN
        -- Update the balance in the MultiEntryMetroCard table
        UPDATE MultiEntryMetroCard
        SET balance = @NewBalance
        WHERE cardNumber = @CardNumber;
    END
END;
-------------------------------------------


CREATE TRIGGER UpdateBalanceOnRecharge
ON MultiEntryRecharges
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @CardNumber VARCHAR(10);
    DECLARE @RechargeAmount DECIMAL(5, 2);

    -- Fetch the cardNumber and amount from the inserted row
    SELECT @CardNumber = cardNumber, @RechargeAmount = amount
    FROM inserted;

    -- Update the balance in the MultiEntryMetroCard table
    UPDATE MultiEntryMetroCard
    SET balance = balance + @RechargeAmount
    WHERE cardNumber = @CardNumber;
END;


