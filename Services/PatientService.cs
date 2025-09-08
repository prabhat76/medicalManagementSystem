using MedicalWebApp.Models;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

namespace MedicalWebApp.Services
{
    public interface IPatientService
    {
        Task<int> AddPatientAsync(Patient patient);
        Task<Patient?> GetPatientByIdAsync(int id);
        Task<List<Patient>> GetAllPatientsAsync();
        Task<bool> UpdatePatientAsync(Patient patient);
        Task<bool> DeletePatientAsync(int id);
        Task<List<Patient>> SearchPatientsAsync(string searchTerm);
        Task<bool> IsEmailUniqueAsync(string email, int? excludePatientId = null);
        Task<Patient?> GetPatientByEmailAsync(string email);
    }

    public class DatabasePatientService : IPatientService
    {
        private readonly MedicalDbContext _context;

        public DatabasePatientService(MedicalDbContext context)
        {
            _context = context;
        }

        public async Task<int> AddPatientAsync(Patient patient)
        {
            // Check if email already exists
            var existingPatient = await GetPatientByEmailAsync(patient.Email);
            if (existingPatient != null)
            {
                throw new InvalidOperationException($"A patient with email '{patient.Email}' already exists.");
            }

            // Ensure the registration date is set
            patient.RegistrationDate = DateTime.Now;
            
            _context.Patients.Add(patient);
            await _context.SaveChangesAsync();
            return patient.Id;
        }

        public async Task<Patient?> GetPatientByEmailAsync(string email)
        {
            return await _context.Patients
                .FirstOrDefaultAsync(p => p.Email.ToLower() == email.ToLower());
        }

        public async Task<bool> IsEmailUniqueAsync(string email, int? excludePatientId = null)
        {
            var query = _context.Patients.Where(p => p.Email.ToLower() == email.ToLower());
            
            if (excludePatientId.HasValue)
            {
                query = query.Where(p => p.Id != excludePatientId.Value);
            }
            
            return !await query.AnyAsync();
        }

        public async Task<Patient?> GetPatientByIdAsync(int id)
        {
            return await _context.Patients
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task<List<Patient>> GetAllPatientsAsync()
        {
            return await _context.Patients
                .OrderByDescending(p => p.RegistrationDate)
                .ToListAsync();
        }

        public async Task<bool> UpdatePatientAsync(Patient patient)
        {
            try
            {
                _context.Patients.Update(patient);
                await _context.SaveChangesAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> DeletePatientAsync(int id)
        {
            var patient = await GetPatientByIdAsync(id);
            if (patient != null)
            {
                _context.Patients.Remove(patient);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<List<Patient>> SearchPatientsAsync(string searchTerm)
        {
            if (string.IsNullOrWhiteSpace(searchTerm))
                return await GetAllPatientsAsync();

            searchTerm = searchTerm.ToLower();
            return await _context.Patients
                .Where(p => p.FirstName.ToLower().Contains(searchTerm) ||
                           p.LastName.ToLower().Contains(searchTerm) ||
                           p.Email.ToLower().Contains(searchTerm) ||
                           p.PhoneNumber.Contains(searchTerm))
                .OrderByDescending(p => p.RegistrationDate)
                .ToListAsync();
        }
    }

    // Keep the in-memory service for fallback or testing
    public class InMemoryPatientService : IPatientService
    {
        private static List<Patient> _patients = new List<Patient>();
        private static int _nextId = 1000;

        public Task<int> AddPatientAsync(Patient patient)
        {
            // Check if email already exists
            var existingPatient = _patients.FirstOrDefault(p => p.Email.ToLower() == patient.Email.ToLower());
            if (existingPatient != null)
            {
                throw new InvalidOperationException($"A patient with email '{patient.Email}' already exists.");
            }

            patient.Id = _nextId++;
            patient.RegistrationDate = DateTime.Now;
            _patients.Add(patient);
            return Task.FromResult(patient.Id);
        }

        public Task<Patient?> GetPatientByEmailAsync(string email)
        {
            var patient = _patients.FirstOrDefault(p => p.Email.ToLower() == email.ToLower());
            return Task.FromResult(patient);
        }

        public Task<bool> IsEmailUniqueAsync(string email, int? excludePatientId = null)
        {
            var query = _patients.Where(p => p.Email.ToLower() == email.ToLower());
            
            if (excludePatientId.HasValue)
            {
                query = query.Where(p => p.Id != excludePatientId.Value);
            }
            
            return Task.FromResult(!query.Any());
        }

        public Task<Patient?> GetPatientByIdAsync(int id)
        {
            var patient = _patients.FirstOrDefault(p => p.Id == id);
            return Task.FromResult(patient);
        }

        public Task<List<Patient>> GetAllPatientsAsync()
        {
            return Task.FromResult(_patients.OrderByDescending(p => p.RegistrationDate).ToList());
        }

        public Task<bool> UpdatePatientAsync(Patient patient)
        {
            var existingPatient = _patients.FirstOrDefault(p => p.Id == patient.Id);
            if (existingPatient != null)
            {
                var index = _patients.IndexOf(existingPatient);
                _patients[index] = patient;
                return Task.FromResult(true);
            }
            return Task.FromResult(false);
        }

        public Task<bool> DeletePatientAsync(int id)
        {
            var patient = _patients.FirstOrDefault(p => p.Id == id);
            if (patient != null)
            {
                _patients.Remove(patient);
                return Task.FromResult(true);
            }
            return Task.FromResult(false);
        }

        public Task<List<Patient>> SearchPatientsAsync(string searchTerm)
        {
            if (string.IsNullOrWhiteSpace(searchTerm))
                return GetAllPatientsAsync();

            searchTerm = searchTerm.ToLower();
            var results = _patients
                .Where(p => p.FirstName.ToLower().Contains(searchTerm) ||
                           p.LastName.ToLower().Contains(searchTerm) ||
                           p.Email.ToLower().Contains(searchTerm) ||
                           p.PhoneNumber.Contains(searchTerm))
                .OrderByDescending(p => p.RegistrationDate)
                .ToList();
            return Task.FromResult(results);
        }
    }
}
