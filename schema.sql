PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS Booking_Audit;
DROP TABLE IF EXISTS Crew_Assignment;
DROP TABLE IF EXISTS Crew;
DROP TABLE IF EXISTS Baggage;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Passenger_Phone;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Flight_Schedule;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Aircraft;
DROP VIEW IF EXISTS Available_Seats;

CREATE TABLE Aircraft (
    Aircraft_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Registration_No TEXT UNIQUE NOT NULL,
    Model TEXT NOT NULL,
    Total_Capacity INTEGER NOT NULL CHECK (Total_Capacity > 0),
    Economy_Seats INTEGER NOT NULL DEFAULT 0,
    Business_Seats INTEGER NOT NULL DEFAULT 0,
    First_Class_Seats INTEGER NOT NULL DEFAULT 0,
    Status TEXT DEFAULT 'Active' CHECK (Status IN ('Active','Maintenance','Retired'))
);

CREATE TABLE Flight (
    Flight_No TEXT PRIMARY KEY,
    Airline TEXT NOT NULL,
    Source TEXT NOT NULL,
    Destination TEXT NOT NULL,
    CHECK (Source != Destination)
);

CREATE TABLE Flight_Schedule (
    Schedule_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Flight_No TEXT NOT NULL,
    Aircraft_ID INTEGER NOT NULL,
    Departure_Time TEXT NOT NULL,
    Arrival_Time TEXT NOT NULL,
    Date TEXT NOT NULL,
    Status TEXT DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled','On-Time','Delayed','Cancelled','Completed')),
    Gate TEXT,
    FOREIGN KEY (Flight_No) REFERENCES Flight(Flight_No) ON DELETE CASCADE,
    FOREIGN KEY (Aircraft_ID) REFERENCES Aircraft(Aircraft_ID),
    UNIQUE(Aircraft_ID, Date, Departure_Time)
);

CREATE TABLE Passenger (
    Passenger_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    First_Name TEXT NOT NULL,
    Last_Name TEXT NOT NULL,
    Email TEXT UNIQUE,
    Passport_No TEXT UNIQUE,
    Date_of_Birth TEXT,
    Gender TEXT CHECK (Gender IN ('Male','Female','Other')),
    Address TEXT,
    Created_At TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Passenger_Phone (
    Phone_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Passenger_ID INTEGER NOT NULL,
    Phone_Number TEXT NOT NULL,
    Phone_Type TEXT DEFAULT 'Mobile' CHECK (Phone_Type IN ('Mobile','Home','Work')),
    FOREIGN KEY (Passenger_ID) REFERENCES Passenger(Passenger_ID) ON DELETE CASCADE,
    UNIQUE(Passenger_ID, Phone_Number)
);

CREATE TABLE Booking (
    Booking_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Passenger_ID INTEGER NOT NULL,
    Schedule_ID INTEGER NOT NULL,
    Seat_No TEXT,
    Class TEXT NOT NULL CHECK (Class IN ('Economy','Business','First')),
    Fare REAL NOT NULL CHECK (Fare >= 0),
    Booking_Status TEXT DEFAULT 'Confirmed' CHECK (Booking_Status IN ('Confirmed','Cancelled','Checked-In','Completed')),
    Booking_Date TEXT DEFAULT CURRENT_TIMESTAMP,
    Cancellation_Date TEXT,
    Refund_Status TEXT CHECK (Refund_Status IN ('Pending','Processed','Denied') OR Refund_Status IS NULL),
    FOREIGN KEY (Passenger_ID) REFERENCES Passenger(Passenger_ID) ON DELETE CASCADE,
    FOREIGN KEY (Schedule_ID) REFERENCES Flight_Schedule(Schedule_ID) ON DELETE CASCADE
);

CREATE TABLE Baggage (
    Booking_ID INTEGER NOT NULL,
    Baggage_Seq_No INTEGER NOT NULL,
    Weight REAL NOT NULL CHECK (Weight > 0),
    Tag_No TEXT UNIQUE NOT NULL,
    Type TEXT DEFAULT 'Checked' CHECK (Type IN ('Checked','Cabin','Special')),
    PRIMARY KEY (Booking_ID, Baggage_Seq_No),
    FOREIGN KEY (Booking_ID) REFERENCES Booking(Booking_ID) ON DELETE CASCADE
);

CREATE TABLE Crew (
    Crew_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    First_Name TEXT NOT NULL,
    Last_Name TEXT NOT NULL,
    Role TEXT NOT NULL CHECK (Role IN ('Captain','First Officer','Flight Engineer','Cabin Crew Lead','Cabin Crew')),
    License_No TEXT UNIQUE,
    Phone TEXT,
    Email TEXT UNIQUE,
    Status TEXT DEFAULT 'Active' CHECK (Status IN ('Active','On Leave','Retired'))
);

CREATE TABLE Crew_Assignment (
    Assignment_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Crew_ID INTEGER NOT NULL,
    Schedule_ID INTEGER NOT NULL,
    FOREIGN KEY (Crew_ID) REFERENCES Crew(Crew_ID) ON DELETE CASCADE,
    FOREIGN KEY (Schedule_ID) REFERENCES Flight_Schedule(Schedule_ID) ON DELETE CASCADE,
    UNIQUE(Crew_ID, Schedule_ID)
);

CREATE TABLE Booking_Audit (
    Audit_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Booking_ID INTEGER,
    Action TEXT NOT NULL,
    Old_Values TEXT,
    New_Values TEXT,
    Changed_At TEXT DEFAULT CURRENT_TIMESTAMP,
    Changed_By TEXT DEFAULT 'system'
);

CREATE VIEW Available_Seats AS
SELECT 
  fs.Schedule_ID,
  f.Flight_No,
  f.Source,
  f.Destination,
  fs.Date,
  fs.Departure_Time,
  fs.Arrival_Time,
  a.Total_Capacity,
  a.Total_Capacity - COALESCE((
    SELECT COUNT(*) FROM Booking b 
    WHERE b.Schedule_ID = fs.Schedule_ID 
    AND b.Booking_Status NOT IN ('Cancelled')
  ), 0) AS Seats_Available,
  fs.Status
FROM Flight_Schedule fs
JOIN Flight f ON fs.Flight_No = f.Flight_No
JOIN Aircraft a ON fs.Aircraft_ID = a.Aircraft_ID;

CREATE TRIGGER booking_after_insert
AFTER INSERT ON Booking
BEGIN
    INSERT INTO Booking_Audit (Booking_ID, Action, New_Values)
    VALUES (NEW.Booking_ID, 'CREATED', json_object('Passenger_ID', NEW.Passenger_ID, 'Schedule_ID', NEW.Schedule_ID, 'Seat_No', NEW.Seat_No, 'Class', NEW.Class, 'Fare', NEW.Fare, 'Booking_Status', NEW.Booking_Status));
END;

CREATE TRIGGER booking_after_update
AFTER UPDATE ON Booking
BEGIN
    INSERT INTO Booking_Audit (Booking_ID, Action, Old_Values, New_Values)
    VALUES (
        NEW.Booking_ID, 
        'MODIFIED', 
        json_object('Seat_No', OLD.Seat_No, 'Class', OLD.Class, 'Booking_Status', OLD.Booking_Status, 'Refund_Status', OLD.Refund_Status),
        json_object('Seat_No', NEW.Seat_No, 'Class', NEW.Class, 'Booking_Status', NEW.Booking_Status, 'Refund_Status', NEW.Refund_Status)
    );
END;

CREATE TRIGGER prevent_seat_double_booking
BEFORE INSERT ON Booking
WHEN NEW.Seat_No IS NOT NULL AND NEW.Booking_Status IN ('Confirmed', 'Checked-In')
BEGIN
    SELECT RAISE(ABORT, 'Seat already booked for this schedule')
    WHERE EXISTS (
        SELECT 1 FROM Booking 
        WHERE Schedule_ID = NEW.Schedule_ID 
          AND Seat_No = NEW.Seat_No 
          AND Booking_Status IN ('Confirmed', 'Checked-In')
    );
END;

CREATE TRIGGER prevent_seat_double_booking_update
BEFORE UPDATE OF Seat_No ON Booking
WHEN NEW.Seat_No IS NOT NULL AND NEW.Booking_Status IN ('Confirmed', 'Checked-In')
BEGIN
    SELECT RAISE(ABORT, 'Seat already booked for this schedule')
    WHERE EXISTS (
        SELECT 1 FROM Booking 
        WHERE Schedule_ID = NEW.Schedule_ID 
          AND Seat_No = NEW.Seat_No 
          AND Booking_Status IN ('Confirmed', 'Checked-In')
          AND Booking_ID != NEW.Booking_ID
    );
END;
