////////////////////////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ
//

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)

	ВыполнитьПроверкуПравДоступа("Администрирование", Метаданные);

	Если Параметры.Свойство("АвтоТест") Тогда // Возврат при получении формы для анализа.
		Возврат;
	КонецЕсли;

	ИдентификаторКонсолиЗапросов = "УИ_КонсольЗапросов";

	ТекущийОбъект = ЭтотОбъектОбработки();
	ТекущийОбъект.ПрочитатьНастройки();
	ТекущийОбъект.ПрочитатьПризнакПоддержкиБСП();

	Строка = СокрЛП(ТекущийОбъект.QueryExternalDataProcessorAddressSetting);
	Если НРег(Прав(Строка, 4)) = ".epf" Тогда
		ВариантИспользованияКонсолиЗапросов = 2;
	ИначеЕсли Метаданные.Обработки.Найти(Строка) <> Неопределено Тогда
		ВариантИспользованияКонсолиЗапросов = 1;
		Строка = "";
	Иначе
		ВариантИспользованияКонсолиЗапросов = 0;
		Строка = "";
	КонецЕсли;
	ТекущийОбъект.QueryExternalDataProcessorAddressSetting = Строка;

	ЭтотОбъектОбработки(ТекущийОбъект);

	СписокВыбора = Элементы.ОбработкаЗапросаВнешняя.СписокВыбора;
	
	// В составе метаданных разрешаем, только если есть предопределенное
	Если Метаданные.Обработки.Найти(ИдентификаторКонсолиЗапросов) = Неопределено Тогда
		ТекЭлемент = СписокВыбора.НайтиПоЗначению(1);
		Если ТекЭлемент <> Неопределено Тогда
			СписокВыбора.Удалить(ТекЭлемент);
		КонецЕсли;
	КонецЕсли;
	
	// Строка опции из файла
	Если ТекущийОбъект.ЭтоФайловаяБаза() Тогда
		ТекЭлемент = СписокВыбора.НайтиПоЗначению(2);
		Если ТекЭлемент <> Неопределено Тогда
			ТекЭлемент.Представление = НСтр("ru='В каталоге:'");
		КонецЕсли;
	КонецЕсли;

	// БСП разрешаем только если она есть и нужной версии
	Элементы.ГруппаБСП.Видимость = ТекущийОбъект.ConfigurationSupportsSSL;

КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ШАПКИ ФОРМЫ
//

&НаКлиенте
Процедура ОбработкаЗапросаПутьПриИзменении(Элемент)
	ВариантИспользованияКонсолиЗапросов = 2;
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаЗапросаПутьНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	Диалог.ПроверятьСуществованиеФайла = Истина;
	Диалог.Фильтр = НСтр("ru='Внешние обработки (*.epf)|*.epf'");
	Диалог.Показать(Новый ОписаниеОповещения("ОбработкаЗапросаПутьНачалоВыбораЗавершение", ЭтаФорма,
		Новый Структура("Диалог", Диалог)));
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаЗапросаПутьНачалоВыбораЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт

	Диалог = ДополнительныеПараметры.Диалог;
	Если (ВыбранныеФайлы <> Неопределено) Тогда
		ВариантИспользованияКонсолиЗапросов = 2;
		УстановитьНастройкуАдресВнешнейОбработкиЗапросов(Диалог.ПолноеИмяФайла);
	КонецЕсли;

КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД ФОРМЫ
//

&НаКлиенте
Процедура ПодтвердитьВыбор(Команда)

	Проверка = ПроверитьНастройки();
	Если Проверка.ЕстьОшибки Тогда
		// Сообщаем об ошибках
		Если Проверка.QueryExternalDataProcessorAddressSetting <> Неопределено Тогда
			СообщитьОбОшибке(Проверка.НастройкаАдресВнешнейОбработкиЗапросов,
				"Объект.QueryExternalDataProcessorAddressSetting");
			Возврат;
		КонецЕсли;
	КонецЕсли;
	
	// Все успешно
	СохранитьНастройки();
	Закрыть();
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ
//

&НаКлиенте
Процедура СообщитьОбОшибке(Текст, ИмяРеквизита = Неопределено)

	Если ИмяРеквизита = Неопределено Тогда
		ЗаголовокОшибки = НСтр("ru='Ошибка'");
		ПоказатьПредупреждение( , Текст, , ЗаголовокОшибки);
		Возврат;
	КонецЕсли;

	Сообщение = Новый СообщениеПользователю;
	Сообщение.Текст = Текст;
	Сообщение.Поле  = ИмяРеквизита;
	Сообщение.УстановитьДанные(ЭтотОбъект);
	Сообщение.Сообщить();
КонецПроцедуры

&НаСервере
Функция ЭтотОбъектОбработки(ТекущийОбъект = Неопределено)
	Если ТекущийОбъект = Неопределено Тогда
		Возврат РеквизитФормыВЗначение("Объект");
	КонецЕсли;
	ЗначениеВРеквизитФормы(ТекущийОбъект, "Объект");
	Возврат Неопределено;
КонецФункции

&НаСервере
Функция ПроверитьНастройки()
	ТекущийОбъект = ЭтотОбъектОбработки();

	Если ВариантИспользованияКонсолиЗапросов = 2 Тогда
		Если НРег(Прав(СокрЛП(ТекущийОбъект.QueryExternalDataProcessorAddressSetting), 4)) <> ".epf" Тогда
			ТекущийОбъект.QueryExternalDataProcessorAddressSetting = СокрЛП(
				ТекущийОбъект.QueryExternalDataProcessorAddressSetting) + ".epf";
		КонецЕсли;
	ИначеЕсли ВариантИспользованияКонсолиЗапросов = 0 Тогда
		ТекущийОбъект.QueryExternalDataProcessorAddressSetting = "";
	КонецЕсли;
	Результат = ТекущийОбъект.ПроверитьКорректностьНастроек();
	ЭтотОбъектОбработки(ТекущийОбъект);

	Возврат Результат;
КонецФункции

&НаСервере
Процедура СохранитьНастройки()
	ТекущийОбъект = ЭтотОбъектОбработки();
	Если ВариантИспользованияКонсолиЗапросов = 0 Тогда
		ТекущийОбъект.QueryExternalDataProcessorAddressSetting = "";
	ИначеЕсли ВариантИспользованияКонсолиЗапросов = 1 Тогда
		ТекущийОбъект.QueryExternalDataProcessorAddressSetting = ИдентификаторКонсолиЗапросов;
	КонецЕсли;
	ТекущийОбъект.СохранитьНастройки();
	ЭтотОбъектОбработки(ТекущийОбъект);
КонецПроцедуры

&НаСервере
Процедура УстановитьНастройкуАдресВнешнейОбработкиЗапросов(ПутьКФайлу)
	ТекущийОбъект = ЭтотОбъектОбработки();
	ТекущийОбъект.QueryExternalDataProcessorAddressSetting = ПутьКФайлу;
	ЭтотОбъектОбработки(ТекущийОбъект);
КонецПроцедуры