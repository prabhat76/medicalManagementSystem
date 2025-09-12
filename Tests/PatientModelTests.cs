using System.ComponentModel.DataAnnotations;
using MedicalWebApp.Models;
using Xunit;

namespace MedicalWebApp.Tests
{
    public class PatientModelTests
    {
        [Fact]
        public void Patient_ShouldHaveValidDefaultProperties()
        {
            // Arrange & Act
            var patient = new Patient();

            // Assert
            Assert.Equal(0, patient.Id);
            Assert.Equal(string.Empty, patient.FirstName);
            Assert.Equal(string.Empty, patient.LastName);
            Assert.Equal(string.Empty, patient.PhoneNumber);
            Assert.Equal(string.Empty, patient.Email);
            Assert.Equal(string.Empty, patient.Address);
            Assert.Equal(string.Empty, patient.MedicalHistory);
            Assert.True(patient.RegistrationDate > DateTime.MinValue);
        }

        [Fact]
        public void Patient_ShouldAllowValidData()
        {
            // Arrange & Act
            var patient = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = "john.doe@example.com",
                Address = "123 Main Street",
                MedicalHistory = "No known allergies"
            };

            // Assert
            Assert.Equal("John", patient.FirstName);
            Assert.Equal("Doe", patient.LastName);
            Assert.Equal(new DateTime(1990, 1, 15), patient.DateOfBirth);
            Assert.Equal("555-123-4567", patient.PhoneNumber);
            Assert.Equal("john.doe@example.com", patient.Email);
            Assert.Equal("123 Main Street", patient.Address);
            Assert.Equal("No known allergies", patient.MedicalHistory);
        }

        [Fact]
        public void Patient_ValidationAttributes_ShouldBePresent()
        {
            // Arrange
            var type = typeof(Patient);

            // Act & Assert - Check Required attributes
            var firstNameProperty = type.GetProperty(nameof(Patient.FirstName));
            Assert.NotNull(firstNameProperty);
            Assert.True(firstNameProperty.GetCustomAttributes(typeof(RequiredAttribute), false).Any());

            var lastNameProperty = type.GetProperty(nameof(Patient.LastName));
            Assert.NotNull(lastNameProperty);
            Assert.True(lastNameProperty.GetCustomAttributes(typeof(RequiredAttribute), false).Any());

            var emailProperty = type.GetProperty(nameof(Patient.Email));
            Assert.NotNull(emailProperty);
            Assert.True(emailProperty.GetCustomAttributes(typeof(RequiredAttribute), false).Any());
            Assert.True(emailProperty.GetCustomAttributes(typeof(EmailAddressAttribute), false).Any());

            var phoneProperty = type.GetProperty(nameof(Patient.PhoneNumber));
            Assert.NotNull(phoneProperty);
            Assert.True(phoneProperty.GetCustomAttributes(typeof(RequiredAttribute), false).Any());
            Assert.True(phoneProperty.GetCustomAttributes(typeof(PhoneAttribute), false).Any());
        }

        [Theory]
        [InlineData("", false)] // Empty string
        [InlineData("invalid-email", false)] // Invalid format
        [InlineData("test@", false)] // Incomplete
        [InlineData("test@example.com", true)] // Valid
        [InlineData("user.name+tag@example.co.uk", true)] // Complex valid
        public void Patient_EmailValidation_ShouldWorkCorrectly(string email, bool expectedValid)
        {
            // Arrange
            var patient = new Patient
            {
                FirstName = "John",
                LastName = "Doe",
                DateOfBirth = new DateTime(1990, 1, 15),
                PhoneNumber = "555-123-4567",
                Email = email,
                Address = "123 Main Street"
            };

            var context = new ValidationContext(patient);
            var results = new List<ValidationResult>();

            // Act
            var isValid = Validator.TryValidateObject(patient, context, results, true);

            // Assert
            if (expectedValid)
            {
                Assert.True(results.All(r => !r.MemberNames.Contains(nameof(Patient.Email))));
            }
            else
            {
                Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.Email))));
            }
        }

        [Fact]
        public void Patient_RequiredFields_ShouldFailValidationWhenEmpty()
        {
            // Arrange
            var patient = new Patient(); // All required fields empty

            var context = new ValidationContext(patient);
            var results = new List<ValidationResult>();

            // Act
            var isValid = Validator.TryValidateObject(patient, context, results, true);

            // Assert
            Assert.False(isValid);
            Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.FirstName))));
            Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.LastName))));
            Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.Email))));
            Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.PhoneNumber))));
            Assert.True(results.Any(r => r.MemberNames.Contains(nameof(Patient.Address))));
        }
    }
}