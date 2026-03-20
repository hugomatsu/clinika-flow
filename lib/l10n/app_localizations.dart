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
