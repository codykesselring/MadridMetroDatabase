CREATE TABLE Clients (
    ClientID varchar(10) PRIMARY KEY,         -- Unique identifier for the client
    Name VARCHAR(255) not null,               -- Client's name
    DateOfBirth DATE not null,                -- Client's date of birth
	age INT,
    DiscountID varchar(5),                  -- Foreign key for discount information
    Address VARCHAR(255),            -- Client's address
    Email VARCHAR(255),              -- Client's email
    Phone VARCHAR(20),               -- Client's phone number
    ZoneCode VARCHAR(5) not null,             -- Zone where the client want to travel
	familyType varchar(50) not null,			 -- Normal, big family, special
	cardType varchar(50) not null,			 -- monthly or multi entry
	FOREIGN KEY (ZoneCode) REFERENCES zonePrices(zoneID)
);

create table zonePrices(
	zoneID varchar(5) primary key,
	priceNormal DECIMAL(5, 2)
);


create table discounts(
	discountID varchar(10),
	appliedDiscount decimal(5,2)
);


CREATE TABLE MonthlyMetroCard (
    cardNumber varchar(10) PRIMARY KEY,
    clientID varchar(10) not null, 
    isActive INT,                     -- 0 = inactive, 1 = active
    paymentStatus VARCHAR(50),        -- Paid or Unpaid (prepaid for the current month)
    creationDate DATE,                -- Date when the card was issued
    expirationDate DATE,              -- Expiration date of the card
    FOREIGN KEY (clientID) REFERENCES Clients(ClientID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE MonthlyRecharges (
    rechargeID INT PRIMARY KEY IDENTITY,
    cardNumber varchar(10),
    amount DECIMAL(5, 2),
    rechargeDate DATE,
    FOREIGN KEY (cardNumber) REFERENCES MonthlyMetroCard(cardNumber) on delete cascade
);


CREATE TABLE MultiEntryMetroCard (
    cardNumber varchar(10) PRIMARY KEY,
    clientID varchar(10), 
    balance DECIMAL(5, 2),           -- Balance available on the card
    FOREIGN KEY (clientID) REFERENCES Clients(ClientID) ON DELETE CASCADE 
);


CREATE TABLE MultiEntryCardUsage (
    usageID INT PRIMARY KEY IDENTITY,
    cardNumber varchar(10),
    usageDate DATE,
    FOREIGN KEY (cardNumber) REFERENCES MultiEntryMetroCard(cardNumber) on delete cascade
);


CREATE TABLE MultiEntryRecharges (
    rechargeID INT PRIMARY KEY IDENTITY, -- Unique ID for each recharge
    cardNumber VARCHAR(10),              -- Multi-entry card being recharged
    amount DECIMAL(5, 2),                -- Amount added to the card
    rechargeDate DATE,                   -- Date of the recharge
	FOREIGN KEY (cardNumber) REFERENCES MultiEntryMetroCard(cardNumber) ON DELETE CASCADE ON UPDATE CASCADE)
);


delete from Clients where ClientID = 'C003'
INSERT INTO Clients (ClientID, Name, DateOfBirth, Address, Email, Phone, ZoneCode, familyType, cardType)
VALUES 
    ('C003', 'Jon Snyder', '1990-05-15', '123 Main St, Madrid', 'john.doe@example.com', '123-456-7890', 'B2', 'Big Family Normal', 'Monthly');

insert into zonePrices
values
	('A', 54.60),
	('B1', 63.70),
	('B2', 72.00),
	('B3', 82.00),
	('C1', 89.50),
	('C2', 99.30),
	('E1', 110.60),
	('E2', 131.80),
	('J', 20.00),
	('M', 6.30),
	('S', 10.00)

insert into discounts
values
	('BFN', .20),
	('BFS', .40),
	('DS', .65),
	('NA', 0)

delete from MonthlyMetroCard where cardNumber = '001'
insert into MonthlyMetroCard
values
	('001', 'C003', 1, 'paid','1990-05-15', NULL)

delete from MonthlyRecharges where cardNumber = '001'
insert into MonthlyRecharges(cardNumber, rechargeDate)
values
	('001', '1990-06-14')

insert into MultiEntryMetroCard
values
	('001', 'C003', 12)

insert into MultiEntryCardUsage
values
	('001', '1990-07-14')

insert into MultiEntryRecharges
values
	('001', 5, '1990-09-12')

select * from zonePrices
select * from discounts
select * from Clients
select * from MonthlyMetroCard
select * from MonthlyRecharges
select * from MultiEntryMetroCard
select * from MultiEntryCardUsage
select * from MultiEntryRecharges

