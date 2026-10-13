# SkyReserve — Airline Reservation & Flight Operations Database System

An interactive full-stack database application designed to manage core airline operations: flight scheduling, aircraft fleet management, passenger reservations with multivalued contact attributes, seat allocation with concurrency control, weak-entity baggage tracking, crew rostering with overlap prevention, and operational reporting.

---

## 🚀 Quick Start

### 1. Requirements
- Python 3.10+ (tested on Python 3.14)
- Flask (`pip install flask`)

### 2. Run the Application
- **Option A (Windows Batch One-Click)**: Double-click **`start.bat`** in Windows Explorer. It automatically detects Python, starts the Flask server, and launches your default web browser directly to `http://localhost:5000`.
- **Option B (Bash / Linux / macOS / Git Bash)**:
  ```bash
  bash start.sh
  # Or make executable and run:
  chmod +x start.sh && ./start.sh
  ```
- **Option C (Standard Command Line)**:
  ```bash
  python app.py
  ```
  Then open: **`http://localhost:5000`**

### 3. Run Automated Verification Test Suite
```bash
python test_suite.py
```

---

## 🗄️ Relational Database Architecture

The application is backed by SQLite with strict `PRAGMA foreign_keys = ON;`.

### 1. Entity Overview & Normalization

| Entity / Table | Primary Key | Description & Normalization Notes |
|---|---|---|
| **`Aircraft`** | `Aircraft_ID` | Fleet inventory (Boeing 787, A320, etc.), total capacity & seat class distribution. |
| **`Flight`** | `Flight_No` | Route definitions (`Source` & `Destination`, e.g., DEL → BOM). |
| **`Flight_Schedule`** | `Schedule_ID` | Specific temporal occurrences of flights. Enforces `UNIQUE(Aircraft_ID, Date, Departure_Time)` to prevent aircraft double-booking. |
| **`Passenger`** | `Passenger_ID` | Passenger demographic & passport records. |
| **`Passenger_Phone`** | `Phone_ID` (FK `Passenger_ID`) | **1NF Normalization:** Resolves multivalued phone numbers into a separate 1:N table. |
| **`Booking`** | `Booking_ID` (FK `Passenger_ID`, FK `Schedule_ID`) | Resolves M:N relationship between passenger and flight schedule. Tracks seat assignment, class, fare, and lifecycle status (`Confirmed`, `Checked-In`, `Cancelled`). |
| **`Baggage`** | `(Booking_ID, Baggage_Seq_No)` | **Weak Entity:** Composite primary key. Cannot exist independently of a `Booking`. Enforces `ON DELETE CASCADE`. |
| **`Crew`** | `Crew_ID` | Pilots, flight engineers, and cabin staff with license numbers. |
| **`Crew_Assignment`** | `Assignment_ID` (FK `Crew_ID`, FK `Schedule_ID`) | Resolves M:N relationship between crew members and flight schedules. |
| **`Booking_Audit`** | `Audit_ID` | Automated audit trail logging timestamp, user, previous state, and new state. |

---

### 2. Derived View: `Available_Seats` (FR10)

Calculated on-the-fly rather than redundantly stored:
```sql
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
```

---

### 3. Database Triggers

1. **`prevent_seat_double_booking` (BEFORE INSERT)**:
   Rejects duplicate bookings on the same `(Schedule_ID, Seat_No)` for active bookings using `RAISE(ABORT, 'Seat already booked for this schedule')`.
2. **`prevent_seat_double_booking_update` (BEFORE UPDATE)**:
   Guarantees seat conflict checks when seat assignments are modified.
3. **`booking_after_insert` (AFTER INSERT)**:
   Automatically writes an immutable audit record with JSON payload to `Booking_Audit`.
4. **`booking_after_update` (AFTER UPDATE)**:
   Captures delta between old values and new values for changes/cancellations.

---

## 🎯 Requirements Mapping Matrix

| Requirement | Implementation Detail | Location |
|---|---|---|
| **FR1, FR2, FR3** | Flight CRUD, departure/arrival schedules, date/source/destination search & available seats | `/flights`, `/schedules`, `/api/search_flights` |
| **FR4, FR5** | Aircraft fleet management, seating class configuration, overlap prevention | `/aircraft`, `Aircraft_Schedule` unique index |
| **FR6** | Passenger registration with dynamic multivalued phone numbers (1NF) | `/passengers`, `templates/passenger_form.html` |
| **FR7, FR8** | Reservation linking passenger to schedule, seat assignment with real-time API validation | `/bookings/add`, `/api/available_seats/<id>` |
| **FR9, FR10** | Cancellation workflow, auto-recalculation of available seats, refund status tracking | `/bookings/<id>/cancel`, `Available_Seats` view |
| **FR11, FR12** | Baggage weak entity with composite PK, weight limits, excess weight flag (>23kg) | `/bookings/<id>/baggage/add`, `Baggage` table |
| **FR13, FR14** | Crew scheduling, roster management, temporal overlap prevention | `/crew`, `/assignments/add` |
| **FR15-FR18** | Interactive front-end CRUD interfaces, visual indicators, Chart.js analytics | All templates in `/templates` |
| **Flight Search & Booking** | Search by origin, destination, date; live seat counts; instant reservation modal | `/book-flight`, `/book-flight/confirm` |
| **India Flight Map** | Interactive Leaflet.js radar map with curved air corridors, airport hubs, live seats | `/flight-map`, `/api/flight_map_data` |
| **Project Guide & Docs** | Comprehensive technical report: Normalization proofs (1NF-BCNF), DDL schemas, Triggers | `/project-guide` |
| **Top Menu Navigation** | Full horizontal top navigation bar replacing vertical sidebar layout | `templates/base.html` |
| **Manual Data Input** | Manual ID & FK override across all 8 categories, Dual-mode inputs, Quick Modals | `/manual-entry`, Quick modals on all list pages |
| **Direct SQL & Bulk JSON** | Live interactive SQL console with tabular results & Bulk JSON batch insert | `/manual-entry/raw-sql`, `/manual-entry/bulk-json` |
| **Baggage Management** | Standalone weak-entity baggage listing, direct filtering, and manual baggage entry | `/baggage`, `/baggage/add` |

---

## ✍️ Manual Data Input & Direct Data Management

SkyReserve provides full manual data entry flexibility across every operational category:

1. **Dual-Mode Data Entry on Every Entity**:
   - **Flights**: Enter custom flight numbers (`AI-101`, `6E-404`) or auto-assign.
   - **Schedules**: Enter custom `Schedule_ID`, or type custom `Flight_No` / `Aircraft_ID` directly or pick from dropdowns.
   - **Aircraft**: Enter custom `Aircraft_ID` or let auto-increment handle it.
   - **Passengers**: Enter custom `Passenger_ID`, passport number, and manual contact phone numbers.
   - **Bookings**: Enter custom `Booking_ID`, manual passenger ID, manual schedule ID, and seat selection.
   - **Baggage**: Standalone weak-entity management at `/baggage` and `/baggage/add` with manual `Booking_ID` and `Baggage_Seq_No`.
   - **Crew & Assignments**: Enter custom `Crew_ID`, `Assignment_ID`, or manually type crew and schedule identifiers.

2. **Quick Manual Input Modals**:
   - Every entity directory page has a **"Manual Input"** button that pops up an immediate modal dialog to enter records without leaving the page.

3. **Centralized Manual Data Input Hub (`/manual-entry`)**:
   - 10-tab interface grouping all 8 database entities.
   - Live schema guides displaying column types, constraints, and sample values.
   - **Direct SQL Console**: Execute arbitrary queries and DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) with results formatted in responsive tables.
   - **Bulk JSON Importer**: Paste JSON arrays with multiple entities for one-click batch ingestion.

---

## 📂 Project Structure

```
d:\Study Mat\dbms project\
├── airline.db             # SQLite database instance with pre-seeded data
├── schema.sql             # Full DDL schema (Tables, Foreign Keys, Views, Triggers)
├── seed_data.sql          # Seed data (Aircraft, Flights, Schedules, Passengers, Bookings, Crew)
├── database.py            # SQLite connection helper & initialization script
├── app.py                 # Flask server with REST endpoints & full CRUD handlers
├── test_suite.py          # Automated test verification suite
├── start.bat              # One-click Windows desktop startup launcher
├── README.md              # Project documentation
└── templates/             # 29 interactive Jinja2 HTML templates
    ├── base.html          # Top navigation menu bar with sleek dark theme
    ├── dashboard.html     # KPI summary cards, flight search hero & upcoming flights
    ├── book_flight.html   # Flight search by Source, Destination, Date & booking modal
    ├── flight_map.html    # Interactive Leaflet.js Indian Air Network Map
    ├── project_guide.html # Detailed technical report & DBMS architecture guide
    ├── flights.html       # Flight routes listing & quick manual input modal
    ├── flight_form.html   # Flight add/edit form
    ├── schedules.html     # Schedules with live available seat counts & modal
    ├── schedule_form.html # Schedule form with dual-mode dropdown/manual inputs
    ├── aircraft.html      # Aircraft fleet cards & quick manual input modal
    ├── aircraft_form.html # Aircraft add/edit form with manual ID override
    ├── passengers.html    # Passenger directory & quick manual input modal
    ├── passenger_form.html# Registration with dynamic multivalued phone numbers
    ├── passenger_detail.html # Passenger profile & booking history
    ├── bookings.html      # Reservations listing & quick manual input modal
    ├── booking_form.html  # Reservation form with AJAX seat checking & manual IDs
    ├── booking_detail.html# Reservation view with weak-entity baggage & audit log
    ├── booking_edit.html  # Seat/class modification form
    ├── baggage.html       # Standalone baggage directory & quick manual modal
    ├── baggage_form.html  # Baggage registration form inside booking view
    ├── baggage_standalone_form.html # Standalone baggage entry form with manual IDs
    ├── crew.html          # Crew roster & quick manual input modal
    ├── crew_form.html     # Crew member registration & manual ID override
    ├── crew_detail.html   # Crew profile & assigned schedules
    ├── assignments.html   # Crew flight assignments & quick manual modal
    ├── assignment_form.html # Crew assignment form with dual-mode manual inputs
    ├── manual_entry.html  # Centralized 10-tab Manual Data Input Hub
    ├── manual_sql_result.html # Tabular results display for raw SQL console
    └── reports.html       # Chart.js analytics, revenue breakdown & audit logs
```
