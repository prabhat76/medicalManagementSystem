-- Medical Web App Database Setup for Neon PostgreSQL
-- Run this manually in your Neon dashboard if migrations fail

-- Create Patients table
CREATE TABLE IF NOT EXISTS "Patients" (
    "Id" SERIAL PRIMARY KEY,
    "FirstName" VARCHAR(100) NOT NULL,
    "LastName" VARCHAR(100) NOT NULL,
    "Email" VARCHAR(255) NOT NULL UNIQUE,
    "PhoneNumber" VARCHAR(20) NOT NULL,
    "Address" VARCHAR(500) NOT NULL,
    "DateOfBirth" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "MedicalHistory" VARCHAR(2000),
    "RegistrationDate" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create unique index on email if not exists
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Patients_Email" ON "Patients" ("Email");

-- Create Appointments table
CREATE TABLE IF NOT EXISTS "Appointments" (
    "Id" SERIAL PRIMARY KEY,
    "PatientId" INTEGER NOT NULL,
    "DoctorName" VARCHAR(100) NOT NULL,
    "AppointmentDateTime" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "Reason" VARCHAR(500) NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Scheduled',
    "Notes" VARCHAR(1000),
    "CreatedDate" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("PatientId") REFERENCES "Patients" ("Id") ON DELETE CASCADE
);

-- Insert sample data for testing
INSERT INTO "Patients" ("FirstName", "LastName", "Email", "PhoneNumber", "Address", "DateOfBirth", "MedicalHistory") 
VALUES 
    ('John', 'Doe', 'john.doe@example.com', '+1-555-0123', '123 Main St, New York, NY 10001', '1985-05-15', 'No known allergies'),
    ('Jane', 'Smith', 'jane.smith@example.com', '+1-555-0124', '456 Oak Ave, Los Angeles, CA 90210', '1990-08-22', 'Allergic to penicillin')
ON CONFLICT ("Email") DO NOTHING;

-- Verify tables are created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('Patients', 'Appointments');

-- Check if data exists
SELECT COUNT(*) as patient_count FROM "Patients";
SELECT COUNT(*) as appointment_count FROM "Appointments";
