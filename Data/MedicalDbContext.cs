using Microsoft.EntityFrameworkCore;
using MedicalWebApp.Models;

namespace MedicalWebApp.Data
{
    public class MedicalDbContext : DbContext
    {
        public MedicalDbContext(DbContextOptions<MedicalDbContext> options) : base(options)
        {
        }

        // DbSets represent database tables
        public DbSet<Patient> Patients { get; set; }
        public DbSet<Appointment> Appointments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Patient entity
            modelBuilder.Entity<Patient>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.FirstName)
                    .IsRequired()
                    .HasMaxLength(100);
                entity.Property(e => e.LastName)
                    .IsRequired()
                    .HasMaxLength(100);
                entity.Property(e => e.Email)
                    .IsRequired()
                    .HasMaxLength(255);
                entity.Property(e => e.PhoneNumber)
                    .IsRequired()
                    .HasMaxLength(20);
                entity.Property(e => e.Address)
                    .IsRequired()
                    .HasMaxLength(500);
                entity.Property(e => e.MedicalHistory)
                    .HasMaxLength(2000);

                // PostgreSQL-specific: Use TIMESTAMP instead of datetime
                if (Database.IsNpgsql())
                {
                    entity.Property(e => e.DateOfBirth)
                        .HasColumnType("timestamp without time zone");
                    entity.Property(e => e.RegistrationDate)
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");
                }
                else if (Database.IsMySql())
                {
                    entity.Property(e => e.DateOfBirth)
                        .HasColumnType("datetime(6)");
                    entity.Property(e => e.RegistrationDate)
                        .HasColumnType("datetime(6)")
                        .HasDefaultValueSql("NOW()");
                }
                else
                {
                    entity.Property(e => e.RegistrationDate)
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");
                }
                
                // Create unique index on email
                entity.HasIndex(e => e.Email)
                    .IsUnique()
                    .HasDatabaseName("IX_Patients_Email");
            });

            // Configure Appointment entity
            modelBuilder.Entity<Appointment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.DoctorName)
                    .IsRequired()
                    .HasMaxLength(100);
                entity.Property(e => e.Reason)
                    .IsRequired()
                    .HasMaxLength(500);
                entity.Property(e => e.Status)
                    .IsRequired()
                    .HasMaxLength(50)
                    .HasDefaultValue("Scheduled");
                entity.Property(e => e.Notes)
                    .HasMaxLength(1000);

                // PostgreSQL-specific: Use TIMESTAMP instead of datetime
                if (Database.IsNpgsql())
                {
                    entity.Property(e => e.AppointmentDateTime)
                        .HasColumnType("timestamp without time zone");
                    entity.Property(e => e.CreatedDate)
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");
                }
                else if (Database.IsMySql())
                {
                    entity.Property(e => e.AppointmentDateTime)
                        .HasColumnType("datetime(6)");
                    entity.Property(e => e.CreatedDate)
                        .HasColumnType("datetime(6)")
                        .HasDefaultValueSql("NOW()");
                }
                else
                {
                    entity.Property(e => e.CreatedDate)
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");
                }

                // Configure relationship with Patient
                entity.HasOne(e => e.Patient)
                    .WithMany()
                    .HasForeignKey(e => e.PatientId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Remove seed data for now - we'll add it manually
            // This prevents DateTime conversion issues during migration
        }
    }
}
