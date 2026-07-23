# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Copy everything
COPY . .

# Restore dependencies
RUN dotnet restore BarberBooking.sln

# Publish the API project
RUN dotnet publish src/BarberBooking.API/BarberBooking.API.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:5170
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 5170

ENTRYPOINT ["dotnet", "BarberBooking.API.dll"]
