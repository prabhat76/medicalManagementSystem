-- ================================================
-- Medical Web Application - Data Manipulation Scripts
-- CRUD Operations for Patients and Appointments
-- ================================================

-- ============================================
-- PATIENT MANAGEMENT OPERATIONS
-- ============================================

-- 1. CREATE - Add a new patient
INSERT INTO "Patients" (
    "FirstName", "LastName", "DateOfBirth", "Email", 
    "PhoneNumber", "Address", "MedicalHistory"
) VALUES (
    'Michael', 'Wilson', '1985-03-10', 'michael.wilson@email.com',
    '(555) 789-0123', '321 Elm Street, Springfield, IL 62701',
    'History of hypertension. Currently on medication.'
);

-- 2. READ - Get patient by ID
SELECT * FROM "Patients" WHERE "Id" = 1;

-- 3. READ - Get all patients with their latest appointment
SELECT 
    p.*,
    a."AppointmentDateTime" AS "LastAppointment",
    a."DoctorName" AS "LastDoctor"
FROM "Patients" p
LEFT JOIN (
    SELECT 
        "PatientId",
        "AppointmentDateTime",
        "DoctorName",
        ROW_NUMBER() OVER (PARTITION BY "PatientId" ORDER BY "AppointmentDateTime" DESC) as rn
    FROM "Appointments"
) a ON p."Id" = a."PatientId" AND a.rn = 1;

-- 4. UPDATE - Update patient information
UPDATE "Patients" 
SET 
    "PhoneNumber" = '(555) 123-9999',
    "Address" = '123 Updated Street, New City, NY 10001',
    "MedicalHistory" = 'No known allergies. Previous surgery: Appendectomy (2010). Added annual checkup notes.'
WHERE "Id" = 1;

-- 5. DELETE - Remove a patient (will cascade delete appointments)
-- DELETE FROM "Patients" WHERE "Id" = 999;

-- ============================================
-- APPOINTMENT MANAGEMENT OPERATIONS  
-- ============================================

-- 1. CREATE - Schedule a new appointment
INSERT INTO "Appointments" (
    "PatientId", "DoctorName", "AppointmentDateTime", 
    "Reason", "Status", "Notes"
) VALUES (
    1, 'Dr. Jennifer Martinez', '2025-09-25 09:30:00',
    'Follow-up consultation', 'Scheduled',
    'Patient requested morning appointment'
);

-- 2. READ - Get appointment with patient details
SELECT 
    a."Id" as "AppointmentId",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    p."Email",
    p."PhoneNumber",
    a."DoctorName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status",
    a."Notes"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE a."Id" = 1;

-- 3. UPDATE - Update appointment status and notes
UPDATE "Appointments" 
SET 
    "Status" = 'Completed',
    "Notes" = 'Patient completed checkup. All vitals normal. Next appointment in 6 months.'
WHERE "Id" = 1;

-- 4. UPDATE - Reschedule appointment
UPDATE "Appointments"
SET 
    "AppointmentDateTime" = '2025-09-30 14:00:00',
    "Notes" = 'Rescheduled per patient request - original date conflicts'
WHERE "Id" = 2;

-- 5. DELETE - Cancel an appointment
-- DELETE FROM "Appointments" WHERE "Id" = 999;

-- ============================================
-- SEARCH AND FILTER OPERATIONS
-- ============================================

-- Search patients by name (case-insensitive)
SELECT 
    "Id",
    "FirstName" || ' ' || "LastName" AS "FullName",
    "Email",
    "PhoneNumber",
    "RegistrationDate"
FROM "Patients"
WHERE LOWER("FirstName" || ' ' || "LastName") LIKE LOWER('%john%')
ORDER BY "LastName", "FirstName";

-- Search patients by email domain
SELECT 
    "FirstName" || ' ' || "LastName" AS "FullName",
    "Email"
FROM "Patients"
WHERE "Email" LIKE '%@email.com'
ORDER BY "Email";

-- Find appointments by date range
SELECT 
    a."Id",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    a."DoctorName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE "AppointmentDateTime" BETWEEN '2025-09-01' AND '2025-09-30'
ORDER BY "AppointmentDateTime";

-- Find appointments by doctor
SELECT 
    a."Id",
    p."FirstName" || ' ' || p."LastName" AS "PatientName",
    a."AppointmentDateTime",
    a."Reason",
    a."Status"
FROM "Appointments" a
INNER JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE a."DoctorName" = 'Dr. Sarah Wilson'
ORDER BY a."AppointmentDateTime";

-- Find patients with specific medical conditions
SELECT 
    "FirstName" || ' ' || "LastName" AS "FullName",
    "Email",
    "MedicalHistory"
FROM "Patients"
WHERE LOWER("MedicalHistory") LIKE '%diabetes%' 
   OR LOWER("MedicalHistory") LIKE '%diabetic%'
ORDER BY "LastName";

-- ============================================
-- REPORTING QUERIES
-- ============================================

-- 1. Monthly patient registration report
SELECT 
    strftime('%Y-%m', "RegistrationDate") AS "Month",
    COUNT(*) AS "NewPatients",
    GROUP_CONCAT("FirstName" || ' ' || "LastName", ', ') AS "PatientNames"
FROM "Patients"
GROUP BY strftime('%Y-%m', "RegistrationDate")
ORDER BY "Month" DESC;

-- 2. Doctor appointment workload
SELECT 
    "DoctorName",
    COUNT(*) AS "TotalAppointments",
    COUNT(CASE WHEN "Status" = 'Scheduled' THEN 1 END) AS "ScheduledCount",
    COUNT(CASE WHEN "Status" = 'Completed' THEN 1 END) AS "CompletedCount",
    COUNT(CASE WHEN "Status" = 'Cancelled' THEN 1 END) AS "CancelledCount"
FROM "Appointments"
GROUP BY "DoctorName"
ORDER BY "TotalAppointments" DESC;

-- 3. Daily appointment schedule
SELECT 
    DATE("AppointmentDateTime") AS "Date",
    COUNT(*) AS "TotalAppointments",
    GROUP_CONCAT(
        TIME("AppointmentDateTime") || ' - ' || 
        "DoctorName" || ' with ' || 
        (SELECT p."FirstName" || ' ' || p."LastName" 
         FROM "Patients" p WHERE p."Id" = a."PatientId"), 
        ' | '
    ) AS "Schedule"
FROM "Appointments" a
WHERE "AppointmentDateTime" >= date('now')
  AND "Status" = 'Scheduled'
GROUP BY DATE("AppointmentDateTime")
ORDER BY "Date"
LIMIT 7;

-- 4. Patient age distribution
SELECT 
    CASE 
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 18 THEN 'Under 18'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 30 THEN '18-29'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 50 THEN '30-49'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 65 THEN '50-64'
        ELSE '65+'
    END AS "AgeGroup",
    COUNT(*) AS "PatientCount"
FROM "Patients"
GROUP BY 
    CASE 
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 18 THEN 'Under 18'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 30 THEN '18-29'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 50 THEN '30-49'
        WHEN (julianday('now') - julianday("DateOfBirth")) / 365.25 < 65 THEN '50-64'
        ELSE '65+'
    END
ORDER BY 
    CASE 
        WHEN "AgeGroup" = 'Under 18' THEN 1
        WHEN "AgeGroup" = '18-29' THEN 2
        WHEN "AgeGroup" = '30-49' THEN 3
        WHEN "AgeGroup" = '50-64' THEN 4
        ELSE 5
    END;

-- ============================================
-- DATA VALIDATION QUERIES
-- ============================================

-- Check for duplicate emails
SELECT 
    "Email",
    COUNT(*) AS "DuplicateCount",
    GROUP_CONCAT("FirstName" || ' ' || "LastName") AS "PatientNames"
FROM "Patients"
GROUP BY "Email"
HAVING COUNT(*) > 1;

-- Check for patients without appointments
SELECT 
    p."Id",
    p."FirstName" || ' ' || p."LastName" AS "FullName",
    p."Email",
    p."RegistrationDate"
FROM "Patients" p
LEFT JOIN "Appointments" a ON p."Id" = a."PatientId"
WHERE a."PatientId" IS NULL
ORDER BY p."RegistrationDate" DESC;

-- Check for appointments with invalid patient references
SELECT 
    a."Id" AS "AppointmentId",
    a."PatientId",
    a."DoctorName",
    a."AppointmentDateTime"
FROM "Appointments" a
LEFT JOIN "Patients" p ON a."PatientId" = p."Id"
WHERE p."Id" IS NULL;

-- ============================================
-- UTILITY PROCEDURES
-- ============================================

-- Calculate patient age
SELECT 
    "Id",
    "FirstName" || ' ' || "LastName" AS "FullName",
    "DateOfBirth",
    CAST((julianday('now') - julianday("DateOfBirth")) / 365.25 AS INTEGER) AS "Age"
FROM "Patients"
ORDER BY "Age" DESC;

-- Get next available appointment ID
SELECT COALESCE(MAX("Id"), 0) + 1 AS "NextAppointmentId" FROM "Appointments";

-- Get next available patient ID  
SELECT COALESCE(MAX("Id"), 0) + 1 AS "NextPatientId" FROM "Patients";

-- ============================================
-- BULK OPERATIONS
-- ============================================

-- Insert multiple patients at once
INSERT INTO "Patients" ("FirstName", "LastName", "DateOfBirth", "Email", "PhoneNumber", "Address", "MedicalHistory")
VALUES 
    ('Alice', 'Brown', '1992-07-18', 'alice.brown@email.com', '(555) 111-2222', '111 First St, City A, ST 11111', 'No medical history'),
    ('Charlie', 'Davis', '1988-11-25', 'charlie.davis@email.com', '(555) 333-4444', '222 Second Ave, City B, ST 22222', 'Allergic to shellfish'),
    ('Diana', 'Miller', '1995-01-30', 'diana.miller@email.com', '(555) 555-6666', '333 Third Blvd, City C, ST 33333', 'Previous broken arm in 2020');

-- Update multiple appointment statuses
UPDATE "Appointments" 
SET "Status" = 'Confirmed'
WHERE "AppointmentDateTime" > datetime('now')
  AND "Status" = 'Scheduled'
  AND "AppointmentDateTime" < datetime('now', '+7 days');

-- ============================================
-- CLEANUP AND MAINTENANCE
-- ============================================

-- Archive old completed appointments (move to archive table - would need to create archive table first)
-- CREATE TABLE "AppointmentsArchive" AS SELECT * FROM "Appointments" WHERE 1=0;

-- Clean up old cancelled appointments
DELETE FROM "Appointments" 
WHERE "Status" = 'Cancelled' 
  AND "AppointmentDateTime" < datetime('now', '-90 days');

-- Reset auto-increment counters (SQLite specific)
-- DELETE FROM sqlite_sequence WHERE name='Patients';
-- DELETE FROM sqlite_sequence WHERE name='Appointments';
