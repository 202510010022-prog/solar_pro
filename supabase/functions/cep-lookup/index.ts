// Restrict CORS to known domains (S2.1)
const allowedOrigins = [
  "https://solarpro.app",
  "https://admin.solarpro.app",
  "http://localhost:3000",
  "http://localhost:8081",
];

function getCorsHeaders(origin?: string): Record<string, string> {
  const corsOrigin = origin && isAllowedOrigin(origin) ? origin : "null";
  return {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function isAllowedOrigin(origin: string) {
  if (allowedOrigins.includes(origin)) return true;
  return /^http:\/\/(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+)(:\d+)?$/
    .test(origin);
}

let corsHeaders = getCorsHeaders();

type CepPayload = {
  cep?: string;
};

type CepLookupData = {
  zipCode: string;
  street: string;
  neighborhood: string;
  city: string;
  state: string;
  source: "viacep" | "brasilapi";
};

const providerTimeoutMs = 6000;

Deno.serve(async (request) => {
  corsHeaders = getCorsHeaders(request.headers.get("Origin") ?? undefined);

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

    const providers = [lookupViaCep, lookupBrasilApi];
    for (const provider of providers) {
      const result = await provider(cep).catch(() => null);
      if (result && hasMinimumAddress(result)) {
        return jsonResponse({
          ok: true,
          zip_code: result.zipCode,
          street: result.street,
          neighborhood: result.neighborhood,
          city: result.city,
          state: result.state,
          source: result.source,
          address_resolution: addressResolution(result),
        });
      }
    }

    return jsonResponse({ error: "CEP não encontrado." }, 404);
  } catch (error) {
    return jsonResponse(
      { error: "Não foi possível consultar o CEP." },
      500,
    );
  }
});

async function lookupViaCep(cep: string): Promise<CepLookupData | null> {
  const response = await fetchWithTimeout(
    `https://viacep.com.br/ws/${cep}/json/`,
  );
  if (!response.ok) return null;

  const data = await response.json();
  if (data?.erro) return null;

  return {
    zipCode: cep,
    street: clean(data.logradouro),
    neighborhood: clean(data.bairro),
    city: clean(data.localidade),
    state: clean(data.uf).toUpperCase(),
    source: "viacep",
  };
}

async function lookupBrasilApi(cep: string): Promise<CepLookupData | null> {
  const response = await fetchWithTimeout(
    `https://brasilapi.com.br/api/cep/v2/${cep}`,
  );
  if (!response.ok) return null;

  const data = await response.json();
  return {
    zipCode: cep,
    street: clean(data.street),
    neighborhood: clean(data.neighborhood),
    city: clean(data.city),
    state: clean(data.state).toUpperCase(),
    source: "brasilapi",
  };
}

async function fetchWithTimeout(url: string) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), providerTimeoutMs);
  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function hasMinimumAddress(data: CepLookupData) {
  return data.city.length > 0 && /^[A-Z]{2}$/.test(data.state);
}

function addressResolution(data: CepLookupData) {
  if (data.street) return "street";
  if (data.neighborhood) return "neighborhood";
  return "locality";
}

function onlyDigits(value: unknown) {
  return `${value ?? ""}`.replace(/\D/g, "");
}

function clean(value: unknown) {
  return `${value ?? ""}`.trim().replace(/\s+/g, " ");
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
