-- ================================================
-- Medical Web Application Database Schema
-- Database: SQLite
-- Created: September 8, 2025
-- ================================================

-- ============================================
-- 1. DATABASE CREATION (SQLite specific)
-- ============================================
-- Note: SQLite database is created automatically when first accessed
-- Database file: MedicalApp.db

-- ============================================
-- 2. PATIENTS TABLE
-- ============================================
CREATE TABLE "Patients" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Patients" PRIMARY KEY AUTOINCREMENT,
    "FirstName" TEXT NOT NULL CONSTRAINT "CHK_FirstName" CHECK (LENGTH("FirstName") <= 100),
    "LastName" TEXT NOT NULL CONSTRAINT "CHK_LastName" CHECK (LENGTH("LastName") <= 100),
    "DateOfBirth" TEXT NOT NULL,
    "PhoneNumber" TEXT NOT NULL CONSTRAINT "CHK_PhoneNumber" CHECK (LENGTH("PhoneNumber") <= 20),
    "Email" TEXT NOT NULL CONSTRAINT "CHK_Email" CHECK (LENGTH("Email") <= 255),
    "Address" TEXT NOT NULL CONSTRAINT "CHK_Address" CHECK (LENGTH("Address") <= 500),
    "MedicalHistory" TEXT DEFAULT '' CONSTRAINT "CHK_MedicalHistory" CHECK (LENGTH("MedicalHistory") <= 2000),
    "RegistrationDate" TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================
-- 3. APPOINTMENTS TABLE
-- ============================================
CREATE TABLE "Appointments" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Appointments" PRIMARY KEY AUTOINCREMENT,
    "PatientId" INTEGER NOT NULL,
    "DoctorName" TEXT NOT NULL CONSTRAINT "CHK_DoctorName" CHECK (LENGTH("DoctorName") <= 100),
    "AppointmentDateTime" TEXT NOT NULL,
    "Reason" TEXT NOT NULL CONSTRAINT "CHK_Reason" CHECK (LENGTH("Reason") <= 500),
    "Status" TEXT NOT NULL DEFAULT 'Scheduled' CONSTRAINT "CHK_Status" CHECK (LENGTH("Status") <= 50),
    "Notes" TEXT DEFAULT '' CONSTRAINT "CHK_Notes" CHECK (LENGTH("Notes") <= 1000),
    "CreatedDate" TEXT NOT NULL DEFAULT (datetime('now')),
    CONSTRAINT "FK_Appointments_Patients_PatientId" 
        FOREIGN KEY ("PatientId") REFERENCES "Patients" ("Id") ON DELETE CASCADE
);

-- ============================================
-- 4. INDEXES FOR PERFORMANCE
-- ============================================

-- Unique index on patient email (prevents duplicate emails)
CREATE UNIQUE INDEX "IX_Patients_Email" ON "Patients" ("Email");

-- Index on patient names for faster searching
CREATE INDEX "IX_Patients_Name" ON "Patients" ("LastName", "FirstName");

-- Index on appointment patient ID (foreign key)
CREATE INDEX "IX_Appointments_PatientId" ON "Appointments" ("PatientId");

-- Index on appointment date for filtering by date
CREATE INDEX "IX_Appointments_DateTime" ON "Appointments" ("AppointmentDateTime");

-- Index on appointment status for filtering
CREATE INDEX "IX_Appointments_Status" ON "Appointments" ("Status");

-- ============================================
-- 5. VIEWS FOR COMMON QUERIES
-- ============================================

-- View combining patient and appointment information
CREATE VIEW "PatientAppointmentView" AS
SELECT 
    p."Id" AS "PatientId",
    p."FirstName",
    p."LastName",
    p."Email",
    p."PhoneNumber",
    a."Id" AS "AppointmentId",
    a."DoctorName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status",
    a."Notes"
FROM "Patients" p
LEFT JOIN "Appointments" a ON p."Id" = a."PatientId";

-- View for upcoming appointments
CREATE VIEW "UpcomingAppointments" AS
SELECT 
    a."Id",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    p."PhoneNumber",
    a."DoctorName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE a."AppointmentDateTime" >= datetime('now')
    AND a."Status" IN ('Scheduled', 'Confirmed')
ORDER BY a."AppointmentDateTime";

-- ============================================
-- 6. TRIGGERS FOR DATA INTEGRITY
-- ============================================

-- Trigger to validate email format
CREATE TRIGGER "validate_patient_email"
    BEFORE INSERT ON "Patients"
    FOR EACH ROW
    WHEN NEW."Email" NOT LIKE '%_@_%._%'
BEGIN
    SELECT RAISE(ABORT, 'Invalid email format');
END;

-- Trigger to prevent scheduling appointments in the past
CREATE TRIGGER "validate_appointment_datetime"
    BEFORE INSERT ON "Appointments"
    FOR EACH ROW
    WHEN NEW."AppointmentDateTime" < datetime('now')
BEGIN
    SELECT RAISE(ABORT, 'Cannot schedule appointments in the past');
END;

-- ============================================
-- 7. SAMPLE DATA INSERTION
-- ============================================

-- Insert sample patients
INSERT INTO "Patients" ("FirstName", "LastName", "DateOfBirth", "Email", "PhoneNumber", "Address", "MedicalHistory", "RegistrationDate")
VALUES 
    ('John', 'Doe', '1980-05-15', 'john.doe@email.com', '(555) 123-4567', '123 Main Street, Anytown, NY 12345', 'No known allergies. Previous surgery: Appendectomy (2010).', '2024-08-01 10:00:00'),
    ('Jane', 'Smith', '1975-08-22', 'jane.smith@email.com', '(555) 987-6543', '456 Oak Avenue, Somewhere, CA 90210', 'Allergic to penicillin. Diabetic (Type 2) since 2018.', '2024-08-15 14:30:00'),
    ('Bob', 'Johnson', '1990-12-03', 'bob.johnson@email.com', '(555) 555-1234', '789 Pine Road, Elsewhere, TX 75001', 'No known medical conditions.', '2024-09-01 09:15:00');

-- Insert sample appointments
INSERT INTO "Appointments" ("PatientId", "DoctorName", "AppointmentDateTime", "Reason", "Status", "Notes", "CreatedDate")
VALUES 
    (1, 'Dr. Sarah Wilson', '2025-09-15 10:00:00', 'Annual checkup and blood work', 'Scheduled', 'Fasting required for blood work', '2025-09-03 09:00:00'),
    (2, 'Dr. Michael Brown', '2025-09-11 14:00:00', 'Diabetes management consultation', 'Scheduled', 'Bring current glucose logs', '2025-09-06 16:00:00'),
    (3, 'Dr. Emily Davis', '2025-09-20 11:30:00', 'Routine physical examination', 'Scheduled', 'First visit - complete physical', '2025-09-07 10:30:00');

-- ============================================
-- 8. USEFUL QUERIES FOR MEDICAL APPLICATION
-- ============================================

-- Find all patients registered in the last 30 days
SELECT 
    "FirstName" || ' ' || "LastName" AS "FullName",
    "Email",
    "RegistrationDate"
FROM "Patients"
WHERE "RegistrationDate" >= datetime('now', '-30 days')
ORDER BY "RegistrationDate" DESC;

-- Get patient count by month
SELECT 
    strftime('%Y-%m', "RegistrationDate") AS "Month",
    COUNT(*) AS "PatientsRegistered"
FROM "Patients"
GROUP BY strftime('%Y-%m', "RegistrationDate")
ORDER BY "Month" DESC;

-- Find all appointments for a specific doctor
SELECT 
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE a."DoctorName" = 'Dr. Sarah Wilson'
ORDER BY a."AppointmentDateTime";

-- Get patients with upcoming appointments
SELECT DISTINCT
    p."Id",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    p."Email",
    p."PhoneNumber"
FROM "Patients" p
INNER JOIN "Appointments" a ON p."Id" = a."PatientId"
WHERE a."AppointmentDateTime" >= datetime('now')
    AND a."Status" = 'Scheduled';

-- Search patients by name or email
SELECT 
    "Id",
    "FirstName" || ' ' || "LastName" AS "FullName",
    "Email",
    "PhoneNumber"
FROM "Patients"
WHERE LOWER("FirstName") LIKE '%john%' 
   OR LOWER("LastName") LIKE '%john%'
   OR LOWER("Email") LIKE '%john%'
ORDER BY "LastName", "FirstName";

-- ============================================
-- 9. MAINTENANCE AND CLEANUP QUERIES
-- ============================================

-- Remove old completed appointments (older than 1 year)
DELETE FROM "Appointments"
WHERE "Status" = 'Completed' 
  AND "AppointmentDateTime" < datetime('now', '-1 year');

-- Update appointment status to 'Missed' for past appointments that are still 'Scheduled'
UPDATE "Appointments"
SET "Status" = 'Missed'
WHERE "AppointmentDateTime" < datetime('now')
  AND "Status" = 'Scheduled';

-- ============================================
-- 10. BACKUP AND EXPORT QUERIES
-- ============================================

-- Export all patient data
SELECT 
    "Id",
    "FirstName",
    "LastName",
    "DateOfBirth",
    "Email",
    "PhoneNumber",
    "Address",
    "MedicalHistory",
    "RegistrationDate"
FROM "Patients"
ORDER BY "Id";

-- Export all appointment data with patient names
SELECT 
    a."Id",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    a."DoctorName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status",
    a."Notes",
    a."CreatedDate"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
ORDER BY a."AppointmentDateTime" DESC;
