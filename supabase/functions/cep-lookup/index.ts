// Restrict CORS to known domains (S2.1)
const allowedOrigins = [
  "https://solarpro.app",
  "https://admin.solarpro.app",
  "http://localhost:3000",
  "http://localhost:8081",
];

function getCorsHeaders(origin?: string): Record<string, string> {
  const corsOrigin = origin && allowedOrigins.includes(origin) ? origin : "null";
  return {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

type CepPayload = {
  cep?: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return jsonResponse({ ok: true });
  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido." }, 405);
  }

  try {
    const token = bearerToken(request);
    if (!token) return jsonResponse({ error: "Token de acesso ausente." }, 401);

    const payload = (await request.json().catch(() => ({}))) as CepPayload;
    const cep = onlyDigits(payload.cep);
    if (cep.length !== 8) {
      return jsonResponse({ error: "Informe um CEP com 8 números." }, 400);
    }

    const viacep = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
    if (viacep.ok) {
      const data = await viacep.json();
      if (!data?.erro) {
        return jsonResponse({
          ok: true,
          zip_code: cep,
          street: `${data.logradouro || ""}`.trim(),
          neighborhood: `${data.bairro || ""}`.trim(),
          city: `${data.localidade || ""}`.trim(),
          state: `${data.uf || ""}`.trim().toUpperCase(),
          source: "viacep",
        });
      }
    }

    const brasilApi = await fetch(`https://brasilapi.com.br/api/cep/v2/${cep}`);
    if (brasilApi.ok) {
      const data = await brasilApi.json();
      return jsonResponse({
        ok: true,
        zip_code: cep,
        street: `${data.street || ""}`.trim(),
        neighborhood: `${data.neighborhood || ""}`.trim(),
        city: `${data.city || ""}`.trim(),
        state: `${data.state || ""}`.trim().toUpperCase(),
        source: "brasilapi",
      });
    }

    return jsonResponse({ error: "CEP não encontrado." }, 404);
  } catch (error) {
    return jsonResponse(
      { error: "Não foi possível consultar o CEP." },
      500,
    );
  }
});

function onlyDigits(value: unknown) {
  return `${value ?? ""}`.replace(/\D/g, "");
}

function bearerToken(request: Request) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? "";
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
