# Clinika Flow: The "Aha! Moment" Onboarding

O objetivo do onboarding do Clinika Flow é levar o usuário ao "Moment of Value" (Momento Uau) nos primeiros 10 minutos de uso. Para um fisioterapeuta ou profissional de saúde, esse momento ocorre quando ele percebe que **registrar um atendimento e ver o controle financeiro atualizado é incrivelmente rápido e sem esforço**.

Essa jornada substitui o "tour" tradicional (com telas chatas de pular) por uma **experiência guiada baseada em ação**.

---

## 🚀 O Fluxo de Onboarding (Primeiros 10 minutos)

### 1. Boas-vindas (0 a 1 min)
- **Tela inicial:** "Bem-vindo ao Clinika Flow. Vamos configurar sua clínica em 3 passos rápidos."
- **Ação:** Botão "Começar agora". Sem tutoriais longos, direto para a prática.

### 2. Passo 1: Adicione seu primeiro paciente (1 a 3 min)
- **O que acontece:** O usuário é levado para uma versão simplificada do formulário de "Novo Paciente".
- **Fricção reduzida:** Pedimos apenas **Nome** e **WhatsApp** neste primeiro momento. O restante (anamnese, histórico) fica para depois.
- **Copy:** "Quem você vai atender hoje? Adicione seu primeiro paciente."
- **Recompensa:** Confete rápido na tela. "Paciente adicionado com sucesso!"

### 3. Passo 2: Registre sua primeira sessão (3 a 6 min)
- **O que acontece:** O app imediatamente sugere registrar a primeira sessão para este paciente.
- **O fluxo:**
  - O paciente recém-criado já vem selecionado.
  - O usuário informa o **Grau de Dor** (Slider 0-10) antes e depois.
  - Seleciona uma técnica (ex: *Terapia Manual*).
  - Define um valor da sessão (ex: *R$ 150*).
- **Ação:** Clica em "Salvar Sessão".

### 4. Passo 3: O Dashboard e o "Aha! Moment" (6 a 8 min)
- **O que acontece:** Assim que a sessão é salva, o app redireciona automaticamente para o **Dashboard**.
- **O impacto visual:** Os gráficos disparam e se animam pela primeira vez.
  - **Total de Sessões** muda para **1**.
  - **Receita Total** muda para **R$ 150**.
  - **Pacientes Ativos** muda para **1**.
- **O Call-to-Action / Celebração final:**
  - Uma notificação ou modal de sucesso aparece na tela do Dashboard com a seguinte mensagem de impacto:
  
  > 🎉 **Parabéns! Sua primeira sessão foi registrada.**
  > 
  > 👉 **Você acabou de economizar cerca de 10 minutos de burocracia e planilhas.**  
  > Imagine o quanto de tempo você vai ganhar ao final da semana! O Clinika Flow organiza tudo automaticamente para você focar no que importa: seus pacientes.

---

## 🔗 Próximos Passos (Evolução natural, pós-onboarding)

Após o momento de valor, o usuário já entendeu o benefício principal. A partir daqui, sugerimos tarefas secundárias (através de pequenos cards dispensáveis no topo do Dashboard):

- **🎨 Customize sua Clínica:** "Deixe o aplicativo com as cores e a cara da sua marca." (Leva para as configurações de *Aparência*).
- **📝 Envie sua primeira Anamnese:** "Sabia que o paciente pode preencher os próprios dados pelo celular dele? Experimente enviar um link de anamnese."
- **💬 Configure mensagens prontas:** "Evite que pacientes sumam configurando automações de WhatsApp."

---

## Princípios de Design para esta Tela
- **Progresso visível:** Mostrar uma barra de progresso (Ex: *Passo 2 de 3*).
- **Sem becos sem saída:** Em todo final de ação, deve haver um botão muito claro do que fazer a seguir (Ex: logo após salvar o paciente, o botão proeminente deve ser "Registrar sessão para [Nome]").
- **Estado vazio (Empty States) motivador:** Enquanto o dashboard estiver zerado, os números deveriam ser traços (`-`) e deve haver uma seta apontando "Vamos adicionar sua primeira sessão para ver seus resultados ganharem vida."