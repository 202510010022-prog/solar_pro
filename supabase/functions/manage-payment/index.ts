import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

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

let corsHeaders = getCorsHeaders();

const allowedCreatorPermissions = new Set(["diretor", "admin", "owner"]);
const allowedActions = new Set(["create", "mark_paid", "cancel", "sync_overdue"]);

type PaymentPayload = {
  action?: string;
  payment_id?: number;
  amount?: number | string;
  due_date?: string;
  pix_reference?: string;
  notes?: string;
  period_months?: number | string;
  idempotency_key?: string;
};

Deno.serve(async (request) => {
  corsHeaders = getCorsHeaders(request.headers.get("Origin") ?? undefined);

  if (request.method === "OPTIONS") return jsonResponse({ ok: true });
  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido." }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: "Ambiente Supabase incompleto." }, 500);
    }

    const token = bearerToken(request);
    if (!token) return jsonResponse({ error: "Token de acesso ausente." }, 401);

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authData, error: authError } =
      await adminClient.auth.getUser(token);
    if (authError || !authData.user) {
      return jsonResponse({ error: "Sessao invalida ou expirada." }, 401);
    }

    const { data: profile, error: profileError } = await adminClient
      .from("profiles")
      .select("id, company_id, permission, active")
      .eq("id", authData.user.id)
      .single();

    if (profileError || !profile?.active) {
      return jsonResponse({ error: "Perfil do solicitante nao encontrado." }, 403);
    }

    if (!allowedCreatorPermissions.has(`${profile.permission}`)) {
      return jsonResponse(
        { error: "Somente diretor ou admin pode gerenciar cobrancas." },
        403,
      );
    }

    const payload = (await request.json().catch(() => ({}))) as PaymentPayload;
    const action = `${payload.action || ""}`.trim();
    if (!allowedActions.has(action)) {
      return jsonResponse({ error: "Acao de cobranca invalida." }, 400);
    }

    if (action !== "sync_overdue") {
      const companyAccessError = await validateCompanyWriteAccess(
        adminClient,
        profile.company_id,
      );
      if (companyAccessError) return companyAccessError;
    }

    if (action === "create") {
      return await createPayment(adminClient, profile.company_id, profile.id, payload);
    }
    if (action === "mark_paid") {
      return await markPaid(adminClient, profile.company_id, payload);
    }
    if (action === "sync_overdue") {
      return await syncOverdue(adminClient, profile.company_id);
    }
    return await cancelPayment(adminClient, profile.company_id, payload);
  } catch (error) {
    return jsonResponse(
      { error: "Nao foi possivel processar a cobranca." },
      500,
    );
  }
});

async function validateCompanyWriteAccess(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
) {
  const { data: company, error } = await adminClient
    .from("companies")
    .select("active, subscription_status, trial_ends_at")
    .eq("id", companyId)
    .single();

  if (error || !company) {
    return jsonResponse({ error: "Empresa nao encontrada." }, 403);
  }

  if (company.active !== true) {
    return jsonResponse({ error: "Empresa inativa. Regularize o plano para gerenciar cobrancas." }, 403);
  }

  const status = `${company.subscription_status || "blocked"}`;
  if (status === "active") return null;

  if (status === "trial") {
    const trialEndsAt = `${company.trial_ends_at || ""}`;
    if (!trialEndsAt || new Date(trialEndsAt).getTime() >= Date.now()) {
      return null;
    }
  }

  return jsonResponse({ error: "Empresa bloqueada. Regularize o plano para gerenciar cobrancas." }, 403);
}

async function createPayment(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
  createdBy: string,
  payload: PaymentPayload,
) {
  const amount = toMoney(payload.amount);
  if (amount <= 0) return jsonResponse({ error: "Informe um valor valido." }, 400);

  const dueDate = `${payload.due_date || ""}`.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) {
    return jsonResponse({ error: "Informe vencimento no formato YYYY-MM-DD." }, 400);
  }

  const { data: subscription } = await adminClient
    .from("subscriptions")
    .select("id")
    .eq("company_id", companyId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const { data, error } = await adminClient
    .from("manual_payments")
    .insert({
      company_id: companyId,
      subscription_id: subscription?.id ?? null,
      amount,
      due_date: dueDate,
      status: "pending",
      pix_reference: `${payload.pix_reference || ""}`.trim(),
      notes: `${payload.notes || ""}`.trim(),
      created_by: createdBy,
      idempotency_key: `${payload.idempotency_key || ""}`.trim() || null,
    })
    .select()
    .single();

  if (error) {
    if (
      `${error.message || ""}`.includes("manual_payments_idempotency_key_unique") ||
      `${error.code || ""}` === "23505"
    ) {
      return jsonResponse({ error: "Esta cobranca ja foi registrada." }, 409);
    }
    return jsonResponse({ error: error.message }, 400);
  }
  await createAppMessage(adminClient, {
    companyId,
    paymentId: data.id,
    createdBy,
    type: "billing",
    title: "Cobrança Pix pendente",
    message:
      `Existe uma cobrança de ${formatMoney(amount)} com vencimento em ${formatDate(dueDate)}.` +
      (data.pix_reference ? ` Referência Pix: ${data.pix_reference}.` : ""),
  });
  return jsonResponse({ ok: true, payment: data }, 201);
}

async function markPaid(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
  payload: PaymentPayload,
) {
  const paymentId = Number(payload.payment_id ?? 0);
  if (!Number.isInteger(paymentId) || paymentId <= 0) {
    return jsonResponse({ error: "Cobranca invalida." }, 400);
  }

  const periodMonths = Math.max(1, Math.min(24, Number(payload.period_months ?? 1)));
  const now = new Date();
  const periodEnd = addMonths(now, periodMonths).toISOString();

  const { data: payment, error: paymentError } = await adminClient
    .from("manual_payments")
    .update({
      status: "paid",
      paid_at: now.toISOString(),
      updated_at: now.toISOString(),
    })
    .eq("id", paymentId)
    .eq("company_id", companyId)
    .select()
    .single();

  if (paymentError || !payment) {
    return jsonResponse({ error: "Cobranca nao encontrada." }, 404);
  }

  await adminClient
    .from("companies")
    .update({
      subscription_status: "active",
      subscription_ends_at: periodEnd,
      billing_provider: "manual",
    })
    .eq("id", companyId);

  const { data: subscription } = await adminClient
    .from("subscriptions")
    .select("id")
    .eq("company_id", companyId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (subscription?.id) {
    await adminClient
      .from("subscriptions")
      .update({
        status: "active",
        provider: "manual",
        current_period_start: now.toISOString(),
        current_period_end: periodEnd,
      })
      .eq("id", subscription.id);
  }

  await createAppMessage(adminClient, {
    companyId,
    paymentId: payment.id,
    type: "success",
    title: "Pagamento confirmado",
    message:
      `Recebemos a cobrança de ${formatMoney(Number(payment.amount ?? 0))}. ` +
      `Sua assinatura está ativa até ${formatDate(periodEnd.slice(0, 10))}.`,
  });

  return jsonResponse({ ok: true, payment, subscription_ends_at: periodEnd });
}

async function cancelPayment(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
  payload: PaymentPayload,
) {
  const paymentId = Number(payload.payment_id ?? 0);
  if (!Number.isInteger(paymentId) || paymentId <= 0) {
    return jsonResponse({ error: "Cobranca invalida." }, 400);
  }

  const { data, error } = await adminClient
    .from("manual_payments")
    .update({
      status: "canceled",
      updated_at: new Date().toISOString(),
    })
    .eq("id", paymentId)
    .eq("company_id", companyId)
    .select()
    .single();

  if (error || !data) return jsonResponse({ error: "Cobranca nao encontrada." }, 404);
  await createAppMessage(adminClient, {
    companyId,
    paymentId: data.id,
    type: "info",
    title: "Cobrança cancelada",
    message: `A cobrança #${data.id} foi cancelada e não precisa ser paga.`,
  });
  return jsonResponse({ ok: true, payment: data });
}

async function createAppMessage(
  adminClient: ReturnType<typeof createClient>,
  params: {
    companyId: string;
    paymentId?: number | null;
    createdBy?: string | null;
    type: "info" | "billing" | "warning" | "success";
    title: string;
    message: string;
  },
) {
  await adminClient.from("app_messages").insert({
    company_id: params.companyId,
    payment_id: params.paymentId ?? null,
    created_by: params.createdBy ?? null,
    type: params.type,
    title: params.title,
    message: params.message,
    status: "unread",
  });
}

async function syncOverdue(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
) {
  const today = new Date().toISOString().slice(0, 10);
  const { data, error } = await adminClient
    .from("manual_payments")
    .update({
      status: "overdue",
      updated_at: new Date().toISOString(),
    })
    .eq("company_id", companyId)
    .eq("status", "pending")
    .lt("due_date", today)
    .select("id");

  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, updated: data?.length ?? 0 });
}

function bearerToken(request: Request) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? "";
}

function toMoney(value: unknown) {
  if (typeof value === "number") return Number(value.toFixed(2));
  const text = `${value ?? ""}`.replace(",", ".").trim();
  const parsed = Number(text);
  return Number.isFinite(parsed) ? Number(parsed.toFixed(2)) : 0;
}

function addMonths(date: Date, months: number) {
  const next = new Date(date);
  next.setMonth(next.getMonth() + months);
  return next;
}

function formatMoney(value: number) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(value);
}

function formatDate(date: string) {
  const [year, month, day] = date.slice(0, 10).split("-");
  return `${day}/${month}/${year}`;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}
