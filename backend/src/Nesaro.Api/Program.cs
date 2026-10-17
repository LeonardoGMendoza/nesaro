using Nesaro.Api.Endpoints;
using Nesaro.Api.Security;
using Nesaro.Application;
using Nesaro.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Cada camada registra as próprias dependências.
builder.Services
    .AddApplication()
    .AddInfrastructure(builder.Configuration);

// Serviços da própria camada Api.
builder.Services.AddSingleton<MetaSignatureValidator>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();

app.MapHealthEndpoints();
app.MapWebhookEndpoints();
app.MapInstagramAuthEndpoints();

app.Run();
