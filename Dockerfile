# Dockerfile for Medical Web Application
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MedicalWebApp.csproj", "."]
RUN dotnet restore "MedicalWebApp.csproj"
COPY . .
RUN dotnet build "MedicalWebApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MedicalWebApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Install Entity Framework tools for migrations
RUN dotnet tool install --global dotnet-ef --version 8.0.8
ENV PATH="${PATH}:/root/.dotnet/tools"

ENTRYPOINT ["dotnet", "MedicalWebApp.dll"]
