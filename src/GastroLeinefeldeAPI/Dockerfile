FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/GastroLeinefeldeAPI/GastroLeinefeldeAPI.csproj GastroLeinefeldeAPI/
RUN dotnet restore GastroLeinefeldeAPI/GastroLeinefeldeAPI.csproj

COPY src/GastroLeinefeldeAPI/ GastroLeinefeldeAPI/
WORKDIR /src/GastroLeinefeldeAPI
RUN dotnet publish -c Release -o /app/publish --no-restore --self-contained false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && addgroup --system --gid 10001 appgroup \
    && adduser --system --uid 10001 --ingroup appgroup appuser
COPY --from=build /app/publish .
RUN chown -R appuser:appgroup /app
USER appuser

ENTRYPOINT ["dotnet", "GastroLeinefeldeAPI.dll"]
