//Признак использования настроек
&НаКлиенте
Перем мИспользоватьНастройки Экспорт;

//Типы объектов, для которых может использоваться обработка.
//По умолчанию для всех.
&НаКлиенте
Перем мТипыОбрабатываемыхОбъектов Экспорт;

&НаКлиенте
Перем мНастройка;

////////////////////////////////////////////////////////////////////////////////
// ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

// Определяет и устанавливает Тип и Длинну номера объекта
//
// Параметры:
//  Нет.
//
&НаСервере
Процедура ОпределитьТипИДлиннуНомера()
	ИмяТипаОбъектов = ОбъектПоиска.Тип;
	ОбъектМетаданных = Метаданные.НайтиПоПолномуИмени(ОбъектПоиска.Тип + "." + ОбъектПоиска.Имя);
	Если ИмяТипаОбъектов = "Документ" Тогда
		ТипНомера   = Строка(ОбъектМетаданных.ТипНомера);
		ДлинаНомера = ОбъектМетаданных.ДлинаНомера;
	ИначеЕсли ИмяТипаОбъектов = "Справочник" Тогда
		ТипНомера   = Строка(ОбъектМетаданных.ТипКода);
		ДлинаНомера = ОбъектМетаданных.ДлинаКода;
	КонецЕсли;
КонецПроцедуры // ()

// Выполняет обработку объектов.
//
// Параметры:
//  Объект                 - обрабатываемый объект.
//  ПорядковыйНомерОбъекта - порядковый номер обрабатываемого объекта.
//
&НаСервере
Процедура ОбработатьОбъект(Ссылка, сч, НеУникальныеНомера, МаксимальныйНомер, ЧисловаяЧастьНомера,
	ПараметрыЗаписиОбъектов)

	Объект = Ссылка.ПолучитьОбъект();

	Если ТипНомера = "Число" Тогда
		Если Не НеИзменятьЧисловуюНумерацию Тогда
			Если ИмяТипаОбъектов = "Документ" Тогда
				Объект.Номер = ЧисловаяЧастьНомера;
			Иначе
				Объект.Код = ЧисловаяЧастьНомера;
			КонецЕсли;
			Если Не UT_Common.ЗаписатьОбъектВБазу(Объект, ПараметрыЗаписиОбъектов) Тогда
				Если ИмяТипаОбъектов = "Документ" Тогда
					Объект.Номер = МаксимальныйНомер - Сч;
				Иначе
					Объект.Код = МаксимальныйНомер - Сч;
				КонецЕсли;
				//				Объект.Записать();

				Если Не UT_Common.ЗаписатьОбъектВБазу(Объект, ПараметрыЗаписиОбъектов) Тогда
					ВызватьИсключение "Ошибка обработки номеров объектов";
				КонецЕсли;
				НеУникальныеНомера.Вставить(ЧисловаяЧастьНомера, Объект.Ссылка);
			КонецЕсли;
//			Попытка
//				Объект.Записать();
//			Исключение
//				Если ИмяТипаОбъектов = "Документ" Тогда
//					Объект.Номер = МаксимальныйНомер - Сч;
//				Иначе
//					Объект.Код = МаксимальныйНомер - Сч;
//				КонецЕсли; 
//				Объект.Записать();
//				НеУникальныеНомера.Вставить(ЧисловаяЧастьНомера, Объект.Ссылка);
//			КонецПопытки;		
			ЧисловаяЧастьНомера = ЧисловаяЧастьНомера + 1;
		КонецЕсли;
		Возврат;
	КонецЕсли;
	Если ИмяТипаОбъектов = "Документ" Тогда
		ТекНомер = СокрЛП(Объект.Номер);
	Иначе
		ТекНомер = СокрЛП(Объект.Код);
	КонецЕсли;

	Если НеИзменятьЧисловуюНумерацию Тогда
		СтроковаяЧастьНомера = ПолучитьПрефиксЧислоНомера(ТекНомер, ЧисловаяЧастьНомера);
	Иначе
		СтроковаяЧастьНомера = ПолучитьПрефиксЧислоНомера(ТекНомер);
	КонецЕсли;
	Если СпособОбработкиПрефиксов = 1 Тогда
		НовыйНомер = СтроковаяЧастьНомера;
	ИначеЕсли СпособОбработкиПрефиксов = 2 Тогда
		НовыйНомер = СокрЛП(СтрокаПрефикса);
	ИначеЕсли СпособОбработкиПрефиксов = 3 Тогда
		НовыйНомер = СокрЛП(СтрокаПрефикса) + СтроковаяЧастьНомера;
	ИначеЕсли СпособОбработкиПрефиксов = 4 Тогда
		НовыйНомер = СтроковаяЧастьНомера + СокрЛП(СтрокаПрефикса);
	ИначеЕсли СпособОбработкиПрефиксов = 5 Тогда
		НовыйНомер = СтрЗаменить(СтроковаяЧастьНомера, СокрЛП(ЗаменяемаяПодстрока), СокрЛП(СтрокаПрефикса));
	КонецЕсли;

	Пока ДлинаНомера - СтрДлина(НовыйНомер) - СтрДлина(Формат(ЧисловаяЧастьНомера, "ЧГ=0")) > 0 Цикл
		НовыйНомер = НовыйНомер + "0";
	КонецЦикла;

	НовыйНомер 	 = НовыйНомер + Формат(ЧисловаяЧастьНомера, "ЧГ=0");

	Если ИмяТипаОбъектов = "Документ" Тогда
		Объект.Номер = НовыйНомер;
	Иначе
		Объект.Код = НовыйНомер;
	КонецЕсли;

	Если Не UT_Common.ЗаписатьОбъектВБазу(Объект, ПараметрыЗаписиОбъектов) Тогда
		Если ИмяТипаОбъектов = "Документ" Тогда
			Объект.Номер = Формат(МаксимальныйНомер - Сч, "ЧГ=0");
		Иначе
			Объект.Код = Формат(МаксимальныйНомер - Сч, "ЧГ=0");
		КонецЕсли; 
//		Объект.Записать();			
		Если Не UT_Common.ЗаписатьОбъектВБазу(Объект, ПараметрыЗаписиОбъектов) Тогда
			ВызватьИсключение "Ошибка обработки номеров объектов";
		КонецЕсли;
		НеУникальныеНомера.Вставить(НовыйНомер, Объект.Ссылка);

	КонецЕсли;
//	Попытка
//		Объект.Записать();
//	Исключение
//		Если ИмяТипаОбъектов = "Документ" Тогда
//			Объект.Номер = Формат(МаксимальныйНомер - Сч, "ЧГ=0");
//		Иначе
//			Объект.Код = Формат(МаксимальныйНомер - Сч, "ЧГ=0");
//		КонецЕсли;
//		Объект.Записать();
//		НеУникальныеНомера.Вставить(НовыйНомер, Объект.Ссылка);
//	КонецПопытки;

	Если Не НеИзменятьЧисловуюНумерацию Тогда
		ЧисловаяЧастьНомера = ЧисловаяЧастьНомера + 1;
	КонецЕсли;

КонецПроцедуры // ОбработатьОбъект()

&НаСервере
Процедура ПроверитьНеУникальныеНомера(НеУникальныеНомера, ПараметрыЗаписиОбъектов)
	Для Каждого Зн Из НеУникальныеНомера Цикл
		НовыйНомер   = Зн.Ключ;
		Объект       = Зн.Значение.ПолучитьОбъект();
		Если ИмяТипаОбъектов = "Документ" Тогда
			Объект.Номер = НовыйНомер;
		Иначе
			Объект.Код = НовыйНомер;
		КонецЕсли;
		Если Не UT_Common.ЗаписатьОбъектВБазу(Объект, ПараметрыЗаписиОбъектов) Тогда
			UT_CommonClientServer.MessageToUser(СтрШаблон(
				"Повтор номера: %1 за пределами данной выборки!", НовыйНомер));
		КонецЕсли;
//		Попытка
//			Объект.Записать();
//		Исключение
//			Сообщить("Повтор номера: " + НовыйНомер + " за пределами данной выборки!");
//		КонецПопытки;
	КонецЦикла;
КонецПроцедуры

// Выполняет обработку объектов.
//
// Параметры:
//  Нет.
//
&НаКлиенте
Функция ВыполнитьОбработку(ПараметрыЗаписиОбъектов) Экспорт
	ОпределитьТипИДлиннуНомера();
	Если (СпособОбработкиПрефиксов = 1) И (НеИзменятьЧисловуюНумерацию) Тогда
		Возврат 0;
	КонецЕсли;

	Если (НачальныйНомер = 0) И (Не НеИзменятьЧисловуюНумерацию) Тогда
		ПоказатьПредупреждение( , "Измените начальный номер!");
		Возврат 0;
	КонецЕсли;

	Если Не НеИзменятьЧисловуюНумерацию Тогда
		ЧисловаяЧастьНомера = НачальныйНомер;
	КонецЕсли;

	НеУникальныеНомера = Новый Соответствие;
	МаксимальныйНомер  = Число(ДополнитьСтрокуСимволами("", ДлинаНомера, "9"));

	Индикатор = ПолучитьИндикаторПроцесса(НайденныеОбъекты.Количество());
	Для сч = 0 По НайденныеОбъекты.Количество() - 1 Цикл
		ОбработатьИндикатор(Индикатор, сч + 1);

		Объект = НайденныеОбъекты.Получить(сч).Значение;
		ОбработатьОбъект(Объект, сч, НеУникальныеНомера, МаксимальныйНомер, ЧисловаяЧастьНомера,
			ПараметрыЗаписиОбъектов);
	КонецЦикла;

	ПроверитьНеУникальныеНомера(НеУникальныеНомера, ПараметрыЗаписиОбъектов);

	Если сч > 0 Тогда
		ОповеститьОбИзменении(Тип(ОбъектПоиска.Тип + "Ссылка." + ОбъектПоиска.Имя));
	КонецЕсли;

	Возврат сч;
КонецФункции // вВыполнитьОбработку()

// Сохраняет значения реквизитов формы.
//
// Параметры:
//  Нет.
//
&НаКлиенте
Процедура СохранитьНастройку() Экспорт

	Если ПустаяСтрока(ТекущаяНастройкаПредставление) Тогда
		ПоказатьПредупреждение( ,
			"Задайте имя новой настройки для сохранения или выберите существующую настройку для перезаписи.");
	КонецЕсли;

	НоваяНастройка = Новый Структура;
	НоваяНастройка.Вставить("Обработка", ТекущаяНастройкаПредставление);
	НоваяНастройка.Вставить("Прочее", Новый Структура);

	Для Каждого РеквизитНастройки Из мНастройка Цикл
		Выполнить ("НоваяНастройка.Прочее.Вставить(Строка(РеквизитНастройки.Ключ), " + Строка(РеквизитНастройки.Ключ)
			+ ");");
	КонецЦикла;

	ДоступныеОбработки = ЭтаФорма.ВладелецФормы.ДоступныеОбработки;
	ТекущаяДоступнаяНастройка = Неопределено;
	Для Каждого ТекущаяДоступнаяНастройка Из ДоступныеОбработки.ПолучитьЭлементы() Цикл
		Если ТекущаяДоступнаяНастройка.ПолучитьИдентификатор() = Родитель Тогда
			Прервать;
		КонецЕсли;
	КонецЦикла;

	Если ТекущаяНастройка = Неопределено Или Не ТекущаяНастройка.Обработка = ТекущаяНастройкаПредставление Тогда
		Если ТекущаяДоступнаяНастройка <> Неопределено Тогда
			НоваяСтрока = ТекущаяДоступнаяНастройка.ПолучитьЭлементы().Добавить();
			НоваяСтрока.Обработка = ТекущаяНастройкаПредставление;
			НоваяСтрока.Настройка.Добавить(НоваяНастройка);

			ЭтаФорма.ВладелецФормы.Элементы.ДоступныеОбработки.ТекущаяСтрока = НоваяСтрока.ПолучитьИдентификатор();
		КонецЕсли;
	КонецЕсли;

	Если ТекущаяДоступнаяНастройка <> Неопределено И ТекущаяСтрока > -1 Тогда
		Для Каждого ТекНастройка Из ТекущаяДоступнаяНастройка.ПолучитьЭлементы() Цикл
			Если ТекНастройка.ПолучитьИдентификатор() = ТекущаяСтрока Тогда
				Прервать;
			КонецЕсли;
		КонецЦикла;

		Если ТекНастройка.Настройка.Количество() = 0 Тогда
			ТекНастройка.Настройка.Добавить(НоваяНастройка);
		Иначе
			ТекНастройка.Настройка[0].Значение = НоваяНастройка;
		КонецЕсли;
	КонецЕсли;

	ТекущаяНастройка = НоваяНастройка;
	ЭтаФорма.Модифицированность = Ложь;
КонецПроцедуры // вСохранитьНастройку()

// Восстанавливает сохраненные значения реквизитов формы.
//
// Параметры:
//  Нет.
//
&НаКлиенте
Процедура ЗагрузитьНастройку() Экспорт

	Если Элементы.ТекущаяНастройка.СписокВыбора.Количество() = 0 Тогда
		УстановитьИмяНастройки("Новая настройка");
	Иначе
		Если Не ТекущаяНастройка.Прочее = Неопределено Тогда
			мНастройка = ТекущаяНастройка.Прочее;
		КонецЕсли;
	КонецЕсли;

	Для Каждого РеквизитНастройки Из мНастройка Цикл
		//@skip-warning
		Значение = мНастройка[РеквизитНастройки.Ключ];
		Выполнить (Строка(РеквизитНастройки.Ключ) + " = Значение;");
	КонецЦикла;

	СпособОбработкиПрефиксовПриИзменении("");
	НеИзменятьЧисловуюНумерациюПриИзменении("");
КонецПроцедуры //вЗагрузитьНастройку()

// Устанавливает значение реквизита "ТекущаяНастройка" по имени настройки или произвольно.
//
// Параметры:
//  ИмяНастройки   - произвольное имя настройки, которое необходимо установить.
//
&НаКлиенте
Процедура УстановитьИмяНастройки(ИмяНастройки = "") Экспорт

	Если ПустаяСтрока(ИмяНастройки) Тогда
		Если ТекущаяНастройка = Неопределено Тогда
			ТекущаяНастройкаПредставление = "";
		Иначе
			ТекущаяНастройкаПредставление = ТекущаяНастройка.Обработка;
		КонецЕсли;
	Иначе
		ТекущаяНастройкаПредставление = ИмяНастройки;
	КонецЕсли;

КонецПроцедуры // вУстановитьИмяНастройки()

// Получает структуру для индикации прогресса цикла.
//
// Параметры:
//  КоличествоПроходов - Число - максимальное значение счетчика;
//  ПредставлениеПроцесса - Строка, "Выполнено" - отображаемое название процесса;
//  ВнутреннийСчетчик - Булево, *Истина - использовать внутренний счетчик с начальным значением 1,
//                    иначе нужно будет передавать значение счетчика при каждом вызове обновления индикатора;
//  КоличествоОбновлений - Число, *100 - всего количество обновлений индикатора;
//  ЛиВыводитьВремя - Булево, *Истина - выводить приблизительное время до окончания процесса;
//  РазрешитьПрерывание - Булево, *Истина - разрешает пользователю прерывать процесс.
//
// Возвращаемое значение:
//  Структура - которую потом нужно будет передавать в метод ЛксОбработатьИндикатор.
//
&НаКлиенте
Функция ПолучитьИндикаторПроцесса(КоличествоПроходов, ПредставлениеПроцесса = "Выполнено", ВнутреннийСчетчик = Истина,
	КоличествоОбновлений = 100, ЛиВыводитьВремя = Истина, РазрешитьПрерывание = Истина) Экспорт

	Индикатор = Новый Структура;
	Индикатор.Вставить("КоличествоПроходов", КоличествоПроходов);
	Индикатор.Вставить("ДатаНачалаПроцесса", ТекущаяДата());
	Индикатор.Вставить("ПредставлениеПроцесса", ПредставлениеПроцесса);
	Индикатор.Вставить("ЛиВыводитьВремя", ЛиВыводитьВремя);
	Индикатор.Вставить("РазрешитьПрерывание", РазрешитьПрерывание);
	Индикатор.Вставить("ВнутреннийСчетчик", ВнутреннийСчетчик);
	Индикатор.Вставить("Шаг", КоличествоПроходов / КоличествоОбновлений);
	Индикатор.Вставить("СледующийСчетчик", 0);
	Индикатор.Вставить("Счетчик", 0);
	Возврат Индикатор;

КонецФункции // ЛксПолучитьИндикаторПроцесса()

// Проверяет и обновляет индикатор. Нужно вызывать на каждом проходе индицируемого цикла.
//
// Параметры:
//  Индикатор    - Структура - индикатора, полученная методом ЛксПолучитьИндикаторПроцесса;
//  Счетчик      - Число - внешний счетчик цикла, используется при ВнутреннийСчетчик = Ложь.
//
&НаКлиенте
Процедура ОбработатьИндикатор(Индикатор, Счетчик = 0) Экспорт

	Если Индикатор.ВнутреннийСчетчик Тогда
		Индикатор.Счетчик = Индикатор.Счетчик + 1;
		Счетчик = Индикатор.Счетчик;
	КонецЕсли;
	Если Индикатор.РазрешитьПрерывание Тогда
		ОбработкаПрерыванияПользователя();
	КонецЕсли;

	Если Счетчик > Индикатор.СледующийСчетчик Тогда
		Индикатор.СледующийСчетчик = Цел(Счетчик + Индикатор.Шаг);
		Если Индикатор.ЛиВыводитьВремя Тогда
			ПрошлоВремени = ТекущаяДата() - Индикатор.ДатаНачалаПроцесса;
			Осталось = ПрошлоВремени * (Индикатор.КоличествоПроходов / Счетчик - 1);
			Часов = Цел(Осталось / 3600);
			Осталось = Осталось - (Часов * 3600);
			Минут = Цел(Осталось / 60);
			Секунд = Цел(Цел(Осталось - (Минут * 60)));
			ОсталосьВремени = Формат(Часов, "ЧЦ=2; ЧН=00; ЧВН=") + ":" + Формат(Минут, "ЧЦ=2; ЧН=00; ЧВН=") + ":"
				+ Формат(Секунд, "ЧЦ=2; ЧН=00; ЧВН=");
			ТекстОсталось = "Осталось: ~" + ОсталосьВремени;
		Иначе
			ТекстОсталось = "";
		КонецЕсли;

		Если Индикатор.КоличествоПроходов > 0 Тогда
			ТекстСостояния = ТекстОсталось;
		Иначе
			ТекстСостояния = "";
		КонецЕсли;

		Состояние(Индикатор.ПредставлениеПроцесса, Счетчик / Индикатор.КоличествоПроходов * 100, ТекстСостояния);
	КонецЕсли;

	Если Счетчик = Индикатор.КоличествоПроходов Тогда
		Состояние(Индикатор.ПредставлениеПроцесса, 100, ТекстСостояния);
	КонецЕсли;

КонецПроцедуры // ЛксОбработатьИндикатор()

// Разбирает строку выделяя из нее префикс и числовую часть
//
// Параметры:
//  Стр            - Строка. Разбираемая строка
//  ЧисловаяЧасть  - Число. Переменная в которую возвратится числовая часть строки
//  Режим          - Строка. Если "Число", то возвратит числовую часть иначе - префикс
//
// Возвращаемое значение:
//  Префикс строки
//              
&НаСервере
Функция ПолучитьПрефиксЧислоНомера(Знач Стр, ЧисловаяЧасть = "", Режим = "") Экспорт

	Стр		=	СокрЛП(Стр);
	Префикс	=	Стр;
	Длина	=	СтрДлина(Стр);

	Для Сч = 1 По Длина Цикл
		Попытка
			ЧисловаяЧасть = Число(Стр);
		Исключение
			Стр = Прав(Стр, Длина - Сч);
			Продолжить;
		КонецПопытки;

		Если (ЧисловаяЧасть > 0) И (СтрДлина(Формат(ЧисловаяЧасть, "ЧГ=0")) = Длина - Сч + 1) Тогда
			Префикс	=	Лев(Префикс, Сч - 1);

			Пока Прав(Префикс, 1) = "0" Цикл
				Префикс = Лев(Префикс, СтрДлина(Префикс) - 1);
			КонецЦикла;

			Прервать;
		Иначе
			Стр = Прав(Стр, Длина - Сч);
		КонецЕсли;

		Если ЧисловаяЧасть < 0 Тогда
			ЧисловаяЧасть = -ЧисловаяЧасть;
		КонецЕсли;

	КонецЦикла;

	Если Режим = "Число" Тогда
		Возврат (ЧисловаяЧасть);
	Иначе
		Возврат (Префикс);
	КонецЕсли;

КонецФункции // вПолучитьПрефиксЧислоНомера()

// Приводит номер (код) к требуемой длине. При этом выделяется префикс
// и числовая часть номера, остальное пространство между префиксом и
// номером заполняется нулями
//
// Параметры:
//  Стр            - Преобразовываемая строка
//  Длина          - Требуемая длина строки
//
// Возвращаемое значение:
//  Строка - код или номер, приведенная к требуемой длине
// 
&НаСервере
Функция ПривестиНомерКДлине(Знач Стр, Длина) Экспорт

	Стр			    =	СокрЛП(Стр);

	ЧисловаяЧасть	=	"";
	Результат		=	ПолучитьПрефиксЧислоНомера(Стр, ЧисловаяЧасть);
	Пока Длина - СтрДлина(Результат) - СтрДлина(Формат(ЧисловаяЧасть, "ЧГ=0")) > 0 Цикл
		Результат	=	Результат + "0";
	КонецЦикла;
	Результат	=	Результат + Формат(ЧисловаяЧасть, "ЧГ=0");

	Возврат (Результат);

КонецФункции // вПривестиНомерКДлине()

// Добавляет к префиксу номера или кода подстроку
//
// Параметры:
//  Стр            - Строка. Номер или код
//  Добавок        - Добаляемая к префиксу подстрока
//  Длина          - Требуемая результрирубщая длина строки
//  Режим          - "Слева" - подстрока добавляется слева к префиксу, иначе - справа
//
// Возвращаемое значение:
//  Строка - номер или код, к префиксу которого добавлена указанная подстрока
//                                                                                                     
&НаСервере
Функция ДобавитьКПрефиксу(Знач Стр, Добавок = "", Длина = "", Режим = "Слева") Экспорт

	Стр = СокрЛП(Стр);

	Если ПустаяСтрока(Длина) Тогда
		Длина = СтрДлина(Стр);
	КонецЕсли;

	ЧисловаяЧасть	=	"";
	Префикс			=	ПолучитьПрефиксЧислоНомера(Стр, ЧисловаяЧасть);
	Если Режим = "Слева" Тогда
		Результат	=	СокрЛП(Добавок) + Префикс;
	Иначе
		Результат	=	Префикс + СокрЛП(Добавок);
	КонецЕсли;

	Пока Длина - СтрДлина(Результат) - СтрДлина(Формат(ЧисловаяЧасть, "ЧГ=0")) > 0 Цикл
		Результат	=	Результат + "0";
	КонецЦикла;
	Результат	=	Результат + Формат(ЧисловаяЧасть, "ЧГ=0");

	Возврат (Результат);

КонецФункции // вДобавитьКПрефиксу()

// Дополняет строку указанным символом до указанной длины
//
// Параметры: 
//  Стр            - Дополняемая строка
//  Длина          - Требуемая длина результирующей строки
//  Чем            - Символ, которым дополняется строка
//
// Возвращаемое значение:
//  Строка дополненная указанным символом до указанной длины
//
&НаСервере
Функция ДополнитьСтрокуСимволами(Стр = "", Длина, Чем = " ") Экспорт
	Результат = СокрЛП(Стр);
	Пока Длина - СтрДлина(Результат) > 0 Цикл
		Результат	=	Результат + Чем;
	КонецЦикла;
	Возврат (Результат);
КонецФункции // вДополнитьСтрокуСимволами() 

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	ОпределитьТипИДлиннуНомера();
	Если ТипНомера <> "Строка" Тогда
		Элементы.ПрефиксыНомеров.Видимость = Ложь;
	КонецЕсли;

	Если мИспользоватьНастройки Тогда
		УстановитьИмяНастройки();
		ЗагрузитьНастройку();
	Иначе
		Элементы.ТекущаяНастройка.Доступность = Ложь;
		Элементы.СохранитьНастройки.Доступность = Ложь;
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	Если Параметры.Свойство("Настройка") Тогда
		ТекущаяНастройка = Параметры.Настройка;
	КонецЕсли;
	Если Параметры.Свойство("НайденныеОбъекты") Тогда
		НайденныеОбъекты.ЗагрузитьЗначения(Параметры.НайденныеОбъекты);
	КонецЕсли;
	ТекущаяСтрока = -1;
	Если Параметры.Свойство("ТекущаяСтрока") Тогда
		Если Параметры.ТекущаяСтрока <> Неопределено Тогда
			ТекущаяСтрока = Параметры.ТекущаяСтрока;
		КонецЕсли;
	КонецЕсли;
	Если Параметры.Свойство("Родитель") Тогда
		Родитель = Параметры.Родитель;
	КонецЕсли;

	Если Параметры.Свойство("ТабличноеПолеВидыОбъектов") Тогда

		Стр=Параметры.ТабличноеПолеВидыОбъектов[0];

		ОбъектПоиска = Новый Структура;
		ОбъектПоиска.Вставить("Тип", ?(Параметры.ТипОбъекта = 0, "Справочник", "Документ"));
		ОбъектПоиска.Вставить("Имя", Стр.ИмяТаблицы);
		ОбъектПоиска.Вставить("Представление", Стр.ПредставлениеТаблицы);

	КонецЕсли;

	Элементы.ТекущаяНастройка.СписокВыбора.Очистить();
	Если Параметры.Свойство("Настройки") Тогда
		Для Каждого Строка Из Параметры.Настройки Цикл
			Элементы.ТекущаяНастройка.СписокВыбора.Добавить(Строка, Строка.Обработка);
		КонецЦикла;
	КонецЕсли;
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ, ВЫЗЫВАЕМЫЕ ИЗ ЭЛЕМЕНТОВ ФОРМЫ

&НаКлиенте
Процедура ВыполнитьОбработкуКоманда(Команда)
	ОбработаноОбъектов = ВыполнитьОбработку(UT_CommonClientServer.ПараметрыЗаписиФормы(
		ЭтотОбъект.ВладелецФормы));

	ПоказатьПредупреждение( , "Обработка <" + СокрЛП(ЭтаФорма.Заголовок) + "> завершена!
																		   |Обработано объектов: " + ОбработаноОбъектов
		+ ".");
КонецПроцедуры

&НаКлиенте
Процедура СохранитьНастройкиКоманда(Команда)
	СохранитьНастройку();
КонецПроцедуры

&НаКлиенте
Процедура ТекущаяНастройкаОбработкаВыбора(Элемент, ВыбранноеЗначение, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;

	Если Не ТекущаяНастройка = ВыбранноеЗначение Тогда

		Если ЭтаФорма.Модифицированность Тогда
			ПоказатьВопрос(Новый ОписаниеОповещения("ТекущаяНастройкаОбработкаВыбораЗавершение", ЭтаФорма,
				Новый Структура("ВыбранноеЗначение", ВыбранноеЗначение)), "Сохранить текущую настройку?",
				РежимДиалогаВопрос.ДаНет, , КодВозвратаДиалога.Да);
			Возврат;
		КонецЕсли;

		ТекущаяНастройкаОбработкаВыбораФрагмент(ВыбранноеЗначение);

	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ТекущаяНастройкаОбработкаВыбораЗавершение(РезультатВопроса, ДополнительныеПараметры) Экспорт

	ВыбранноеЗначение = ДополнительныеПараметры.ВыбранноеЗначение;
	Если РезультатВопроса = КодВозвратаДиалога.Да Тогда
		СохранитьНастройку();
	КонецЕсли;

	ТекущаяНастройкаОбработкаВыбораФрагмент(ВыбранноеЗначение);

КонецПроцедуры

&НаКлиенте
Процедура ТекущаяНастройкаОбработкаВыбораФрагмент(Знач ВыбранноеЗначение)

	ТекущаяНастройка = ВыбранноеЗначение;
	УстановитьИмяНастройки();

	ЗагрузитьНастройку();

КонецПроцедуры

&НаКлиенте
Процедура ТекущаяНастройкаПриИзменении(Элемент)
	ЭтаФорма.Модифицированность = Истина;
КонецПроцедуры

&НаКлиенте
Процедура НеИзменятьЧисловуюНумерациюПриИзменении(Элемент)
	Элементы.НачальныйНомер.Доступность = Не НеИзменятьЧисловуюНумерацию;
КонецПроцедуры

&НаКлиенте
Процедура СпособОбработкиПрефиксовПриИзменении(Элемент)
	Если СпособОбработкиПрефиксов = 1 Тогда
		Элементы.СтрокаПрефикса.Доступность      = Ложь;
		Элементы.ЗаменяемаяПодстрока.Доступность = Ложь;
	ИначеЕсли СпособОбработкиПрефиксов = 5 Тогда
		Элементы.СтрокаПрефикса.Доступность      = Истина;
		Элементы.ЗаменяемаяПодстрока.Доступность = Истина;
	Иначе
		Элементы.СтрокаПрефикса.Доступность      = Истина;
		Элементы.ЗаменяемаяПодстрока.Доступность = Ложь;
	КонецЕсли;
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// ИНИЦИАЛИЗАЦИЯ МОДУЛЬНЫХ ПЕРЕМЕННЫХ

мИспользоватьНастройки = Истина;

//Реквизиты настройки и значения по умолчанию.
мНастройка = Новый Структура("НачальныйНомер,НеИзменятьЧисловуюНумерацию,СтрокаПрефикса,ЗаменяемаяПодстрока,СпособОбработкиПрефиксов");

мНастройка.НачальныйНомер              = 1;
мНастройка.НеИзменятьЧисловуюНумерацию = Ложь;
мНастройка.СпособОбработкиПрефиксов    = 1;

мТипыОбрабатываемыхОбъектов = "Справочник,Документ";