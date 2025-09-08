using System.ComponentModel.DataAnnotations;

namespace MedicalWebApp.Models
{
    public class Appointment
    {
        public int Id { get; set; }
        
        [Required]
        [Display(Name = "Patient ID")]
        public int PatientId { get; set; }
        
        [Required]
        [Display(Name = "Doctor Name")]
        public string DoctorName { get; set; } = string.Empty;
        
        [Required]
        [DataType(DataType.DateTime)]
        [Display(Name = "Appointment Date & Time")]
        public DateTime AppointmentDateTime { get; set; }
        
        [Required]
        [Display(Name = "Reason for Visit")]
        public string Reason { get; set; } = string.Empty;
        
        [Display(Name = "Status")]
        public string Status { get; set; } = "Scheduled";
        
        [Display(Name = "Notes")]
        public string Notes { get; set; } = string.Empty;
        
        [Display(Name = "Created Date")]
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        
        // Navigation property
        public Patient? Patient { get; set; }
    }
}
