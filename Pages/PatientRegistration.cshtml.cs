using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using MedicalWebApp.Models;
using MedicalWebApp.Services;

namespace MedicalWebApp.Pages
{
    public class PatientRegistrationModel : PageModel
    {
        private readonly IPatientService _patientService;

        public PatientRegistrationModel(IPatientService patientService)
        {
            _patientService = patientService;
        }

        [BindProperty]
        public Patient Patient { get; set; } = new Patient();
        
        public bool IsSuccess { get; set; } = false;
        public int? NewPatientId { get; set; }

        public void OnGet()
        {
            // Initialize with current date for registration
            Patient.RegistrationDate = DateTime.Now;
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            try
            {
                // Check if email is already in use
                var existingPatient = await _patientService.GetPatientByEmailAsync(Patient.Email);
                if (existingPatient != null)
                {
                    ModelState.AddModelError("Patient.Email", 
                        $"A patient with email '{Patient.Email}' is already registered. Please use a different email address.");
                    return Page();
                }

                // Actually save the patient data using our service
                var patientId = await _patientService.AddPatientAsync(Patient);
                
                // Set success flag and store the new patient ID
                IsSuccess = true;
                NewPatientId = patientId;
                
                // Reset the form for a new patient (optional)
                Patient = new Patient { RegistrationDate = DateTime.Now };
                
                return Page();
            }
            catch (InvalidOperationException ex) when (ex.Message.Contains("already exists"))
            {
                // Handle duplicate email errors specifically
                ModelState.AddModelError("Patient.Email", 
                    "This email address is already registered. Please use a different email address.");
                return Page();
            }
            catch (Exception ex)
            {
                // Handle any other errors during save
                ModelState.AddModelError("", $"An error occurred while registering the patient: {ex.Message}");
                return Page();
            }
        }
    }
}
