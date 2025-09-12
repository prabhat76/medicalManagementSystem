using Microsoft.EntityFrameworkCore;
using MedicalWebApp.Data;
using MedicalWebApp.Models;
using MedicalWebApp.Services;
using Xunit;

namespace MedicalWebApp.Tests
{
    public class PatientServiceTests
    {
        private MedicalDbContext GetInMemoryContext()
        {
            var options = new DbContextOptionsBuilder<MedicalDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            return new MedicalDbContext(options);
        }

        [Fact]
        public async Task AddPatientAsync_ShouldAddPatient_WhenValidData()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);
            var patient = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@test.com",
                Address = "123 Test Street",
                MedicalHistory = "No known issues"
            };

            // Act
            var patientId = await service.AddPatientAsync(patient);

            // Assert
            Assert.True(patientId > 0);
            var savedPatient = await service.GetPatientByIdAsync(patientId);
            Assert.NotNull(savedPatient);
            Assert.Equal("John", savedPatient.FirstName);
            Assert.Equal("john.doe@test.com", savedPatient.Email);
        }

        [Fact]
        public async Task AddPatientAsync_ShouldThrowException_WhenDuplicateEmail()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);
            var patient1 = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@test.com",
                Address = "123 Test Street",
                MedicalHistory = "No known issues"
            };

            var patient2 = new Patient
            {
                FirstName = "Jane",
                LastName = "Smith",
                DateOfBirth = new DateTime(1985, 5, 20),
                PhoneNumber = "555-987-6543",
                Email = "john.doe@test.com", // Same email
                Address = "456 Another Street",
                MedicalHistory = "Some history"
            };

            // Act & Assert
            await service.AddPatientAsync(patient1);
            await Assert.ThrowsAsync<InvalidOperationException>(
                () => service.AddPatientAsync(patient2));
        }

        [Fact]
        public async Task GetAllPatientsAsync_ShouldReturnAllPatients()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);
            
            var patient1 = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@test.com",
                Address = "123 Test Street"
            };

            var patient2 = new Patient
            {
                FirstName = "Jane",
                LastName = "Smith",
                DateOfBirth = new DateTime(1985, 5, 20),
                PhoneNumber = "555-987-6543",
                Email = "jane.smith@test.com",
                Address = "456 Another Street"
            };

            // Act
            await service.AddPatientAsync(patient1);
            await service.AddPatientAsync(patient2);
            var patients = await service.GetAllPatientsAsync();

            // Assert
            Assert.Equal(2, patients.Count);
            Assert.Contains(patients, p => p.FirstName == "John");
            Assert.Contains(patients, p => p.FirstName == "Jane");
        }

        [Fact]
        public async Task SearchPatientsAsync_ShouldFindPatientsByName()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);
            
            var patient1 = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@test.com",
                Address = "123 Test Street"
            };

            var patient2 = new Patient
            {
                FirstName = "Jane",
                LastName = "Smith",
                DateOfBirth = new DateTime(1985, 5, 20),
                PhoneNumber = "555-987-6543",
                Email = "jane.smith@test.com",
                Address = "456 Another Street"
            };

            await service.AddPatientAsync(patient1);
            await service.AddPatientAsync(patient2);

            // Act
            var results = await service.SearchPatientsAsync("John");

            // Assert
            Assert.Single(results);
            Assert.Equal("John", results[0].FirstName);
        }

        [Fact]
        public async Task IsEmailUniqueAsync_ShouldReturnTrue_WhenEmailNotExists()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);

            // Act
            var isUnique = await service.IsEmailUniqueAsync("new.email@test.com");

            // Assert
            Assert.True(isUnique);
        }

        [Fact]
        public async Task IsEmailUniqueAsync_ShouldReturnFalse_WhenEmailExists()
        {
            // Arrange
            using var context = GetInMemoryContext();
            var service = new DatabasePatientService(context);
            
            var patient = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@test.com",
                Address = "123 Test Street"
            };

            await service.AddPatientAsync(patient);

            // Act
            var isUnique = await service.IsEmailUniqueAsync("john.doe@test.com");

            // Assert
            Assert.False(isUnique);
        }
    }
}