-- ================================================
-- Medical Web Application Database Schema - SQL Server Version
-- Database: SQL Server / Azure SQL Database
-- Created: September 8, 2025
-- ================================================

-- ============================================
-- 1. DATABASE CREATION (SQL Server)
-- ============================================
-- Note: Run this only if creating a new database
-- USE master;
-- CREATE DATABASE MedicalApp;
-- USE MedicalApp;

-- ============================================
-- 2. PATIENTS TABLE
-- ============================================
CREATE TABLE [dbo].[Patients] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [DateOfBirth] DATETIME2 NOT NULL,
    [PhoneNumber] NVARCHAR(20) NOT NULL,
    [Email] NVARCHAR(255) NOT NULL,
    [Address] NVARCHAR(500) NOT NULL,
    [MedicalHistory] NVARCHAR(2000) NULL,
    [RegistrationDate] DATETIME2 NOT NULL CONSTRAINT [DF_Patients_RegistrationDate] DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_Patients] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CK_Patients_Email] CHECK ([Email] LIKE '%_@_%._%')
);

-- ============================================
-- 3. APPOINTMENTS TABLE
-- ============================================
CREATE TABLE [dbo].[Appointments] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PatientId] INT NOT NULL,
    [DoctorName] NVARCHAR(100) NOT NULL,
    [AppointmentDateTime] DATETIME2 NOT NULL,
    [Reason] NVARCHAR(500) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Appointments_Status] DEFAULT ('Scheduled'),
    [Notes] NVARCHAR(1000) NULL,
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Appointments_CreatedDate] DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_Appointments] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Appointments_Patients] FOREIGN KEY ([PatientId]) REFERENCES [dbo].[Patients]([Id]) ON DELETE CASCADE,
    CONSTRAINT [CK_Appointments_Status] CHECK ([Status] IN ('Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-Show', 'Rescheduled')),
    CONSTRAINT [CK_Appointments_FutureDate] CHECK ([AppointmentDateTime] >= CAST(GETDATE() AS DATE))
);

-- ============================================
-- 4. INDEXES FOR PERFORMANCE
-- ============================================

-- Unique index on patient email
CREATE UNIQUE NONCLUSTERED INDEX [IX_Patients_Email] 
ON [dbo].[Patients] ([Email]);

-- Index on patient names for searching
CREATE NONCLUSTERED INDEX [IX_Patients_Name] 
ON [dbo].[Patients] ([LastName], [FirstName]);

-- Index on appointment patient ID (foreign key)
CREATE NONCLUSTERED INDEX [IX_Appointments_PatientId] 
ON [dbo].[Appointments] ([PatientId]);

-- Index on appointment date for filtering
CREATE NONCLUSTERED INDEX [IX_Appointments_DateTime] 
ON [dbo].[Appointments] ([AppointmentDateTime]);

-- Index on appointment status
CREATE NONCLUSTERED INDEX [IX_Appointments_Status] 
ON [dbo].[Appointments] ([Status]);

-- ============================================
-- 5. VIEWS FOR COMMON QUERIES
-- ============================================

-- View combining patient and appointment information
CREATE VIEW [dbo].[PatientAppointmentView] AS
SELECT 
    p.[Id] AS [PatientId],
    p.[FirstName],
    p.[LastName],
    p.[Email],
    p.[PhoneNumber],
    a.[Id] AS [AppointmentId],
    a.[DoctorName],
    a.[AppointmentDateTime],
    a.[Reason],
    a.[Status],
    a.[Notes]
FROM [dbo].[Patients] p
LEFT JOIN [dbo].[Appointments] a ON p.[Id] = a.[PatientId];

-- View for upcoming appointments
CREATE VIEW [dbo].[UpcomingAppointments] AS
SELECT 
    a.[Id],
    p.[FirstName] + ' ' + p.[LastName] AS [PatientName],
    p.[PhoneNumber],
    a.[DoctorName],
    a.[AppointmentDateTime],
    a.[Reason],
    a.[Status]
FROM [dbo].[Appointments] a
INNER JOIN [dbo].[Patients] p ON a.[PatientId] = p.[Id]
WHERE a.[AppointmentDateTime] >= GETDATE()
    AND a.[Status] IN ('Scheduled', 'Confirmed')
    AND a.[AppointmentDateTime] <= DATEADD(MONTH, 6, GETDATE());

-- ============================================
-- 6. STORED PROCEDURES
-- ============================================

-- Procedure to add a new patient
CREATE PROCEDURE [dbo].[sp_AddPatient]
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @DateOfBirth DATETIME2,
    @Email NVARCHAR(255),
    @PhoneNumber NVARCHAR(20),
    @Address NVARCHAR(500),
    @MedicalHistory NVARCHAR(2000) = NULL,
    @NewPatientId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[Patients] (
        [FirstName], [LastName], [DateOfBirth], [Email], 
        [PhoneNumber], [Address], [MedicalHistory]
    )
    VALUES (
        @FirstName, @LastName, @DateOfBirth, @Email,
        @PhoneNumber, @Address, @MedicalHistory
    );
    
    SET @NewPatientId = SCOPE_IDENTITY();
    
    SELECT @NewPatientId AS [NewPatientId];
END;

-- Procedure to schedule an appointment
CREATE PROCEDURE [dbo].[sp_ScheduleAppointment]
    @PatientId INT,
    @DoctorName NVARCHAR(100),
    @AppointmentDateTime DATETIME2,
    @Reason NVARCHAR(500),
    @Notes NVARCHAR(1000) = NULL,
    @NewAppointmentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if patient exists
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Patients] WHERE [Id] = @PatientId)
    BEGIN
        THROW 50001, 'Patient does not exist', 1;
    END
    
    -- Check if appointment time is in the future
    IF @AppointmentDateTime <= GETDATE()
    BEGIN
        THROW 50002, 'Appointment must be scheduled for a future date', 1;
    END
    
    INSERT INTO [dbo].[Appointments] (
        [PatientId], [DoctorName], [AppointmentDateTime], 
        [Reason], [Notes]
    )
    VALUES (
        @PatientId, @DoctorName, @AppointmentDateTime,
        @Reason, @Notes
    );
    
    SET @NewAppointmentId = SCOPE_IDENTITY();
    
    SELECT @NewAppointmentId AS [NewAppointmentId];
END;

-- Procedure to search patients
CREATE PROCEDURE [dbo].[sp_SearchPatients]
    @SearchTerm NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        [Id],
        [FirstName] + ' ' + [LastName] AS [FullName],
        [Email],
        [PhoneNumber],
        [RegistrationDate]
    FROM [dbo].[Patients]
    WHERE LOWER([FirstName]) LIKE '%' + LOWER(@SearchTerm) + '%'
       OR LOWER([LastName]) LIKE '%' + LOWER(@SearchTerm) + '%'
       OR LOWER([Email]) LIKE '%' + LOWER(@SearchTerm) + '%'
       OR [PhoneNumber] LIKE '%' + @SearchTerm + '%'
    ORDER BY [LastName], [FirstName];
END;

-- ============================================
-- 7. FUNCTIONS
-- ============================================

-- Function to calculate patient age
CREATE FUNCTION [dbo].[fn_CalculateAge](@DateOfBirth DATETIME2)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @DateOfBirth, GETDATE()) - 
           CASE 
               WHEN MONTH(@DateOfBirth) > MONTH(GETDATE()) OR 
                   (MONTH(@DateOfBirth) = MONTH(GETDATE()) AND DAY(@DateOfBirth) > DAY(GETDATE()))
               THEN 1 
               ELSE 0 
           END;
END;

-- Function to get patient's next appointment
CREATE FUNCTION [dbo].[fn_GetNextAppointment](@PatientId INT)
RETURNS DATETIME2
AS
BEGIN
    DECLARE @NextAppointment DATETIME2;
    
    SELECT @NextAppointment = MIN([AppointmentDateTime])
    FROM [dbo].[Appointments]
    WHERE [PatientId] = @PatientId
      AND [AppointmentDateTime] > GETDATE()
      AND [Status] IN ('Scheduled', 'Confirmed');
    
    RETURN @NextAppointment;
END;

-- ============================================
-- 8. SAMPLE DATA
-- ============================================

-- Insert sample patients
SET IDENTITY_INSERT [dbo].[Patients] ON;

INSERT INTO [dbo].[Patients] ([Id], [FirstName], [LastName], [DateOfBirth], [Email], [PhoneNumber], [Address], [MedicalHistory], [RegistrationDate])
VALUES 
    (1, N'John', N'Doe', '1980-05-15', N'john.doe@email.com', N'(555) 123-4567', N'123 Main Street, Anytown, NY 12345', N'No known allergies. Previous surgery: Appendectomy (2010).', '2024-08-01 10:00:00'),
    (2, N'Jane', N'Smith', '1975-08-22', N'jane.smith@email.com', N'(555) 987-6543', N'456 Oak Avenue, Somewhere, CA 90210', N'Allergic to penicillin. Diabetic (Type 2) since 2018.', '2024-08-15 14:30:00'),
    (3, N'Bob', N'Johnson', '1990-12-03', N'bob.johnson@email.com', N'(555) 555-1234', N'789 Pine Road, Elsewhere, TX 75001', N'No known medical conditions.', '2024-09-01 09:15:00');

SET IDENTITY_INSERT [dbo].[Patients] OFF;

-- Insert sample appointments
SET IDENTITY_INSERT [dbo].[Appointments] ON;

INSERT INTO [dbo].[Appointments] ([Id], [PatientId], [DoctorName], [AppointmentDateTime], [Reason], [Status], [Notes], [CreatedDate])
VALUES 
    (1, 1, N'Dr. Sarah Wilson', '2025-09-15 10:00:00', N'Annual checkup and blood work', N'Scheduled', N'Fasting required for blood work', '2025-09-03 09:00:00'),
    (2, 2, N'Dr. Michael Brown', '2025-09-11 14:00:00', N'Diabetes management consultation', N'Scheduled', N'Bring current glucose logs', '2025-09-06 16:00:00'),
    (3, 3, N'Dr. Emily Davis', '2025-09-20 11:30:00', N'Routine physical examination', N'Scheduled', N'First visit - complete physical', '2025-09-07 10:30:00');

SET IDENTITY_INSERT [dbo].[Appointments] OFF;

-- ============================================
-- 9. EXAMPLE USAGE OF STORED PROCEDURES
-- ============================================

-- Add a new patient
DECLARE @NewPatientId INT;
EXEC [dbo].[sp_AddPatient] 
    @FirstName = N'Alice',
    @LastName = N'Williams',
    @DateOfBirth = '1988-03-20',
    @Email = N'alice.williams@email.com',
    @PhoneNumber = N'(555) 444-5555',
    @Address = N'999 New Street, Sample City, ST 54321',
    @MedicalHistory = N'Seasonal allergies',
    @NewPatientId = @NewPatientId OUTPUT;

-- Schedule an appointment for the new patient
DECLARE @NewAppointmentId INT;
EXEC [dbo].[sp_ScheduleAppointment]
    @PatientId = @NewPatientId,
    @DoctorName = N'Dr. Lisa Chen',
    @AppointmentDateTime = '2025-09-25 15:30:00',
    @Reason = N'Initial consultation',
    @Notes = N'New patient intake',
    @NewAppointmentId = @NewAppointmentId OUTPUT;

-- Search for patients
EXEC [dbo].[sp_SearchPatients] @SearchTerm = N'smith';

-- ============================================
-- 10. REPORTING QUERIES
-- ============================================

-- Monthly registration report
SELECT 
    FORMAT([RegistrationDate], 'yyyy-MM') AS [Month],
    COUNT(*) AS [NewPatients]
FROM [dbo].[Patients]
GROUP BY FORMAT([RegistrationDate], 'yyyy-MM')
ORDER BY [Month] DESC;

-- Doctor workload report
SELECT 
    [DoctorName],
    COUNT(*) AS [TotalAppointments],
    SUM(CASE WHEN [Status] = 'Scheduled' THEN 1 ELSE 0 END) AS [ScheduledCount],
    SUM(CASE WHEN [Status] = 'Completed' THEN 1 ELSE 0 END) AS [CompletedCount],
    SUM(CASE WHEN [Status] = 'Cancelled' THEN 1 ELSE 0 END) AS [CancelledCount]
FROM [dbo].[Appointments]
GROUP BY [DoctorName]
ORDER BY [TotalAppointments] DESC;

-- Patients with ages using the custom function
SELECT 
    [Id],
    [FirstName] + ' ' + [LastName] AS [FullName],
    [DateOfBirth],
    [dbo].[fn_CalculateAge]([DateOfBirth]) AS [Age]
FROM [dbo].[Patients]
ORDER BY [Age] DESC;

-- ============================================
-- 11. MAINTENANCE SCRIPTS
-- ============================================

-- Update old appointment statuses
UPDATE [dbo].[Appointments] 
SET [Status] = 'Completed'
WHERE [AppointmentDateTime] < DATEADD(DAY, -1, GETDATE())
  AND [Status] = 'Scheduled';

-- Clean up old cancelled appointments (older than 3 months)
DELETE FROM [dbo].[Appointments] 
WHERE [Status] = 'Cancelled' 
  AND [CreatedDate] < DATEADD(MONTH, -3, GETDATE());
