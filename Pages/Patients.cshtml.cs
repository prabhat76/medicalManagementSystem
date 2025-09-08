using Microsoft.AspNetCore.Mvc.RazorPages;
using MedicalWebApp.Models;
using MedicalWebApp.Services;

namespace MedicalWebApp.Pages
{
    public class PatientsModel : PageModel
    {
        private readonly IPatientService _patientService;

        public PatientsModel(IPatientService patientService)
        {
            _patientService = patientService;
        }

        public List<Patient> Patients { get; set; } = new List<Patient>();

        public async Task OnGetAsync()
        {
            Patients = await _patientService.GetAllPatientsAsync();
        }
    }
}
