-- ================================================
-- Database Management and Maintenance Scripts
-- For Medical Web Application SQLite Database
-- ================================================

-- ============================================
-- 1. DATABASE INFORMATION
-- ============================================

-- Show database schema information
.schema

-- Show all tables
.tables

-- Show database file info
.dbinfo

-- ============================================
-- 2. DATA VERIFICATION QUERIES
-- ============================================

-- Count records in each table
SELECT 'Patients' AS TableName, COUNT(*) AS RecordCount FROM Patients
UNION ALL
SELECT 'Appointments' AS TableName, COUNT(*) AS RecordCount FROM Appointments;

-- Show sample data from each table
SELECT 'PATIENTS TABLE:' AS Info;
SELECT Id, FirstName || ' ' || LastName AS FullName, Email, RegistrationDate 
FROM Patients 
ORDER BY Id;

SELECT 'APPOINTMENTS TABLE:' AS Info;
SELECT 
    a.Id,
    p.FirstName || ' ' || p.LastName AS PatientName,
    a.DoctorName,
    a.AppointmentDateTime,
    a.Status
FROM Appointments a
JOIN Patients p ON a.PatientId = p.Id
ORDER BY a.AppointmentDateTime;

-- ============================================
-- 3. DATA INTEGRITY CHECKS
-- ============================================

-- Check for orphaned appointments (should be none due to foreign key)
SELECT 'Orphaned Appointments Check:' AS Check;
SELECT COUNT(*) AS OrphanedCount
FROM Appointments a
LEFT JOIN Patients p ON a.PatientId = p.Id
WHERE p.Id IS NULL;

-- Check for duplicate emails
SELECT 'Duplicate Email Check:' AS Check;
SELECT Email, COUNT(*) as Count
FROM Patients
GROUP BY Email
HAVING COUNT(*) > 1;

-- Check appointment date consistency
SELECT 'Future Appointments Check:' AS Check;
SELECT COUNT(*) AS FutureAppointments
FROM Appointments
WHERE AppointmentDateTime > datetime('now')
  AND Status = 'Scheduled';

-- ============================================
-- 4. PERFORMANCE ANALYSIS
-- ============================================

-- Show index information
.indexes

-- Analyze query performance (SQLite specific)
EXPLAIN QUERY PLAN 
SELECT p.FirstName, p.LastName, a.AppointmentDateTime
FROM Patients p
JOIN Appointments a ON p.Id = a.PatientId
WHERE p.Email = 'john.doe@email.com';

-- ============================================
-- 5. BACKUP AND RESTORE
-- ============================================

-- Export data to CSV files (run these commands in SQLite CLI)
/*
.mode csv
.headers on
.output patients_backup.csv
SELECT * FROM Patients;
.output appointments_backup.csv
SELECT * FROM Appointments;
.output off
*/

-- Create a complete backup script
SELECT '-- Full database backup generated on: ' || datetime('now') AS BackupInfo;

SELECT 'INSERT INTO Patients VALUES(' ||
       Id || ', ''' || 
       replace(FirstName, '''', '''''') || ''', ''' ||
       replace(LastName, '''', '''''') || ''', ''' ||
       DateOfBirth || ''', ''' ||
       replace(PhoneNumber, '''', '''''') || ''', ''' ||
       replace(Email, '''', '''''') || ''', ''' ||
       replace(Address, '''', '''''') || ''', ''' ||
       replace(coalesce(MedicalHistory, ''), '''', '''''') || ''', ''' ||
       RegistrationDate || ''');'
FROM Patients;

-- ============================================
-- 6. DATABASE MAINTENANCE
-- ============================================

-- Vacuum database to reclaim space
VACUUM;

-- Analyze database for query optimization
ANALYZE;

-- Update statistics
UPDATE sqlite_stat1 SET stat = NULL;
ANALYZE;

-- Check database integrity
PRAGMA integrity_check;

-- Show database configuration
PRAGMA compile_options;

-- ============================================
-- 7. TROUBLESHOOTING QUERIES
-- ============================================

-- Show foreign key violations (if any)
PRAGMA foreign_key_check;

-- Show unused space
PRAGMA freelist_count;

-- Show page count and size
PRAGMA page_count;
PRAGMA page_size;

-- ============================================
-- 8. DEVELOPMENT HELPERS
-- ============================================

-- Reset auto-increment counters (use with caution)
-- DELETE FROM sqlite_sequence WHERE name='Patients';
-- DELETE FROM sqlite_sequence WHERE name='Appointments';

-- Add a test patient for development
INSERT INTO Patients (FirstName, LastName, DateOfBirth, Email, PhoneNumber, Address, MedicalHistory)
VALUES ('Test', 'Patient', '1990-01-01', 'test@example.com', '(555) 000-0000', '123 Test St, Test City, TS 12345', 'Test data for development');

-- Add a test appointment
INSERT INTO Appointments (PatientId, DoctorName, AppointmentDateTime, Reason, Status, Notes)
SELECT 
    Id, 
    'Dr. Test Doctor', 
    datetime('now', '+7 days'), 
    'Test appointment', 
    'Scheduled', 
    'This is test data'
FROM Patients 
WHERE Email = 'test@example.com';

-- ============================================
-- 9. REPORTING HELPERS
-- ============================================

-- Generate appointment summary report
SELECT 
    date(AppointmentDateTime) as AppointmentDate,
    COUNT(*) as TotalAppointments,
    COUNT(CASE WHEN Status = 'Scheduled' THEN 1 END) as Scheduled,
    COUNT(CASE WHEN Status = 'Completed' THEN 1 END) as Completed
FROM Appointments
WHERE AppointmentDateTime >= date('now', '-30 days')
GROUP BY date(AppointmentDateTime)
ORDER BY AppointmentDate;

-- Patient registration trend
SELECT 
    strftime('%Y-%m', RegistrationDate) as Month,
    COUNT(*) as NewPatients
FROM Patients
GROUP BY strftime('%Y-%m', RegistrationDate)
ORDER BY Month DESC
LIMIT 12;

-- ============================================
-- 10. USEFUL QUERIES FOR WEB APPLICATION
-- ============================================

-- Get patient with their latest appointment
SELECT 
    p.Id,
    p.FirstName || ' ' || p.LastName as FullName,
    p.Email,
    p.PhoneNumber,
    COALESCE(latest.AppointmentDateTime, 'No appointments') as LastAppointment
FROM Patients p
LEFT JOIN (
    SELECT 
        PatientId,
        AppointmentDateTime,
        ROW_NUMBER() OVER (PARTITION BY PatientId ORDER BY AppointmentDateTime DESC) as rn
    FROM Appointments
) latest ON p.Id = latest.PatientId AND latest.rn = 1;

-- Search patients (useful for autocomplete)
-- Replace 'searchterm' with actual search term
SELECT 
    Id,
    FirstName || ' ' || LastName as FullName,
    Email
FROM Patients
WHERE LOWER(FirstName || ' ' || LastName) LIKE LOWER('%searchterm%')
   OR LOWER(Email) LIKE LOWER('%searchterm%')
ORDER BY LastName, FirstName;

-- Today's appointment schedule
SELECT 
    p.FirstName || ' ' || p.LastName as PatientName,
    a.DoctorName,
    time(a.AppointmentDateTime) as Time,
    a.Reason,
    a.Status
FROM Appointments a
JOIN Patients p ON a.PatientId = p.Id
WHERE date(a.AppointmentDateTime) = date('now')
ORDER BY a.AppointmentDateTime;
