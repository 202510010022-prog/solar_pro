enum AdminSection { overview, companies, users, payments, feedbacks, messages }

extension AdminSectionInfo on AdminSection {
  String get title {
    return switch (this) {
      AdminSection.overview => 'Visão geral',
      AdminSection.companies => 'Empresas',
      AdminSection.users => 'Empresas e usuários',
      AdminSection.payments => 'Cobranças Pix',
      AdminSection.feedbacks => 'Feedbacks e chamados',
      AdminSection.messages => 'Mensagens',
    };
  }

  String get subtitle {
    return switch (this) {
      AdminSection.overview => 'Relatórios, receita, conversão e uso.',
      AdminSection.companies => 'Cadastro, planos e status das empresas.',
      AdminSection.users => 'Dados da empresa, dependentes e acessos.',
      AdminSection.payments => 'Cobranças, pagamentos e inadimplência.',
      AdminSection.feedbacks => 'Chamados enviados pelo app cliente.',
      AdminSection.messages => 'Comunicados enviados ao aplicativo.',
    };
  }
}
