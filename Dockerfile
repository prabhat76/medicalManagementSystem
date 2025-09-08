# Dockerfile for Medical Web Application
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file first for better Docker layer caching
COPY ["MedicalWebApp.csproj", "."]
RUN dotnet restore "./MedicalWebApp.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "./MedicalWebApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "./MedicalWebApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Set environment variables for production
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "MedicalWebApp.dll"]
