import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en', ''));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ru', ''), // Russian
    Locale('tg', ''), // Tajik
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'debts': 'Debts',
      'cotton': 'Cotton',
      'cattle': 'Cattle',
      'history': 'History',
      'reports': 'Reports',
      
      // Dashboard
      'portfolio_details': 'Portfolio Details',
      'lending_borrowing': 'Lending & Borrowing',
      'manage_debts_payments': 'Manage debts and payments',
      'cotton_fields': 'Cotton Fields',
      'fields_harvests': 'Fields and harvests',
      'cotton_stock': 'Cotton Stock',
      'processing_sales': 'Processing & sales',
      'cattle_management': 'Cattle Management',
      'livestock_tracking': 'Livestock tracking',
      'reports_analytics': 'Reports & Analytics',
      'financial_insights': 'Financial insights',
      'start_with_lending': 'START WITH LENDING & BORROWING',
      
      // Language
      'language': 'Language',
      'select_language': 'Select Language',
      'english': 'English',
      'russian': 'Russian',
      'tajik': 'Tajik',
      
      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'confirm': 'Confirm',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'total': 'Total',
      'date': 'Date',
      'amount': 'Amount',
      'description': 'Description',
      'status': 'Status',
      'name': 'Name',
      'phone': 'Phone',
      'address': 'Address',
      'notes': 'Notes',
      
      // Debts
      'persons': 'Persons',
      'add_person': 'Add Person',
      'add_debt': 'Add Debt',
      'debt_details': 'Debt Details',
      'active_debts': 'Active Debts',
      'completed_debts': 'Completed Debts',
      'debt_amount': 'Debt Amount',
      'paid_amount': 'Paid Amount',
      'remaining_amount': 'Remaining Amount',
      'lent': 'Lent',
      'borrowed': 'Borrowed',
      'payment': 'Payment',
      'add_payment': 'Add Payment',
      
      // Cotton
      'fields': 'Fields',
      'add_field': 'Add Field',
      'field_name': 'Field Name',
      'field_area': 'Field Area',
      'hectares': 'Hectares',
      'harvest': 'Harvest',
      'add_harvest': 'Add Harvest',
      'harvest_amount': 'Harvest Amount',
      'quality_grade': 'Quality Grade',
      'sale': 'Sale',
      'add_sale': 'Add Sale',
      'sale_amount': 'Sale Amount',
      'price_per_kg': 'Price per kg',
      
      // Cattle
      'add_cattle': 'Add Cattle',
      'cattle_details': 'Cattle Details',
      'breed': 'Breed',
      'age': 'Age',
      'weight': 'Weight',
      'kg': 'kg',
      'purchase_date': 'Purchase Date',
      'purchase_price': 'Purchase Price',
      'sale_date': 'Sale Date',
      'sale_price': 'Sale Price',
      
      // Reports
      'debt_summary': 'Debt Summary',
      'cotton_summary': 'Cotton Summary',
      'cattle_summary': 'Cattle Summary',
      'financial_report': 'Financial Report',
      'export_report': 'Export Report',
      
      // Messages
      'loading': 'Loading...',
      'no_data': 'No data available',
      'error': 'Error',
      'success': 'Success',
      'saved_successfully': 'Saved successfully',
      'deleted_successfully': 'Deleted successfully',
      'confirm_delete': 'Are you sure you want to delete?',
    },
    'ru': {
      // Navigation
      'home': 'Главная',
      'debts': 'Долги',
      'cotton': 'Хлопок',
      'cattle': 'Скот',
      'history': 'История',
      'reports': 'Отчеты',
      
      // Dashboard
      'portfolio_details': 'Детали Портфолио',
      'lending_borrowing': 'Кредиты и Займы',
      'manage_debts_payments': 'Управление долгами и платежами',
      'cotton_fields': 'Хлопковые Поля',
      'fields_harvests': 'Поля и урожаи',
      'cotton_stock': 'Склад Хлопка',
      'processing_sales': 'Обработка и продажа',
      'cattle_management': 'Управление Скотом',
      'livestock_tracking': 'Учет скота',
      'reports_analytics': 'Отчеты и Аналитика',
      'financial_insights': 'Финансовая информация',
      'start_with_lending': 'НАЧАТЬ С КРЕДИТОВ И ЗАЙМОВ',
      
      // Language
      'language': 'Язык',
      'select_language': 'Выберите Язык',
      'english': 'Английский',
      'russian': 'Русский',
      'tajik': 'Таджикский',
      
      // Common
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Изменить',
      'add': 'Добавить',
      'close': 'Закрыть',
      'confirm': 'Подтвердить',
      'ok': 'ОК',
      'yes': 'Да',
      'no': 'Нет',
      'search': 'Поиск',
      'filter': 'Фильтр',
      'sort': 'Сортировка',
      'total': 'Всего',
      'date': 'Дата',
      'amount': 'Сумма',
      'description': 'Описание',
      'status': 'Статус',
      'name': 'Имя',
      'phone': 'Телефон',
      'address': 'Адрес',
      'notes': 'Заметки',
      
      // Debts
      'persons': 'Контакты',
      'add_person': 'Добавить Контакт',
      'add_debt': 'Добавить Долг',
      'debt_details': 'Детали Долга',
      'active_debts': 'Активные Долги',
      'completed_debts': 'Завершенные Долги',
      'debt_amount': 'Сумма Долга',
      'paid_amount': 'Выплачено',
      'remaining_amount': 'Осталось',
      'lent': 'Дали в долг',
      'borrowed': 'Взяли в долг',
      'payment': 'Платеж',
      'add_payment': 'Добавить Платеж',
      
      // Cotton
      'fields': 'Поля',
      'add_field': 'Добавить Поле',
      'field_name': 'Название Поля',
      'field_area': 'Площадь Поля',
      'hectares': 'Гектары',
      'harvest': 'Урожай',
      'add_harvest': 'Добавить Урожай',
      'harvest_amount': 'Количество Урожая',
      'quality_grade': 'Сорт Качества',
      'sale': 'Продажа',
      'add_sale': 'Добавить Продажу',
      'sale_amount': 'Количество Продажи',
      'price_per_kg': 'Цена за кг',
      
      // Cattle
      'add_cattle': 'Добавить Скот',
      'cattle_details': 'Детали Скота',
      'breed': 'Порода',
      'age': 'Возраст',
      'weight': 'Вес',
      'kg': 'кг',
      'purchase_date': 'Дата Покупки',
      'purchase_price': 'Цена Покупки',
      'sale_date': 'Дата Продажи',
      'sale_price': 'Цена Продажи',
      
      // Reports
      'debt_summary': 'Сводка по Долгам',
      'cotton_summary': 'Сводка по Хлопку',
      'cattle_summary': 'Сводка по Скоту',
      'financial_report': 'Финансовый Отчет',
      'export_report': 'Экспортировать Отчет',
      
      // Messages
      'loading': 'Загрузка...',
      'no_data': 'Нет данных',
      'error': 'Ошибка',
      'success': 'Успешно',
      'saved_successfully': 'Успешно сохранено',
      'deleted_successfully': 'Успешно удалено',
      'confirm_delete': 'Вы уверены, что хотите удалить?',
    },
    'tg': {
      // Navigation
      'home': 'Асосӣ',
      'debts': 'Қарзҳо',
      'cotton': 'Пахта',
      'cattle': 'Чорво',
      'history': 'Таърих',
      'reports': 'Ҳисоботҳо',
      
      // Dashboard
      'portfolio_details': 'Асосӣ',
      'lending_borrowing': 'Қарз Додан ва Гирифтан',
      'manage_debts_payments': 'Идораи қарзҳо ва пардохтҳо',
      'cotton_fields': 'Майдонҳои Пахта',
      'fields_harvests': 'Майдонҳо ва ҳосилот',
      'cotton_stock': 'Анбори Пахта',
      'processing_sales': 'Коркард ва фурӯш',
      'cattle_management': 'Идораи Чорво',
      'livestock_tracking': 'Ҳисоботи чорво',
      'reports_analytics': 'Ҳисоботҳо ва Таҳлил',
      'financial_insights': 'Маълумоти молиявӣ',
      'start_with_lending': 'ОҒОЗ БО ҚАРЗ ДОДАН ВА ГИРИФТАН',
      
      // Language
      'language': 'Забон',
      'select_language': 'Забонро Интихоб Кунед',
      'english': 'Англисӣ',
      'russian': 'Русӣ',
      'tajik': 'Тоҷикӣ',
      
      // Common
      'save': 'Захира',
      'cancel': 'Бекор',
      'delete': 'Нест кардан',
      'edit': 'Таҳрир',
      'add': 'Илова',
      'close': 'Пӯшидан',
      'confirm': 'Тасдиқ',
      'ok': 'Хуб',
      'yes': 'Ҳа',
      'no': 'Не',
      'search': 'Ҷустуҷӯ',
      'filter': 'Филтр',
      'sort': 'Мураттаб',
      'total': 'Ҳамагӣ',
      'date': 'Сана',
      'amount': 'Миқдор',
      'description': 'Тавсиф',
      'status': 'Ҳолат',
      'name': 'Ном',
      'phone': 'Телефон',
      'address': 'Суроға',
      'notes': 'Ёддоштҳо',
      
      // Debts
      'persons': 'Шахсон',
      'add_person': 'Илова Кардани Шахс',
      'add_debt': 'Илова Кардани Қарз',
      'debt_details': 'Тафсилоти Қарз',
      'active_debts': 'Қарзҳои Фаъол',
      'completed_debts': 'Қарзҳои Анҷомёфта',
      'debt_amount': 'Миқдори Қарз',
      'paid_amount': 'Миқдори Пардохтшуда',
      'remaining_amount': 'Миқдори Боқимонда',
      'lent': 'Қарз дода шуд',
      'borrowed': 'Қарз гирифта шуд',
      'payment': 'Пардохт',
      'add_payment': 'Илова Кардани Пардохт',
      
      // Cotton
      'fields': 'Майдонҳо',
      'add_field': 'Илова Кардани Майдон',
      'field_name': 'Номи Майдон',
      'field_area': 'Масоҳати Майдон',
      'hectares': 'Гектар',
      'harvest': 'Ҳосил',
      'add_harvest': 'Илова Кардани Ҳосил',
      'harvest_amount': 'Миқдори Ҳосил',
      'quality_grade': 'Дараҷаи Сифат',
      'sale': 'Фурӯш',
      'add_sale': 'Илова Кардани Фурӯш',
      'sale_amount': 'Миқдори Фурӯш',
      'price_per_kg': 'Нарх барои кг',
      
      // Cattle
      'add_cattle': 'Илова Кардани Чорво',
      'cattle_details': 'Тафсилоти Чорво',
      'breed': 'Зот',
      'age': 'Синну сол',
      'weight': 'Вазн',
      'kg': 'кг',
      'purchase_date': 'Санаи Харид',
      'purchase_price': 'Нархи Харид',
      'sale_date': 'Санаи Фурӯш',
      'sale_price': 'Нархи Фурӯш',
      
      // Reports
      'debt_summary': 'Хулосаи Қарзҳо',
      'cotton_summary': 'Хулосаи Пахта',
      'cattle_summary': 'Хулосаи Чорво',
      'financial_report': 'Ҳисоботи Молиявӣ',
      'export_report': 'Содироти Ҳисобот',
      
      // Messages
      'loading': 'Боргирӣ...',
      'no_data': 'Маълумот нест',
      'error': 'Хато',
      'success': 'Муваффақ',
      'saved_successfully': 'Бомуваффақият захира шуд',
      'deleted_successfully': 'Бомуваффақият нест карда шуд',
      'confirm_delete': 'Нест кардан тасдиқ мекунед?',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters for commonly used strings
  String get home => translate('home');
  String get debts => translate('debts');
  String get cotton => translate('cotton');
  String get cattle => translate('cattle');
  String get history => translate('history');
  String get reports => translate('reports');
  String get portfolioDetails => translate('portfolio_details');
  String get lendingBorrowing => translate('lending_borrowing');
  String get manageDebtsPayments => translate('manage_debts_payments');
  String get cottonFields => translate('cotton_fields');
  String get fieldsHarvests => translate('fields_harvests');
  String get cottonStock => translate('cotton_stock');
  String get processingSales => translate('processing_sales');
  String get cattleManagement => translate('cattle_management');
  String get livestockTracking => translate('livestock_tracking');
  String get reportsAnalytics => translate('reports_analytics');
  String get financialInsights => translate('financial_insights');
  String get startWithLending => translate('start_with_lending');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get english => translate('english');
  String get russian => translate('russian');
  String get tajik => translate('tajik');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'tg'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
