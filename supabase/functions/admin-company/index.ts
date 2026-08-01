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

const platformAdminPermissions = new Set(["platform_admin", "admin"]);
const companyStatuses = new Set(["trial", "active", "past_due", "canceled", "blocked"]);
const feedbackStatuses = new Set(["open", "reviewing", "resolved", "archived"]);
const messageTypes = new Set(["info", "billing", "warning", "success"]);
const allowedUserPermissions = new Set([
  "assessor_projetos",
  "assessor_daf",
  "diretor",
  "owner",
  "platform_admin",
]);

type AdminPayload = {
  action?: string;
  company?: {
    id?: string;
    name?: string;
    document?: string;
    plan_slug?: string;
    subscription_status?: string;
    billing_email?: string;
    active?: boolean;
    trial_days?: number | string;
    subscription_ends_at?: string | null;
  };
  master?: {
    name?: string;
    email?: string;
    matricula?: string;
    password?: string;
  };
  payment?: {
    id?: number | string;
    company_id?: string;
    amount?: number | string;
    due_date?: string;
    pix_reference?: string;
    notes?: string;
    period_months?: number | string;
    idempotency_key?: string;
  };
  feedback?: {
    id?: number | string;
    status?: string;
  };
  message?: {
    company_id?: string;
    send_to_all?: boolean;
    title?: string;
    message?: string;
    type?: string;
    expires_at?: string | null;
  };
  user?: {
    id?: string;
    company_id?: string;
    name?: string;
    email?: string;
    matricula?: string;
    role?: string;
    permission?: string;
    password?: string;
    active?: boolean;
  };
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
    const profile = await requirePlatformAdmin(adminClient, token);
    if ("error" in profile) return jsonResponse({ error: profile.error }, profile.status);

    const payload = (await request.json().catch(() => ({}))) as AdminPayload;
    const action = `${payload.action || ""}`.trim();

    if (action === "list_plans") return await listPlans(adminClient);
    if (action === "list_companies") return await listCompanies(adminClient);
    if (action === "create_company") {
      return await createCompany(adminClient, profile.id, payload);
    }
    if (action === "update_company") return await updateCompany(adminClient, payload);
    if (action === "list_payments") return await listPayments(adminClient);
    if (action === "create_payment") {
      return await createPayment(adminClient, profile.id, payload);
    }
    if (action === "mark_payment_paid") return await markPaymentPaid(adminClient, payload);
    if (action === "cancel_payment") return await cancelPayment(adminClient, payload);
    if (action === "list_feedbacks") return await listFeedbacks(adminClient);
    if (action === "update_feedback") return await updateFeedback(adminClient, payload);
    if (action === "list_messages") return await listMessages(adminClient);
    if (action === "create_message") {
      return await createMessage(adminClient, profile.id, payload);
    }
    if (action === "list_users") return await listUsers(adminClient);
    if (action === "create_user") return await createUser(adminClient, payload);
    if (action === "update_user") return await updateUser(adminClient, payload);
    if (action === "update_user_active") return await updateUserActive(adminClient, payload);

    return jsonResponse({ error: "Acao administrativa invalida." }, 400);
  } catch (error) {
    return jsonResponse(
      { error: "Nao foi possivel processar a operacao administrativa." },
      500,
    );
  }
});

async function requirePlatformAdmin(
  adminClient: ReturnType<typeof createClient>,
  token: string,
) {
  const { data: authData, error: authError } = await adminClient.auth.getUser(token);
  if (authError || !authData.user) {
    return { error: "Sessao invalida ou expirada.", status: 401 };
  }

  const { data: profile, error } = await adminClient
    .from("profiles")
    .select("id, permission, active")
    .eq("id", authData.user.id)
    .single();

  if (error || !profile?.active) {
    return { error: "Perfil administrativo nao encontrado.", status: 403 };
  }
  if (!platformAdminPermissions.has(`${profile.permission}`)) {
    return { error: "Somente administradores da plataforma podem acessar.", status: 403 };
  }
  return { id: `${profile.id}` };
}

async function listPlans(adminClient: ReturnType<typeof createClient>) {
  const { data, error } = await adminClient
    .from("plans")
    .select()
    .eq("active", true)
    .order("monthly_price");
  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, plans: data ?? [] });
}

async function listCompanies(adminClient: ReturnType<typeof createClient>) {
  const { data: companies, error } = await adminClient
    .from("companies")
    .select("id, name, document, plan_slug, subscription_status, trial_ends_at, subscription_ends_at, billing_email, active, created_at")
    .order("created_at", { ascending: false })
    .limit(100);
  if (error) return jsonResponse({ error: error.message }, 400);

  const companyIds = (companies ?? []).map((item) => item.id);
  const [profilesResult, projectsResult, paymentsResult] = await Promise.all([
    companyIds.length
      ? adminClient.from("profiles").select("company_id, active").in("company_id", companyIds)
      : Promise.resolve({ data: [] }),
    companyIds.length
      ? adminClient.from("projects").select("company_id, status").in("company_id", companyIds)
      : Promise.resolve({ data: [] }),
    companyIds.length
      ? adminClient.from("manual_payments").select("company_id, status, amount").in("company_id", companyIds)
      : Promise.resolve({ data: [] }),
  ]);

  const usersByCompany = countByCompany(profilesResult.data ?? [], "active");
  const projectsByCompany = countByCompany(projectsResult.data ?? []);
  const pendingByCompany = sumPending(paymentsResult.data ?? []);

  return jsonResponse({
    ok: true,
    companies: (companies ?? []).map((company) => ({
      ...company,
      users_count: usersByCompany.get(company.id) ?? 0,
      projects_count: projectsByCompany.get(company.id) ?? 0,
      pending_amount: pendingByCompany.get(company.id) ?? 0,
    })),
  });
}

async function createCompany(
  adminClient: ReturnType<typeof createClient>,
  createdBy: string,
  payload: AdminPayload,
) {
  const company = normalizeCompany(payload.company ?? {});
  const master = normalizeMaster(payload.master ?? {});
  const validation = validateCreate(company, master);
  if (validation) return jsonResponse({ error: validation }, 400);

  const trialEndsAt = addDays(new Date(), company.trialDays).toISOString();
  const { data: createdCompany, error: companyError } = await adminClient
    .from("companies")
    .insert({
      name: company.name,
      document: company.document,
      plan: company.planSlug,
      plan_slug: company.planSlug,
      subscription_status: company.subscriptionStatus,
      trial_ends_at: company.subscriptionStatus === "trial" ? trialEndsAt : null,
      subscription_ends_at: company.subscriptionStatus === "active" ? trialEndsAt : null,
      billing_email: company.billingEmail,
      billing_provider: "manual",
      billing_notes: `Empresa criada pelo painel admin por ${createdBy}.`,
      active: true,
    })
    .select()
    .single();

  if (companyError || !createdCompany) {
    return jsonResponse({ error: companyError?.message ?? "Empresa nao criada." }, 400);
  }

  await adminClient.from("subscriptions").insert({
    company_id: createdCompany.id,
    plan_slug: company.planSlug,
    status: company.subscriptionStatus,
    provider: "manual",
    current_period_start: new Date().toISOString(),
    current_period_end: trialEndsAt,
    notes: "Assinatura criada pelo painel admin.",
  });

  const { data: user, error: userError } = await adminClient.auth.admin.createUser({
    email: master.email,
    password: master.password,
    email_confirm: true,
      user_metadata: {
        name: master.name,
        matricula: master.matricula,
        role: "Usuario Master",
        permission: "owner",
    },
  });

  if (userError || !user.user) {
    await adminClient.from("companies").delete().eq("id", createdCompany.id);
    return jsonResponse({ error: friendlyAuthError(userError?.message) }, 400);
  }

  const { error: profileError } = await adminClient.from("profiles").insert({
    id: user.user.id,
    company_id: createdCompany.id,
    name: master.name,
    matricula: master.matricula,
    email: master.email,
    role: "Usuario Master",
    permission: "owner",
    active: true,
  });

  if (profileError) {
    await adminClient.auth.admin.deleteUser(user.user.id);
    await adminClient.from("companies").delete().eq("id", createdCompany.id);
    return jsonResponse({ error: profileError.message }, 409);
  }

  return jsonResponse({ ok: true, company: createdCompany, master_email: master.email }, 201);
}

async function updateCompany(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const id = `${payload.company?.id || ""}`.trim();
  if (!id) return jsonResponse({ error: "Empresa invalida." }, 400);

  const planSlug = `${payload.company?.plan_slug || "starter"}`.trim();
  const status = `${payload.company?.subscription_status || "trial"}`.trim();
  const name = `${payload.company?.name || ""}`.trim();
  const document = `${payload.company?.document || ""}`.trim();
  const billingEmail = `${payload.company?.billing_email || ""}`.trim().toLowerCase();
  if (!companyStatuses.has(status)) {
    return jsonResponse({ error: "Status de assinatura invalido." }, 400);
  }
  if (name.length < 3) return jsonResponse({ error: "Informe o nome da empresa." }, 400);
  if (billingEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(billingEmail)) {
    return jsonResponse({ error: "Informe um e-mail de cobranca valido." }, 400);
  }

  const active = payload.company?.active !== false;
  const subscriptionEndsAt = `${payload.company?.subscription_ends_at || ""}`.trim();
  const update = {
    name,
    document,
    plan: planSlug,
    plan_slug: planSlug,
    subscription_status: status,
    billing_email: billingEmail,
    subscription_ends_at: subscriptionEndsAt || null,
    active,
  };

  const { data, error } = await adminClient
    .from("companies")
    .update(update)
    .eq("id", id)
    .select()
    .single();
  if (error || !data) return jsonResponse({ error: "Empresa nao encontrada." }, 404);

  await adminClient
    .from("subscriptions")
    .update({
      plan_slug: planSlug,
      status,
      current_period_end: subscriptionEndsAt || null,
      updated_at: new Date().toISOString(),
    })
    .eq("company_id", id);

  return jsonResponse({ ok: true, company: data });
}

async function listPayments(adminClient: ReturnType<typeof createClient>) {
  const { data, error } = await adminClient
    .from("manual_payments")
    .select("id, company_id, amount, currency, due_date, paid_at, status, pix_reference, notes, created_at, companies(name)")
    .order("created_at", { ascending: false })
    .limit(80);

  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, payments: data ?? [] });
}

async function createPayment(
  adminClient: ReturnType<typeof createClient>,
  createdBy: string,
  payload: AdminPayload,
) {
  const payment = normalizePayment(payload.payment ?? {});
  const validation = validatePayment(payment);
  if (validation) return jsonResponse({ error: validation }, 400);

  const { data: company, error: companyError } = await adminClient
    .from("companies")
    .select("id, name")
    .eq("id", payment.companyId)
    .single();
  if (companyError || !company) return jsonResponse({ error: "Empresa nao encontrada." }, 404);

  const { data: subscription } = await adminClient
    .from("subscriptions")
    .select("id")
    .eq("company_id", payment.companyId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const { data, error } = await adminClient
    .from("manual_payments")
    .insert({
      company_id: payment.companyId,
      subscription_id: subscription?.id ?? null,
      amount: payment.amount,
      due_date: payment.dueDate,
      status: "pending",
      pix_reference: payment.pixReference,
      notes: payment.notes,
      created_by: createdBy,
      idempotency_key: payment.idempotencyKey || null,
    })
    .select()
    .single();

  if (error || !data) {
    if (
      `${error?.message || ""}`.includes("manual_payments_idempotency_key_unique") ||
      `${error?.code || ""}` === "23505"
    ) {
      return jsonResponse({ error: "Esta cobranca ja foi registrada." }, 409);
    }
    return jsonResponse({ error: error?.message ?? "Cobranca nao criada." }, 400);
  }

  await createAppMessage(adminClient, {
    companyId: payment.companyId,
    paymentId: data.id,
    createdBy,
    type: "billing",
    title: "Cobrança Pix pendente",
    message:
      `Existe uma cobrança de ${formatMoney(payment.amount)} com vencimento em ${formatDate(payment.dueDate)}.` +
      (payment.pixReference ? ` Referência Pix: ${payment.pixReference}.` : ""),
  });

  return jsonResponse({ ok: true, payment: data }, 201);
}

async function markPaymentPaid(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const paymentId = Number(payload.payment?.id ?? 0);
  if (!Number.isInteger(paymentId) || paymentId <= 0) {
    return jsonResponse({ error: "Cobranca invalida." }, 400);
  }

  const periodMonths = Math.max(1, Math.min(24, Number(payload.payment?.period_months ?? 1)));
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
    .eq("id", payment.company_id);

  await adminClient
    .from("subscriptions")
    .update({
      status: "active",
      provider: "manual",
      current_period_start: now.toISOString(),
      current_period_end: periodEnd,
      updated_at: now.toISOString(),
    })
    .eq("company_id", payment.company_id);

  await createAppMessage(adminClient, {
    companyId: payment.company_id,
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
  payload: AdminPayload,
) {
  const paymentId = Number(payload.payment?.id ?? 0);
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
    .select()
    .single();

  if (error || !data) return jsonResponse({ error: "Cobranca nao encontrada." }, 404);

  await createAppMessage(adminClient, {
    companyId: data.company_id,
    paymentId: data.id,
    type: "info",
    title: "Cobrança cancelada",
    message: `A cobrança #${data.id} foi cancelada e não precisa ser paga.`,
  });

  return jsonResponse({ ok: true, payment: data });
}

async function listFeedbacks(adminClient: ReturnType<typeof createClient>) {
  const { data, error } = await adminClient
    .from("beta_feedback")
    .select("id, company_id, profile_id, rating, area, message, status, app_version, device_info, created_at, resolved_at, companies(name), profiles(name, email)")
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, feedbacks: data ?? [] });
}

async function updateFeedback(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const feedbackId = Number(payload.feedback?.id ?? 0);
  const status = `${payload.feedback?.status || ""}`.trim();
  if (!Number.isInteger(feedbackId) || feedbackId <= 0) {
    return jsonResponse({ error: "Chamado invalido." }, 400);
  }
  if (!feedbackStatuses.has(status)) {
    return jsonResponse({ error: "Status do chamado invalido." }, 400);
  }

  const { data, error } = await adminClient
    .from("beta_feedback")
    .update({
      status,
      resolved_at: status === "resolved" ? new Date().toISOString() : null,
    })
    .eq("id", feedbackId)
    .select()
    .single();

  if (error || !data) return jsonResponse({ error: "Chamado nao encontrado." }, 404);
  return jsonResponse({ ok: true, feedback: data });
}

async function listMessages(adminClient: ReturnType<typeof createClient>) {
  const { data, error } = await adminClient
    .from("app_messages")
    .select("id, company_id, payment_id, title, message, type, status, created_at, read_at, expires_at, companies(name)")
    .order("created_at", { ascending: false })
    .limit(120);

  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, messages: data ?? [] });
}

async function listUsers(adminClient: ReturnType<typeof createClient>) {
  const { data, error } = await adminClient
    .from("profiles")
    .select("id, company_id, name, email, matricula, role, permission, active, created_at, companies(name)")
    .order("created_at", { ascending: false })
    .limit(200);

  if (error) return jsonResponse({ error: error.message }, 400);
  return jsonResponse({ ok: true, users: data ?? [] });
}

async function createUser(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const user = normalizeUser(payload.user ?? {});
  const validation = validateUser(user);
  if (validation) return jsonResponse({ error: validation }, 400);

  const limitError = await validateCompanyUserLimit(adminClient, user.companyId);
  if (limitError) return jsonResponse({ error: limitError }, 403);

  const { data: company, error: companyError } = await adminClient
    .from("companies")
    .select("id")
    .eq("id", user.companyId)
    .single();
  if (companyError || !company) return jsonResponse({ error: "Empresa nao encontrada." }, 404);

  const { data: created, error: createError } =
    await adminClient.auth.admin.createUser({
      email: user.email,
      password: user.password,
      email_confirm: true,
      user_metadata: {
        name: user.name,
        matricula: user.matricula,
        role: user.role,
        permission: user.permission,
      },
    });

  if (createError || !created.user) {
    return jsonResponse({ error: friendlyAuthError(createError?.message) }, 400);
  }

  const { error: profileError } = await adminClient.from("profiles").insert({
    id: created.user.id,
    company_id: user.companyId,
    name: user.name,
    matricula: user.matricula,
    email: user.email,
    role: user.role,
    permission: user.permission,
    active: true,
  });

  if (profileError) {
    await adminClient.auth.admin.deleteUser(created.user.id);
    return jsonResponse({ error: profileError.message }, 409);
  }

  return jsonResponse({ ok: true, user: { id: created.user.id, email: user.email } }, 201);
}

async function updateUser(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const user = normalizeUser(payload.user ?? {});
  if (!user.id) return jsonResponse({ error: "Usuario invalido." }, 400);
  if (!user.companyId) return jsonResponse({ error: "Selecione a empresa." }, 400);
  if (user.name.length < 3) return jsonResponse({ error: "Informe o nome do usuario." }, 400);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(user.email)) {
    return jsonResponse({ error: "Informe um e-mail valido." }, 400);
  }
  if (user.matricula.length < 3) return jsonResponse({ error: "Informe uma matricula." }, 400);
  if (!allowedUserPermissions.has(user.permission)) return jsonResponse({ error: "Permissao invalida." }, 400);
  if (user.password && user.password.length < 8) {
    return jsonResponse({ error: "A senha deve ter pelo menos 8 caracteres." }, 400);
  }

  const authUpdate: Record<string, unknown> = {
    email: user.email,
    user_metadata: {
      name: user.name,
      matricula: user.matricula,
      role: user.role,
      permission: user.permission,
    },
  };
  if (user.password) authUpdate.password = user.password;

  const { error: authError } = await adminClient.auth.admin.updateUserById(
    user.id,
    authUpdate,
  );
  if (authError) return jsonResponse({ error: friendlyAuthError(authError.message) }, 400);

  const { data, error } = await adminClient
    .from("profiles")
    .update({
      company_id: user.companyId,
      name: user.name,
      email: user.email,
      matricula: user.matricula,
      role: user.role,
      permission: user.permission,
      active: user.active,
    })
    .eq("id", user.id)
    .select()
    .single();

  if (error || !data) return jsonResponse({ error: "Usuario nao encontrado." }, 404);
  return jsonResponse({ ok: true, user: data });
}

async function updateUserActive(
  adminClient: ReturnType<typeof createClient>,
  payload: AdminPayload,
) {
  const userId = `${payload.user?.id || ""}`.trim();
  if (!userId) return jsonResponse({ error: "Usuario invalido." }, 400);
  const active = payload.user?.active !== false;

  const { data, error } = await adminClient
    .from("profiles")
    .update({ active })
    .eq("id", userId)
    .select()
    .single();

  if (error || !data) return jsonResponse({ error: "Usuario nao encontrado." }, 404);
  return jsonResponse({ ok: true, user: data });
}

async function createMessage(
  adminClient: ReturnType<typeof createClient>,
  createdBy: string,
  payload: AdminPayload,
) {
  const message = normalizeMessage(payload.message ?? {});
  const validation = validateMessage(message);
  if (validation) return jsonResponse({ error: validation }, 400);

  if (message.sendToAll) {
    const { data: companies, error: companiesError } = await adminClient
      .from("companies")
      .select("id")
      .eq("active", true);
    if (companiesError) return jsonResponse({ error: companiesError.message }, 400);

    const rows = (companies ?? []).map((company) => ({
      company_id: company.id,
      created_by: createdBy,
      type: message.type,
      title: message.title,
      message: message.body,
      status: "unread",
      expires_at: message.expiresAt || null,
    }));
    if (!rows.length) return jsonResponse({ error: "Nenhuma empresa ativa encontrada." }, 400);

    const { error } = await adminClient.from("app_messages").insert(rows);
    if (error) return jsonResponse({ error: error.message }, 400);
    return jsonResponse({ ok: true, created: rows.length }, 201);
  }

  const { data: company, error: companyError } = await adminClient
    .from("companies")
    .select("id")
    .eq("id", message.companyId)
    .single();
  if (companyError || !company) return jsonResponse({ error: "Empresa nao encontrada." }, 404);

  await createAppMessage(adminClient, {
    companyId: message.companyId,
    createdBy,
    type: message.type,
    title: message.title,
    message: message.body,
    expiresAt: message.expiresAt || null,
  });

  return jsonResponse({ ok: true, created: 1 }, 201);
}

function normalizeCompany(company: NonNullable<AdminPayload["company"]>) {
  return {
    name: `${company.name || ""}`.trim(),
    document: `${company.document || ""}`.trim(),
    planSlug: `${company.plan_slug || "starter"}`.trim(),
    subscriptionStatus: `${company.subscription_status || "trial"}`.trim(),
    billingEmail: `${company.billing_email || ""}`.trim().toLowerCase(),
    trialDays: Math.max(1, Math.min(365, Number(company.trial_days ?? 14))),
  };
}

function normalizeMaster(master: NonNullable<AdminPayload["master"]>) {
  return {
    name: `${master.name || ""}`.trim(),
    email: `${master.email || ""}`.trim().toLowerCase(),
    matricula: `${master.matricula || ""}`.trim(),
    password: `${master.password || ""}`.trim(),
  };
}

function normalizePayment(payment: NonNullable<AdminPayload["payment"]>) {
  return {
    id: Number(payment.id ?? 0),
    companyId: `${payment.company_id || ""}`.trim(),
    amount: toMoney(payment.amount),
    dueDate: `${payment.due_date || ""}`.trim(),
    pixReference: `${payment.pix_reference || ""}`.trim(),
    notes: `${payment.notes || ""}`.trim(),
    idempotencyKey: `${payment.idempotency_key || ""}`.trim(),
  };
}

function normalizeMessage(message: NonNullable<AdminPayload["message"]>) {
  return {
    companyId: `${message.company_id || ""}`.trim(),
    sendToAll: message.send_to_all === true,
    title: `${message.title || ""}`.trim(),
    body: `${message.message || ""}`.trim(),
    type: `${message.type || "info"}`.trim(),
    expiresAt: `${message.expires_at || ""}`.trim(),
  };
}

function normalizeUser(user: NonNullable<AdminPayload["user"]>) {
  const permission = `${user.permission || "assessor_projetos"}`.trim();
  return {
    id: `${user.id || ""}`.trim(),
    companyId: `${user.company_id || ""}`.trim(),
    name: `${user.name || ""}`.trim(),
    email: `${user.email || ""}`.trim().toLowerCase(),
    matricula: `${user.matricula || ""}`.trim(),
    role: `${user.role || defaultRole(permission)}`.trim(),
    permission,
    password: `${user.password || ""}`.trim(),
    active: user.active !== false,
  };
}

function validateCreate(
  company: ReturnType<typeof normalizeCompany>,
  master: ReturnType<typeof normalizeMaster>,
) {
  if (company.name.length < 3) return "Informe o nome da empresa.";
  if (!companyStatuses.has(company.subscriptionStatus)) {
    return "Status de assinatura invalido.";
  }
  if (master.name.length < 3) return "Informe o nome do usuario master.";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(master.email)) {
    return "Informe um e-mail valido para o master.";
  }
  if (master.matricula.length < 3) return "Informe uma matricula do master.";
  if (master.password.length < 8) return "A senha do master deve ter pelo menos 8 caracteres.";
  return "";
}

function validatePayment(payment: ReturnType<typeof normalizePayment>) {
  if (!payment.companyId) return "Selecione a empresa.";
  if (payment.amount <= 0) return "Informe um valor valido.";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(payment.dueDate)) {
    return "Informe vencimento no formato YYYY-MM-DD.";
  }
  return "";
}

function validateMessage(message: ReturnType<typeof normalizeMessage>) {
  if (!message.sendToAll && !message.companyId) return "Selecione a empresa.";
  if (message.title.length < 3) return "Informe um titulo para o comunicado.";
  if (message.body.length < 8) return "Escreva uma mensagem mais completa.";
  if (!messageTypes.has(message.type)) return "Tipo de mensagem invalido.";
  if (message.expiresAt && !/^\d{4}-\d{2}-\d{2}$/.test(message.expiresAt)) {
    return "Informe expiracao no formato YYYY-MM-DD.";
  }
  return "";
}

function validateUser(user: ReturnType<typeof normalizeUser>) {
  if (!user.companyId) return "Selecione a empresa.";
  if (user.name.length < 3) return "Informe o nome do usuario.";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(user.email)) {
    return "Informe um e-mail valido.";
  }
  if (user.matricula.length < 3) return "Informe uma matricula.";
  if (!allowedUserPermissions.has(user.permission)) return "Permissao invalida.";
  if (user.password.length < 8) return "A senha deve ter pelo menos 8 caracteres.";
  return "";
}

async function validateCompanyUserLimit(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
) {
  const { data: billing } = await adminClient
    .from("company_billing_overview")
    .select("max_users, plan_name")
    .eq("company_id", companyId)
    .single();

  const maxUsers = billing?.max_users as number | null | undefined;
  if (maxUsers === null || maxUsers === undefined) return "";

  const { count, error } = await adminClient
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .eq("company_id", companyId)
    .eq("active", true);

  if (error) return "Nao foi possivel validar limite de usuarios.";
  if ((count ?? 0) >= maxUsers) {
    return `Limite de usuarios do plano ${billing?.plan_name ?? ""} atingido.`;
  }
  return "";
}

function defaultRole(permission: string) {
  return ({
    assessor_projetos: "Assessor de Projetos",
    assessor_daf: "Assessor DAF",
    diretor: "Diretor",
    owner: "Usuario Master",
    platform_admin: "Administrador da Plataforma",
  } as Record<string, string>)[permission] ?? "Assessor de Projetos";
}

function countByCompany(rows: Array<Record<string, unknown>>, activeField = "") {
  const counts = new Map<string, number>();
  for (const row of rows) {
    if (activeField && row[activeField] === false) continue;
    const companyId = `${row.company_id || ""}`;
    counts.set(companyId, (counts.get(companyId) ?? 0) + 1);
  }
  return counts;
}

function sumPending(rows: Array<Record<string, unknown>>) {
  const sums = new Map<string, number>();
  for (const row of rows) {
    if (!["pending", "overdue"].includes(`${row.status}`)) continue;
    const companyId = `${row.company_id || ""}`;
    const amount = Number(row.amount ?? 0);
    sums.set(companyId, (sums.get(companyId) ?? 0) + (Number.isFinite(amount) ? amount : 0));
  }
  return sums;
}

function addDays(date: Date, days: number) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function addMonths(date: Date, months: number) {
  const next = new Date(date);
  next.setMonth(next.getMonth() + months);
  return next;
}

function toMoney(value: unknown) {
  if (typeof value === "number") return Number(value.toFixed(2));
  const text = `${value ?? ""}`.replace(",", ".").trim();
  const parsed = Number(text);
  return Number.isFinite(parsed) ? Number(parsed.toFixed(2)) : 0;
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
    expiresAt?: string | null;
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
    expires_at: params.expiresAt ?? null,
  });
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

function bearerToken(request: Request) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? "";
}

function friendlyAuthError(message = "") {
  const normalized = message.toLowerCase();
  if (normalized.includes("already")) return "Este e-mail ja esta cadastrado.";
  if (normalized.includes("password")) return "Senha invalida ou fraca.";
  return message || "Nao foi possivel criar usuario master.";
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
