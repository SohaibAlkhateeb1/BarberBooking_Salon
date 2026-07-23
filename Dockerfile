# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files first for better layer caching
COPY BarberBooking.sln .
COPY src/BarberBooking.Domain/BarberBooking.Domain.csproj src/BarberBooking.Domain/
COPY src/BarberBooking.Application/BarberBooking.Application.csproj src/BarberBooking.Application/
COPY src/BarberBooking.Infrastructure/BarberBooking.Infrastructure.csproj src/BarberBooking.Infrastructure/
COPY src/BarberBooking.API/BarberBooking.API.csproj src/BarberBooking.API/

RUN dotnet restore

# Copy everything and publish
COPY src/ .
RUN dotnet publish src/BarberBooking.API/BarberBooking.API.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:5170
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 5170

ENTRYPOINT ["dotnet", "BarberBooking.API.dll"]
