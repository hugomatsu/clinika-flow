import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Kelyn Physio'**
  String get appTitle;

  /// No description provided for @patients.
  ///
  /// In pt, this message translates to:
  /// **'Pacientes'**
  String get patients;

  /// No description provided for @appointments.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get appointments;

  /// No description provided for @dashboard.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @newPatient.
  ///
  /// In pt, this message translates to:
  /// **'Novo Paciente'**
  String get newPatient;

  /// No description provided for @editPatient.
  ///
  /// In pt, this message translates to:
  /// **'Editar Paciente'**
  String get editPatient;

  /// No description provided for @patientDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Paciente'**
  String get patientDetails;

  /// No description provided for @noPatients.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum paciente cadastrado.\nToque em + para adicionar.'**
  String get noPatients;

  /// No description provided for @searchPatients.
  ///
  /// In pt, this message translates to:
  /// **'Buscar pacientes...'**
  String get searchPatients;

  /// No description provided for @name.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @dateOfBirth.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento'**
  String get dateOfBirth;

  /// No description provided for @occupation.
  ///
  /// In pt, this message translates to:
  /// **'Profissão'**
  String get occupation;

  /// No description provided for @emergencyContact.
  ///
  /// In pt, this message translates to:
  /// **'Contato de emergência'**
  String get emergencyContact;

  /// No description provided for @posturalAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese postural'**
  String get posturalAnamnesis;

  /// No description provided for @injuryHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de lesões'**
  String get injuryHistory;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @archive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get archive;

  /// No description provided for @reactivate.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get reactivate;

  /// No description provided for @statusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get statusInactive;

  /// No description provided for @statusArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get statusArchived;

  /// No description provided for @patientStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get patientStatus;

  /// No description provided for @all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @newAppointment.
  ///
  /// In pt, this message translates to:
  /// **'Nova Consulta'**
  String get newAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In pt, this message translates to:
  /// **'Editar Consulta'**
  String get editAppointment;

  /// No description provided for @noAppointments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma consulta agendada.'**
  String get noAppointments;

  /// No description provided for @appointmentDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get appointmentDate;

  /// No description provided for @appointmentTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get appointmentTime;

  /// No description provided for @duration.
  ///
  /// In pt, this message translates to:
  /// **'Duração (minutos)'**
  String get duration;

  /// No description provided for @notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get notes;

  /// No description provided for @statusScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendada'**
  String get statusScheduled;

  /// No description provided for @statusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluída'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get statusCancelled;

  /// No description provided for @statusRescheduled.
  ///
  /// In pt, this message translates to:
  /// **'Reagendada'**
  String get statusRescheduled;

  /// No description provided for @appointmentStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get appointmentStatus;

  /// No description provided for @selectPatient.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Paciente'**
  String get selectPatient;

  /// No description provided for @patient.
  ///
  /// In pt, this message translates to:
  /// **'Paciente'**
  String get patient;

  /// No description provided for @recordSession.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Sessão'**
  String get recordSession;

  /// No description provided for @sessionDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Sessão'**
  String get sessionDetails;

  /// No description provided for @noSessions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sessão registrada.'**
  String get noSessions;

  /// No description provided for @sessionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Sessões'**
  String get sessionHistory;

  /// No description provided for @prePainScore.
  ///
  /// In pt, this message translates to:
  /// **'Dor antes da sessão (0–10)'**
  String get prePainScore;

  /// No description provided for @postPainScore.
  ///
  /// In pt, this message translates to:
  /// **'Dor após a sessão (0–10)'**
  String get postPainScore;

  /// No description provided for @techniquesApplied.
  ///
  /// In pt, this message translates to:
  /// **'Técnicas aplicadas'**
  String get techniquesApplied;

  /// No description provided for @sessionObservations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get sessionObservations;

  /// No description provided for @painReduction.
  ///
  /// In pt, this message translates to:
  /// **'Redução de dor'**
  String get painReduction;

  /// No description provided for @totalPatients.
  ///
  /// In pt, this message translates to:
  /// **'Total de pacientes'**
  String get totalPatients;

  /// No description provided for @activePatients.
  ///
  /// In pt, this message translates to:
  /// **'Pacientes ativos'**
  String get activePatients;

  /// No description provided for @totalSessions.
  ///
  /// In pt, this message translates to:
  /// **'Total de sessões'**
  String get totalSessions;

  /// No description provided for @totalRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Receita total'**
  String get totalRevenue;

  /// No description provided for @pendingPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos pendentes'**
  String get pendingPayments;

  /// No description provided for @averagePainReduction.
  ///
  /// In pt, this message translates to:
  /// **'Redução média de dor'**
  String get averagePainReduction;

  /// No description provided for @branding.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get branding;

  /// No description provided for @primaryColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor primária'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor secundária'**
  String get secondaryColor;

  /// No description provided for @accentColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor de destaque'**
  String get accentColor;

  /// No description provided for @darkMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo escuro'**
  String get darkMode;

  /// No description provided for @colorSaved.
  ///
  /// In pt, this message translates to:
  /// **'Aparência salva com sucesso!'**
  String get colorSaved;

  /// No description provided for @fieldRequired.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido'**
  String get invalidEmail;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @notInformed.
  ///
  /// In pt, this message translates to:
  /// **'Não informado'**
  String get notInformed;

  /// No description provided for @paymentStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status de pagamento'**
  String get paymentStatus;

  /// No description provided for @paymentPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get paymentPaid;

  /// No description provided for @paymentPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get paymentPending;

  /// No description provided for @paymentPackage.
  ///
  /// In pt, this message translates to:
  /// **'Pacote'**
  String get paymentPackage;

  /// No description provided for @paymentOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get paymentOverdue;

  /// No description provided for @amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$)'**
  String get amount;

  /// No description provided for @confirmDelete.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão'**
  String get confirmDelete;

  /// No description provided for @deletePatientConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir este paciente? Esta ação não pode ser desfeita.'**
  String get deletePatientConfirm;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @reminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete ativo'**
  String get reminder;

  /// No description provided for @sessionSaved.
  ///
  /// In pt, this message translates to:
  /// **'Sessão registrada com sucesso!'**
  String get sessionSaved;

  /// No description provided for @appointmentSaved.
  ///
  /// In pt, this message translates to:
  /// **'Consulta salva com sucesso!'**
  String get appointmentSaved;

  /// No description provided for @patientSaved.
  ///
  /// In pt, this message translates to:
  /// **'Paciente salvo com sucesso!'**
  String get patientSaved;

  /// No description provided for @patientArchived.
  ///
  /// In pt, this message translates to:
  /// **'Paciente arquivado.'**
  String get patientArchived;

  /// No description provided for @patientReactivated.
  ///
  /// In pt, this message translates to:
  /// **'Paciente reativado.'**
  String get patientReactivated;

  /// No description provided for @techniques.
  ///
  /// In pt, this message translates to:
  /// **'Técnicas'**
  String get techniques;

  /// No description provided for @noTechniquesSelected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma técnica selecionada'**
  String get noTechniquesSelected;

  /// No description provided for @vasScore.
  ///
  /// In pt, this message translates to:
  /// **'Escala VAS'**
  String get vasScore;

  /// No description provided for @preSession.
  ///
  /// In pt, this message translates to:
  /// **'Pré-sessão'**
  String get preSession;

  /// No description provided for @postSession.
  ///
  /// In pt, this message translates to:
  /// **'Pós-sessão'**
  String get postSession;

  /// No description provided for @sessions.
  ///
  /// In pt, this message translates to:
  /// **'Sessões'**
  String get sessions;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Faça login para acessar sua clínica'**
  String get loginSubtitle;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get register;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não tem conta? Cadastre-se'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem conta? Entrar'**
  String get hasAccount;

  /// No description provided for @passwordResetSent.
  ///
  /// In pt, this message translates to:
  /// **'E-mail de redefinição enviado!'**
  String get passwordResetSent;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @loginError.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos'**
  String get loginError;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMsg.
  ///
  /// In pt, this message translates to:
  /// **'Deseja encerrar a sessão?'**
  String get logoutConfirmMsg;

  /// No description provided for @clinicName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da clínica'**
  String get clinicName;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @colorPreview.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização'**
  String get colorPreview;

  /// No description provided for @resetDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get resetDefaults;

  /// No description provided for @themeColors.
  ///
  /// In pt, this message translates to:
  /// **'Cores do tema'**
  String get themeColors;

  /// No description provided for @account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get account;

  /// No description provided for @weekView.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get weekView;

  /// No description provided for @dayView.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get dayView;

  /// No description provided for @weekConsultsDone.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total} concluídas'**
  String weekConsultsDone(int done, int total);

  /// No description provided for @filter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get filter;

  /// No description provided for @viewSession.
  ///
  /// In pt, this message translates to:
  /// **'Ver sessão'**
  String get viewSession;

  /// No description provided for @templates.
  ///
  /// In pt, this message translates to:
  /// **'Modelos'**
  String get templates;

  /// No description provided for @newTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Novo Modelo'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Editar Modelo'**
  String get editTemplate;

  /// No description provided for @noTemplates.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum modelo criado.'**
  String get noTemplates;

  /// No description provided for @templateName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do modelo'**
  String get templateName;

  /// No description provided for @templateDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get templateDescription;

  /// No description provided for @templateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Modelo salvo com sucesso!'**
  String get templateSaved;

  /// No description provided for @templateDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Modelo excluído.'**
  String get templateDeleted;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir este modelo? Sessões já registradas não serão afetadas.'**
  String get deleteTemplateConfirm;

  /// No description provided for @setAsDefault.
  ///
  /// In pt, this message translates to:
  /// **'Definir como padrão'**
  String get setAsDefault;

  /// No description provided for @defaultTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get defaultTemplate;

  /// No description provided for @builtIn.
  ///
  /// In pt, this message translates to:
  /// **'Embutido'**
  String get builtIn;

  /// No description provided for @duplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get duplicate;

  /// No description provided for @preview.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualizar'**
  String get preview;

  /// No description provided for @addField.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar campo'**
  String get addField;

  /// No description provided for @fieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rótulo do campo'**
  String get fieldLabel;

  /// No description provided for @fieldSlider.
  ///
  /// In pt, this message translates to:
  /// **'Controle deslizante'**
  String get fieldSlider;

  /// No description provided for @fieldTextField.
  ///
  /// In pt, this message translates to:
  /// **'Campo de texto'**
  String get fieldTextField;

  /// No description provided for @fieldLabelType.
  ///
  /// In pt, this message translates to:
  /// **'Texto estático'**
  String get fieldLabelType;

  /// No description provided for @fieldTags.
  ///
  /// In pt, this message translates to:
  /// **'Tags / Chips'**
  String get fieldTags;

  /// No description provided for @fieldComboBox.
  ///
  /// In pt, this message translates to:
  /// **'Lista suspensa'**
  String get fieldComboBox;

  /// No description provided for @fieldImage.
  ///
  /// In pt, this message translates to:
  /// **'Captura de imagem'**
  String get fieldImage;

  /// No description provided for @fieldCheckbox.
  ///
  /// In pt, this message translates to:
  /// **'Caixas de seleção'**
  String get fieldCheckbox;

  /// No description provided for @minimum.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get maximum;

  /// No description provided for @step.
  ///
  /// In pt, this message translates to:
  /// **'Incremento'**
  String get step;

  /// No description provided for @unit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get unit;

  /// No description provided for @multiline.
  ///
  /// In pt, this message translates to:
  /// **'Múltiplas linhas'**
  String get multiline;

  /// No description provided for @maxLength.
  ///
  /// In pt, this message translates to:
  /// **'Limite de caracteres'**
  String get maxLength;

  /// No description provided for @options.
  ///
  /// In pt, this message translates to:
  /// **'Opções'**
  String get options;

  /// No description provided for @addOption.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar opção'**
  String get addOption;

  /// No description provided for @allowCustomTags.
  ///
  /// In pt, this message translates to:
  /// **'Permitir tags personalizadas'**
  String get allowCustomTags;

  /// No description provided for @requireAll.
  ///
  /// In pt, this message translates to:
  /// **'Exigir todos'**
  String get requireAll;

  /// No description provided for @imageHint.
  ///
  /// In pt, this message translates to:
  /// **'Instrução para foto'**
  String get imageHint;

  /// No description provided for @requiredField.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get requiredField;

  /// No description provided for @selectTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar modelo'**
  String get selectTemplate;

  /// No description provided for @versionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String versionLabel(int version);

  /// No description provided for @fieldCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} campos'**
  String fieldCount(int count);

  /// No description provided for @profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In pt, this message translates to:
  /// **'Nome de exibição'**
  String get displayName;

  /// No description provided for @changePassword.
  ///
  /// In pt, this message translates to:
  /// **'Alterar senha'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova senha'**
  String get confirmNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso!'**
  String get passwordChanged;

  /// No description provided for @passwordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get passwordMismatch;

  /// No description provided for @profileSaved.
  ///
  /// In pt, this message translates to:
  /// **'Perfil salvo com sucesso!'**
  String get profileSaved;

  /// No description provided for @wrongPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual incorreta'**
  String get wrongPassword;

  /// No description provided for @camera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get gallery;

  /// No description provided for @addPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get addPhoto;

  /// No description provided for @fieldSubTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Sub-modelo'**
  String get fieldSubTemplate;

  /// No description provided for @subTemplateSelect.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar modelo vinculado'**
  String get subTemplateSelect;

  /// No description provided for @displayMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo de exibição'**
  String get displayMode;

  /// No description provided for @displayModePage.
  ///
  /// In pt, this message translates to:
  /// **'Página separada'**
  String get displayModePage;

  /// No description provided for @displayModeInline.
  ///
  /// In pt, this message translates to:
  /// **'Embutido'**
  String get displayModeInline;

  /// No description provided for @openSubTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Abrir formulário'**
  String get openSubTemplate;

  /// No description provided for @subTemplateCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Preenchido'**
  String get subTemplateCompleted;

  /// No description provided for @noTemplateSelected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum modelo selecionado'**
  String get noTemplateSelected;

  /// No description provided for @anamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese'**
  String get anamnesis;

  /// No description provided for @fillAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Preencher'**
  String get fillAnamnesis;

  /// No description provided for @editAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editAnamnesis;

  /// No description provided for @anamnesisSaved.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese salva com sucesso!'**
  String get anamnesisSaved;

  /// No description provided for @sessionHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de sessões'**
  String get sessionHistoryTitle;

  /// No description provided for @fieldToggle.
  ///
  /// In pt, this message translates to:
  /// **'Alternância'**
  String get fieldToggle;

  /// No description provided for @painScore.
  ///
  /// In pt, this message translates to:
  /// **'Dor: {pre} → {post}'**
  String painScore(int pre, int post);

  /// No description provided for @fieldLibrary.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca de campos'**
  String get fieldLibrary;

  /// No description provided for @searchFields.
  ///
  /// In pt, this message translates to:
  /// **'Buscar campos...'**
  String get searchFields;

  /// No description provided for @customField.
  ///
  /// In pt, this message translates to:
  /// **'Campo personalizado'**
  String get customField;

  /// No description provided for @popular.
  ///
  /// In pt, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @sendAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get sendAnamnesis;

  /// No description provided for @anamnesisSent.
  ///
  /// In pt, this message translates to:
  /// **'Link de anamnese criado!'**
  String get anamnesisSent;

  /// No description provided for @anamnesisStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando preenchimento'**
  String get anamnesisStatusPending;

  /// No description provided for @anamnesisStatusOpened.
  ///
  /// In pt, this message translates to:
  /// **'Paciente abriu o formulário'**
  String get anamnesisStatusOpened;

  /// No description provided for @anamnesisStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese preenchida'**
  String get anamnesisStatusCompleted;

  /// No description provided for @anamnesisExpired.
  ///
  /// In pt, this message translates to:
  /// **'Este link expirou'**
  String get anamnesisExpired;

  /// No description provided for @anamnesisInvalidLink.
  ///
  /// In pt, this message translates to:
  /// **'Link inválido ou expirado'**
  String get anamnesisInvalidLink;

  /// No description provided for @anamnesisSubmitted.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese enviada com sucesso!'**
  String get anamnesisSubmitted;

  /// No description provided for @anamnesisSubmittedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Suas respostas foram salvas. Você pode fechar esta página.'**
  String get anamnesisSubmittedDesc;

  /// No description provided for @anamnesisFormTitle.
  ///
  /// In pt, this message translates to:
  /// **'Anamnese'**
  String get anamnesisFormTitle;

  /// No description provided for @submitAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get submitAnamnesis;

  /// No description provided for @anamnesisLinkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado!'**
  String get anamnesisLinkCopied;

  /// No description provided for @shareAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar link'**
  String get shareAnamnesis;

  /// No description provided for @resendAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar link'**
  String get resendAnamnesis;

  /// No description provided for @copyLink.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get copyLink;

  /// No description provided for @anamnesisReadOnly.
  ///
  /// In pt, this message translates to:
  /// **'Esta anamnese já foi preenchida.'**
  String get anamnesisReadOnly;

  /// No description provided for @clinicLogo.
  ///
  /// In pt, this message translates to:
  /// **'Logo da clínica'**
  String get clinicLogo;

  /// No description provided for @removeLogo.
  ///
  /// In pt, this message translates to:
  /// **'Remover logo'**
  String get removeLogo;

  /// No description provided for @tapToAddLogo.
  ///
  /// In pt, this message translates to:
  /// **'Toque para adicionar o logo'**
  String get tapToAddLogo;

  /// No description provided for @fieldCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$)'**
  String get fieldCurrency;

  /// No description provided for @whatsapp.
  ///
  /// In pt, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @instagram.
  ///
  /// In pt, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @settingsShort.
  ///
  /// In pt, this message translates to:
  /// **'Config.'**
  String get settingsShort;

  /// No description provided for @defaultSessionModel.
  ///
  /// In pt, this message translates to:
  /// **'Modelo padrão de sessão'**
  String get defaultSessionModel;

  /// No description provided for @defaultAnamnesisModel.
  ///
  /// In pt, this message translates to:
  /// **'Modelo padrão de anamnese'**
  String get defaultAnamnesisModel;

  /// No description provided for @none.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get none;

  /// No description provided for @spentTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo gasto (min)'**
  String get spentTime;

  /// No description provided for @sessionNotes.
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get sessionNotes;

  /// No description provided for @paidPrice.
  ///
  /// In pt, this message translates to:
  /// **'Valor pago'**
  String get paidPrice;

  /// No description provided for @monthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get annual;

  /// No description provided for @newPatients.
  ///
  /// In pt, this message translates to:
  /// **'Novos pacientes'**
  String get newPatients;

  /// No description provided for @recurringPatients.
  ///
  /// In pt, this message translates to:
  /// **'Pacientes recorrentes'**
  String get recurringPatients;

  /// No description provided for @totalReceived.
  ///
  /// In pt, this message translates to:
  /// **'Total recebido'**
  String get totalReceived;

  /// No description provided for @bestWeek.
  ///
  /// In pt, this message translates to:
  /// **'Melhor semana'**
  String get bestWeek;

  /// No description provided for @bestWeekSessions.
  ///
  /// In pt, this message translates to:
  /// **'Melhor semana (sessões)'**
  String get bestWeekSessions;

  /// No description provided for @finance.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get finance;

  /// No description provided for @subscription.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura'**
  String get subscription;

  /// No description provided for @currentPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano atual'**
  String get currentPlan;

  /// No description provided for @upgradePlan.
  ///
  /// In pt, this message translates to:
  /// **'Alterar plano'**
  String get upgradePlan;

  /// No description provided for @freeTier.
  ///
  /// In pt, this message translates to:
  /// **'Grátis'**
  String get freeTier;

  /// No description provided for @essentialTier.
  ///
  /// In pt, this message translates to:
  /// **'Essencial'**
  String get essentialTier;

  /// No description provided for @professionalTier.
  ///
  /// In pt, this message translates to:
  /// **'Profissional'**
  String get professionalTier;

  /// No description provided for @clinicTier.
  ///
  /// In pt, this message translates to:
  /// **'Clínica'**
  String get clinicTier;

  /// No description provided for @perMonth.
  ///
  /// In pt, this message translates to:
  /// **'/mês'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In pt, this message translates to:
  /// **'/ano'**
  String get perYear;

  /// No description provided for @unlimitedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ilimitado'**
  String get unlimitedLabel;

  /// No description provided for @patientsLimit.
  ///
  /// In pt, this message translates to:
  /// **'Pacientes'**
  String get patientsLimit;

  /// No description provided for @sessionsMonthLimit.
  ///
  /// In pt, this message translates to:
  /// **'Sessões/mês'**
  String get sessionsMonthLimit;

  /// No description provided for @templatesLimit.
  ///
  /// In pt, this message translates to:
  /// **'Modelos'**
  String get templatesLimit;

  /// No description provided for @anamnesisMonthLimit.
  ///
  /// In pt, this message translates to:
  /// **'Anamneses/mês'**
  String get anamnesisMonthLimit;

  /// No description provided for @storageLimit.
  ///
  /// In pt, this message translates to:
  /// **'Armazenamento'**
  String get storageLimit;

  /// No description provided for @customBrandingFeature.
  ///
  /// In pt, this message translates to:
  /// **'Marca personalizada'**
  String get customBrandingFeature;

  /// No description provided for @dataExportFeature.
  ///
  /// In pt, this message translates to:
  /// **'Exportação de dados'**
  String get dataExportFeature;

  /// No description provided for @dashboardHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do painel'**
  String get dashboardHistory;

  /// No description provided for @days30.
  ///
  /// In pt, this message translates to:
  /// **'30 dias'**
  String get days30;

  /// No description provided for @months12.
  ///
  /// In pt, this message translates to:
  /// **'12 meses'**
  String get months12;

  /// No description provided for @selectPlan.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get selectPlan;

  /// No description provided for @currentPlanBadge.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get currentPlanBadge;

  /// No description provided for @planUpgraded.
  ///
  /// In pt, this message translates to:
  /// **'Plano alterado com sucesso!'**
  String get planUpgraded;

  /// No description provided for @quotaReached.
  ///
  /// In pt, this message translates to:
  /// **'Limite atingido'**
  String get quotaReached;

  /// No description provided for @quotaReachedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você atingiu o limite de {resource} do plano {plan}. Faça upgrade para continuar.'**
  String quotaReachedDesc(String resource, String plan);

  /// No description provided for @quotaNearLimit.
  ///
  /// In pt, this message translates to:
  /// **'Você usou {current} de {limit} {resource}.'**
  String quotaNearLimit(int current, int limit, String resource);

  /// No description provided for @upgrade.
  ///
  /// In pt, this message translates to:
  /// **'Fazer upgrade'**
  String get upgrade;

  /// No description provided for @usageOf.
  ///
  /// In pt, this message translates to:
  /// **'{current} de {limit}'**
  String usageOf(int current, int limit);

  /// No description provided for @resourcePatients.
  ///
  /// In pt, this message translates to:
  /// **'pacientes'**
  String get resourcePatients;

  /// No description provided for @resourceSessions.
  ///
  /// In pt, this message translates to:
  /// **'sessões'**
  String get resourceSessions;

  /// No description provided for @resourceTemplates.
  ///
  /// In pt, this message translates to:
  /// **'modelos'**
  String get resourceTemplates;

  /// No description provided for @resourceAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'anamneses'**
  String get resourceAnamnesis;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
