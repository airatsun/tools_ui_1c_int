#Область ПрограммныйИнтерфейс

#Область СозданиеЭлементовФормы

Процедура ФормаПриСозданииНаСервере(Форма, ВидРедактора = Неопределено) Экспорт
	Если ВидРедактора = Неопределено Тогда
		ПараметрыРедактора = ТекущиеПараметрыРедактораКода();
		ВидРедактора = ПараметрыРедактора.Вариант;
	КонецЕсли;
	ВариантыРедактора = UT_CodeEditorClientServer.ВариантыРедактораКода();
	
	ЭтоWindowsКлиент = Ложь;
	ЭтоВебКлиент = Истина;
	
	ПараметрыСеансаВХранилище = UT_CommonServerCall.ХранилищеОбщихНастроекЗагрузить(
		UT_CommonClientServer.КлючОбъектаВХранилищеНастроек(),
		UT_CommonClientServer.SessionParametersSettingsKey());
	Если Тип(ПараметрыСеансаВХранилище) = Тип("Структура") Тогда
		Если ПараметрыСеансаВХранилище.Свойство("HTMLFieldBasedOnWebkit") Тогда
			Если Не ПараметрыСеансаВХранилище.HTMLFieldBasedOnWebkit Тогда
				ВидРедактора = ВариантыРедактора.Текст;
			КонецЕсли;
		КонецЕсли;
		Если ПараметрыСеансаВХранилище.Свойство("ЭтоWindowsКлиент") Тогда
			ЭтоWindowsКлиент = ПараметрыСеансаВХранилище.ЭтоWindowsКлиент;
		КонецЕсли;
		Если ПараметрыСеансаВХранилище.Свойство("ЭтоВебКлиент") Тогда
			ЭтоВебКлиент = ПараметрыСеансаВХранилище.ЭтоВебКлиент;
		КонецЕсли;
		
	КонецЕсли;
	
	ИмяРеквизитаВидРедактора=UT_CodeEditorClientServer.ИмяРеквизитаРедактораКодаВидРедактора();
	ИмяРеквизитаАдресБиблиотеки=UT_CodeEditorClientServer.ИмяРеквизитаРедактораКодаАдресБиблиотеки();
	ИмяРеквизитаРедактораКодаСписокРедакторовФормы = UT_CodeEditorClientServer.ИмяРеквизитаРедактораКодаСписокРедакторовФормы();
	
	МассивРеквизитов=Новый Массив;
	МассивРеквизитов.Добавить(Новый РеквизитФормы(ИмяРеквизитаВидРедактора, Новый ОписаниеТипов("Строка", , Новый КвалификаторыСтроки(20,
		ДопустимаяДлина.Переменная)), "", "", Истина));
	МассивРеквизитов.Добавить(Новый РеквизитФормы(ИмяРеквизитаАдресБиблиотеки, Новый ОписаниеТипов("Строка", , Новый КвалификаторыСтроки(0,
		ДопустимаяДлина.Переменная)), "", "", Истина));
	МассивРеквизитов.Добавить(Новый РеквизитФормы(ИмяРеквизитаРедактораКодаСписокРедакторовФормы, Новый ОписаниеТипов, "", "", Истина));
		
	Форма.ИзменитьРеквизиты(МассивРеквизитов);
	
	Форма[ИмяРеквизитаВидРедактора]=ВидРедактора;
	Форма[ИмяРеквизитаАдресБиблиотеки] = ПоместитьБиблиотекуВоВременноеХранилище(Форма.УникальныйИдентификатор, ЭтоWindowsКлиент, ЭтоВебКлиент, ВидРедактора);
	Форма[ИмяРеквизитаРедактораКодаСписокРедакторовФормы] = Новый Структура;
КонецПроцедуры

Процедура СоздатьЭлементыРедактораКода(Форма, ИдентификаторРедактора, ПолеРедактора, ЯзыкРедактора = "bsl") Экспорт
	ИмяРеквизитаВидРедактора=UT_CodeEditorClientServer.ИмяРеквизитаРедактораКодаВидРедактора();
	
	ВидРедактора = Форма[ИмяРеквизитаВидРедактора];
	
	ДанныеРедактора = Новый Структура;

	Если UT_CodeEditorClientServer.РедакторКодаИспользуетПолеHTML(ВидРедактора) Тогда
		Если ПолеРедактора.Вид <> ВидПоляФормы.ПолеHTMLДокумента Тогда
			ПолеРедактора.Вид = ВидПоляФормы.ПолеHTMLДокумента;
		КонецЕсли;
		ПолеРедактора.УстановитьДействие("ДокументСформирован", "Подключаемый_ПолеРедактораДокументСформирован");
		ПолеРедактора.УстановитьДействие("ПриНажатии", "Подключаемый_ПолеРедактораПриНажатии");

		ДанныеРедактора.Вставить("Инициализирован", Ложь);

	Иначе
		ПолеРедактора.Вид = ВидПоляФормы.ПолеТекстовогоДокумента;
		ДанныеРедактора.Вставить("Инициализирован", Истина);
	КонецЕсли;

	ДанныеРедактора.Вставить("Язык", ЯзыкРедактора);
	ДанныеРедактора.Вставить("ПолеРедактора", ПолеРедактора.Имя);
	ДанныеРедактора.Вставить("ИмяРеквизита", ПолеРедактора.ПутьКДанным);
	
	ВариантыРедактора = UT_CodeEditorClientServer.ВариантыРедактораКода();

	ПараметрыРедактора = ТекущиеПараметрыРедактораКода();
	ДанныеРедактора.Вставить("ПараметрыРедактора", ПараметрыРедактора);

	Если ВидРедактора = ВариантыРедактора.Monaco Тогда
		Для Каждого КлючЗначение ИЗ ПараметрыРедактора.Monaco Цикл
			ДанныеРедактора.ПараметрыРедактора.Вставить(КлючЗначение.Ключ, КлючЗначение.Значение);
		КонецЦикла;
	КонецЕсли;
	
	Форма[UT_CodeEditorClientServer.ИмяРеквизитаРедактораКодаСписокРедакторовФормы()].Вставить(ИдентификаторРедактора,  ДанныеРедактора);	
КонецПроцедуры

#КонецОбласти

Функция ПоместитьБиблиотекуВоВременноеХранилище(ИдентификаторФормы, ЭтоWindowsКлиент, ЭтоВебКлиент, ВидРедактора=Неопределено) Экспорт
	Если ВидРедактора = Неопределено Тогда
		ВидРедактора = ТекущийВариантРедактораКода1С();
	КонецЕсли;
	ВариантыРедактора = UT_CodeEditorClientServer.ВариантыРедактораКода();
	
	Если ВидРедактора = ВариантыРедактора.Monaco Тогда
		Если ЭтоWindowsКлиент Тогда
			ДвоичныеДанныеБиблиотеки=ПолучитьОбщийМакет("УИ_MonacoEditorWindows");
		Иначе
			ДвоичныеДанныеБиблиотеки=ПолучитьОбщийМакет("UT_MonacoEditor");
		КонецЕсли;
	ИначеЕсли ВидРедактора = ВариантыРедактора.Ace Тогда
		ДвоичныеДанныеБиблиотеки=ПолучитьОбщийМакет("UT_Ace");
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
	СтруктураБиблиотеки=Новый Соответствие;

	Если Не ЭтоВебКлиент Тогда
		СтруктураБиблиотеки.Вставить("editor.zip",ДвоичныеДанныеБиблиотеки);

		Возврат ПоместитьВоВременноеХранилище(СтруктураБиблиотеки, ИдентификаторФормы);
	КонецЕсли;
	
	КаталогНаСервере=ПолучитьИмяВременногоФайла();
	СоздатьКаталог(КаталогНаСервере);

	Поток=ДвоичныеДанныеБиблиотеки.ОткрытьПотокДляЧтения();

	ЧтениеZIP=Новый ЧтениеZipФайла(Поток);
	ЧтениеZIP.ИзвлечьВсе(КаталогНаСервере, РежимВосстановленияПутейФайловZIP.Восстанавливать);


	ФайлыАрхива=НайтиФайлы(КаталогНаСервере, "*", Истина);
	Для Каждого ФайлБиблиотеки Из ФайлыАрхива Цикл
		КлючФайла=СтрЗаменить(ФайлБиблиотеки.ПолноеИмя, КаталогНаСервере + ПолучитьРазделительПути(), "");
		Если ФайлБиблиотеки.ЭтоКаталог() Тогда
			Продолжить;
		КонецЕсли;

		СтруктураБиблиотеки.Вставить(КлючФайла, Новый ДвоичныеДанные(ФайлБиблиотеки.ПолноеИмя));
	КонецЦикла;

	АдресБиблиотеки=ПоместитьВоВременноеХранилище(СтруктураБиблиотеки, ИдентификаторФормы);

	Попытка
		УдалитьФайлы(КаталогНаСервере);
	Исключение
		// TODO:
	КонецПопытки;

	Возврат АдресБиблиотеки;
КонецФункции

#Область НастройкиИнструментов


Функция ТекущийВариантРедактораКода1С() Экспорт
	ПараметрыРедактораКода = ТекущиеПараметрыРедактораКода();
	
	РедакторКода = ПараметрыРедактораКода.Вариант;
	
	УИ_ПараметрыСеанса = UT_Common.ХранилищеОбщихНастроекЗагрузить(
		UT_CommonClientServer.КлючОбъектаВХранилищеНастроек(),
		UT_CommonClientServer.SessionParametersSettingsKey());
		
	Если Тип(УИ_ПараметрыСеанса) = Тип("Структура") Тогда
		Если УИ_ПараметрыСеанса.HTMLFieldBasedOnWebkit<>Истина Тогда
			РедакторКода = UT_CodeEditorClientServer.ВариантыРедактораКода().Текст;
		КонецЕсли;
	КонецЕсли;
	
	Возврат РедакторКода;
КонецФункции

Процедура УстановитьНовыеНастройкиРедактораКода(НовыеНастройки) Экспорт
	UT_Common.ХранилищеОбщихНастроекСохранить(
		UT_CommonClientServer.SettingsDataKeyInSettingsStorage(), "ПараметрыРедактораКода",
		НовыеНастройки);
КонецПроцедуры

Функция ТекущиеПараметрыРедактораКода() Экспорт
	СохраненныеПараметрыРедактора = UT_Common.ХранилищеОбщихНастроекЗагрузить(
		UT_CommonClientServer.SettingsDataKeyInSettingsStorage(), "ПараметрыРедактораКода");

	ПараметрыПоУмолчанию = UT_CodeEditorClientServer.ПараметрыРедактораКодаПоУмолчанию();
	Если СохраненныеПараметрыРедактора = Неопределено Тогда		
		ПараметрыРедактораMonaco = ТекущиеПараметрыРедактораMonaco();
		
		ЗаполнитьЗначенияСвойств(ПараметрыПоУмолчанию.Monaco, ПараметрыРедактораMonaco);
	Иначе
		ЗаполнитьЗначенияСвойств(ПараметрыПоУмолчанию, СохраненныеПараметрыРедактора,,"Monaco");
		ЗаполнитьЗначенияСвойств(ПараметрыПоУмолчанию.Monaco, СохраненныеПараметрыРедактора.Monaco);
	КонецЕсли;
	
	Возврат ПараметрыПоУмолчанию;
	
КонецФункции

#КонецОбласти

#Область Метаданные

Функция ЯзыкСинтаксисаКонфигурации() Экспорт
	Если Метаданные.ВариантВстроенногоЯзыка = Метаданные.СвойстваОбъектов.ВариантВстроенногоЯзыка.Английский Тогда
		Возврат "Английский";
	Иначе
		Возврат "Русский";
	КонецЕсли;
КонецФункции

Функция ОбъектМетаданныхИмеетПредопределенные(ИмяТипаМетаданного)
	
	Объекты = Новый Массив();
	Объекты.Добавить("справочник");
	Объекты.Добавить("справочники");
	Объекты.Добавить("плансчетов");	
	Объекты.Добавить("планысчетов");	
	Объекты.Добавить("планвидовхарактеристик");
	Объекты.Добавить("планывидовхарактеристик");
	Объекты.Добавить("планвидоврасчета");
	Объекты.Добавить("планывидоврасчета");
	
	Возврат Объекты.Найти(НРег(ИмяТипаМетаданного)) <> Неопределено;
	
КонецФункции

Функция ОбъектМетаданныхИмеетВиртуальныеТаблицы(ИмяТипаМетаданного)
	
	Объекты = Новый Массив();
	Объекты.Добавить("РегистрыСведений");
	Объекты.Добавить("РегистрыНакопления");	
	Объекты.Добавить("РегистрыРасчета");
	Объекты.Добавить("РегистрыБухгалтерии");
	
	Возврат Объекты.Найти(ИмяТипаМетаданного) <> Неопределено;
	
КонецФункции


Функция ОписаниеРеквизитаОбъектаМетаданных(Реквизит,ТипВсеСсылки)
	Описание = Новый Структура;
	Описание.Вставить("Имя", Реквизит.Имя);
	Описание.Вставить("Синоним", Реквизит.Синоним);
	Описание.Вставить("Комментарий", Реквизит.Комментарий);
	
	СсылочныеТипы = Новый Массив;
	Для каждого ТекТ Из Реквизит.Тип.Типы() Цикл
		Если ТипВсеСсылки.СодержитТип(ТекТ) Тогда
			СсылочныеТипы.Добавить(ТекТ);
		КонецЕсли;
	КонецЦикла;
	Описание.Вставить("Тип", Новый ОписаниеТипов(СсылочныеТипы));
	
	Возврат Описание;
КонецФункции

Функция ОписаниеОбъектаМетаданныхКонфигурацииПоИмени(ВидОбъекта, ИмяОбъекта) Экспорт
	ТипВсеСсылки = UT_Common.AllRefsTypeDescription();

	Возврат ОписаниеОбъектаМетаданныхКонфигурации(Метаданные[ВидОбъекта][ИмяОбъекта], ВидОбъекта, ТипВсеСсылки);	
КонецФункции

Функция ОписаниеОбъектаМетаданныхКонфигурации(ОбъектМетаданных, ВидОбъекта, ТипВсеСсылки, ВключатьОписаниеРеквизитов = Истина) Экспорт
	ОписаниеЭлемента = Новый Структура;
	ОписаниеЭлемента.Вставить("ВидОбъекта", ВидОбъекта);
	ОписаниеЭлемента.Вставить("Имя", ОбъектМетаданных.Имя);
	ОписаниеЭлемента.Вставить("Синоним", ОбъектМетаданных.Синоним);
	ОписаниеЭлемента.Вставить("Комментарий", ОбъектМетаданных.Комментарий);
	
	Расширение = ОбъектМетаданных.РасширениеКонфигурации();
	Если Расширение <> Неопределено Тогда
		ОписаниеЭлемента.Вставить("Расширение", Расширение.Имя);
	Иначе
		ОписаниеЭлемента.Вставить("Расширение", Неопределено);
	КонецЕсли;
	Если НРег(ВидОбъекта) = "константа"
		Или НРег(ВидОбъекта) = "константы" Тогда
		ОписаниеЭлемента.Вставить("Тип", ОбъектМетаданных.Тип);
	ИначеЕсли НРег(ВидОбъекта) = "перечисление"
		Или НРег(ВидОбъекта) = "перечисления"Тогда
		ЗначенияПеречисления = Новый Структура;

		Для Каждого ТекЗнч Из ОбъектМетаданных.ЗначенияПеречисления Цикл
			ЗначенияПеречисления.Вставить(ТекЗнч.Имя, ТекЗнч.Синоним);
		КонецЦикла;

		ОписаниеЭлемента.Вставить("ЗначенияПеречисления", ЗначенияПеречисления);
	КонецЕсли;

	Если Не ВключатьОписаниеРеквизитов Тогда
		Возврат ОписаниеЭлемента;
	КонецЕсли;
	
	КоллекцииРеквизитов = Новый Структура("Реквизиты, СтандартныеРеквизиты, Измерения, Ресурсы, РеквизитыАдресации, ПризнакиУчета");
	КоллекцииТЧ = Новый Структура("ТабличныеЧасти, СтандартныеТабличныеЧасти");
	ЗаполнитьЗначенияСвойств(КоллекцииРеквизитов, ОбъектМетаданных);
	ЗаполнитьЗначенияСвойств(КоллекцииТЧ, ОбъектМетаданных);

	Для Каждого КлючЗначение Из КоллекцииРеквизитов Цикл
		Если КлючЗначение.Значение = Неопределено Тогда
			Продолжить;
		КонецЕсли;

		ОписаниеКоллекцииРеквизитов= Новый Структура;

		Для Каждого ТекРеквизит Из КлючЗначение.Значение Цикл
			ОписаниеКоллекцииРеквизитов.Вставить(ТекРеквизит.Имя, ОписаниеРеквизитаОбъектаМетаданных(ТекРеквизит,
				ТипВсеСсылки));
		КонецЦикла;

		ОписаниеЭлемента.Вставить(КлючЗначение.Ключ, ОписаниеКоллекцииРеквизитов);
	КонецЦикла;

	Для Каждого КлючЗначение Из КоллекцииТЧ Цикл
		Если КлючЗначение.Значение = Неопределено Тогда
			Продолжить;
		КонецЕсли;

		ОписаниеКоллекцииТЧ = Новый Структура;

		Для Каждого ТЧ Из КлючЗначение.Значение Цикл
			ОписаниеТЧ = Новый Структура;
			ОписаниеТЧ.Вставить("Имя", ТЧ.Имя);
			ОписаниеТЧ.Вставить("Синоним", ТЧ.Синоним);
			ОписаниеТЧ.Вставить("Комментарий", ТЧ.Комментарий);

			КоллекцииРеквизитовТЧ = Новый Структура("Реквизиты, СтандартныеРеквизиты");
			ЗаполнитьЗначенияСвойств(КоллекцииРеквизитовТЧ, ТЧ);
			Для Каждого ТекКоллекцияРеквизитовТЧ Из КоллекцииРеквизитовТЧ Цикл
				Если ТекКоллекцияРеквизитовТЧ.Значение = Неопределено Тогда
					Продолжить;
				КонецЕсли;

				ОписаниеКоллекцииРеквизитовТЧ = Новый Структура;

				Для Каждого ТекРеквизит Из ТекКоллекцияРеквизитовТЧ.Значение Цикл
					ОписаниеКоллекцииРеквизитовТЧ.Вставить(ТекРеквизит.Имя, ОписаниеРеквизитаОбъектаМетаданных(
						ТекРеквизит, ТипВсеСсылки));
				КонецЦикла;

				ОписаниеТЧ.Вставить(ТекКоллекцияРеквизитовТЧ.Ключ, ОписаниеКоллекцииРеквизитовТЧ);
			КонецЦикла;
			ОписаниеКоллекцииТЧ.Вставить(ТЧ.Имя, ОписаниеТЧ);
		КонецЦикла;

		ОписаниеЭлемента.Вставить(КлючЗначение.Ключ, ОписаниеКоллекцииТЧ);
	КонецЦикла;


	Если ОбъектМетаданныхИмеетПредопределенные(ВидОбъекта) Тогда

		Предопределенные = ОбъектМетаданных.ПолучитьИменаПредопределенных();

		ОписаниеПредопределенных = Новый Структура;
		Для Каждого Имя Из Предопределенные Цикл
			ОписаниеПредопределенных.Вставить(Имя, "");
		КонецЦикла;

		ОписаниеЭлемента.Вставить("Предопределенные", ОписаниеПредопределенных);
	КонецЕсли;
	
	Возврат ОписаниеЭлемента;
КонецФункции

Функция ОписаниеКоллекцииМетаданныхКонфигурации(Коллекция, ВидОбъекта, СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов) 
	ОписаниеКоллекции = Новый Структура();

	Для Каждого ОбъектМетаданных Из Коллекция Цикл
		ОписаниеЭлемента = ОписаниеОбъектаМетаданныхКонфигурации(ОбъектМетаданных, ВидОбъекта, ТипВсеСсылки, ВключатьОписаниеРеквизитов);
			
		ОписаниеКоллекции.Вставить(ОбъектМетаданных.Имя, ОписаниеЭлемента);
		
		Если UT_Common.ЭтоОбъектСсылочногоТипа(ОбъектМетаданных) Тогда
			СоответствиеТипов.Вставить(Тип(ВидОбъекта+"Ссылка."+ОписаниеЭлемента.Имя), ОписаниеЭлемента);
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат ОписаниеКоллекции;
КонецФункции

Функция ОписаниеОбщихМодулейКонфигурации() Экспорт
	ОписаниеКоллекции = Новый Структура();

	Для Каждого ОбъектМетаданных Из Метаданные.ОбщиеМодули Цикл
			
		ОписаниеКоллекции.Вставить(ОбъектМетаданных.Имя, Новый Структура);
		
	КонецЦикла;
	
	Возврат ОписаниеКоллекции;
КонецФункции

Функция ОписнаиеМетаданныйДляИнициализацииРедактораMonaco() Экспорт
	СоответствиеТипов = Новый Соответствие;
	ТипВсеСсылки = UT_Common.AllRefsTypeDescription();

	ОписаниеМетаданных = Новый Структура;
	ОписаниеМетаданных.Вставить("ОбщиеМодули", ОписаниеОбщихМодулейКонфигурации());
//	ОписаниеМетаданных.Вставить("Роли", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Роли, "Роль", СоответствиеТипов, ТипВсеСсылки));
//	ОписаниеМетаданных.Вставить("ОбщиеФормы", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ОбщиеФормы, "ОбщаяФорма", СоответствиеТипов, ТипВсеСсылки));

	Возврат ОписаниеМетаданных;	
КонецФункции

Функция ОписаниеМетаданныхКонфигурации(ВключатьОписаниеРеквизитов = Истина) Экспорт
	ТипВсеСсылки = UT_Common.AllRefsTypeDescription();
	
	ОписаниеМетаданных = Новый Структура;
	
	СоответствиеТипов = Новый Соответствие;
	
	ОписаниеМетаданных.Вставить("Имя", Метаданные.Имя);
	ОписаниеМетаданных.Вставить("Версия", Метаданные.Версия);
	ОписаниеМетаданных.Вставить("ТипВсеСсылки", ТипВсеСсылки);
	
	ОписаниеМетаданных.Вставить("Справочники", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Справочники, "Справочник", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Документы", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Документы, "Документ", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("РегистрыСведений", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.РегистрыСведений, "РегистрСведений", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("РегистрыНакопления", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.РегистрыНакопления, "РегистрНакопления", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("РегистрыБухгалтерии", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.РегистрыБухгалтерии, "РегистрБухгалтерии", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("РегистрыРасчета", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.РегистрыРасчета, "РегистрРасчета", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Обработки", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Обработки, "Обработка", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Отчеты", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Отчеты, "Отчет", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Перечисления", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Перечисления, "Перечисление", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ОбщиеМодули", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ОбщиеМодули, "ОбщийМодуль", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПланыСчетов", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПланыСчетов, "ПланСчетов", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("БизнесПроцессы", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.БизнесПроцессы, "БизнесПроцесс", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Задачи", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Задачи, "Задача", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПланыСчетов", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПланыСчетов, "ПланСчетов", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПланыОбмена", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПланыОбмена, "ПланОбмена", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПланыВидовХарактеристик", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПланыВидовХарактеристик, "ПланВидовХарактеристик", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПланыВидовРасчета", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПланыВидовРасчета, "ПланВидовРасчета", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("Константы", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.Константы, "Константа", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	ОписаниеМетаданных.Вставить("ПараметрыСеанса", ОписаниеКоллекцииМетаданныхКонфигурации(Метаданные.ПараметрыСеанса, "ПараметрСеанса", СоответствиеТипов, ТипВсеСсылки, ВключатьОписаниеРеквизитов));
	
	ОписаниеМетаданных.Вставить("СоответствиеСсылочныхТипов", СоответствиеТипов);
	
	Возврат ОписаниеМетаданных;
КонецФункции

Функция АдресОписанияМетаданныхКонфигурации() Экспорт
	ОПисание = ОписаниеМетаданныхКонфигурации();
	
	Возврат ПоместитьВоВременноеХранилище(ОПисание, Новый УникальныйИдентификатор);
КонецФункции

Функция СписокМетаданныхПоВиду(ВидМетаданных) Экспорт
	КоллекцияМетаданных = Метаданные[ВидМетаданных];
	
	МассивИмен = Новый Массив;
	Для Каждого ОбъектМетаданных Из КоллекцияМетаданных Цикл
		МассивИмен.Добавить(ОбъектМетаданных.Имя);
	КонецЦикла;
	
	Возврат МассивИмен;
КонецФункции

Процедура ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(СоответствиеТипов, Коллекция, ВидОбъекта)
	Для Каждого ОбъектМетаданных Из Коллекция Цикл
		ОписаниеЭлемента = Новый Структура;
		ОписаниеЭлемента.Вставить("Имя", ОбъектМетаданных.Имя);
		ОписаниеЭлемента.Вставить("ВидОбъекта", ВидОбъекта);
			
		СоответствиеТипов.Вставить(Тип(ВидОбъекта+"Ссылка."+ОбъектМетаданных.Имя), ОписаниеЭлемента);
	КонецЦикла;
	
КонецПроцедуры

Функция СоответствиеСсылочныхТипов() Экспорт
	Соответствие = Новый Соответствие;
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.Справочники, "Справочник");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.Документы, "Документ");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.Перечисления, "Перечисление");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.ПланыСчетов, "ПланСчетов");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.БизнесПроцессы, "БизнесПроцесс");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.Задачи, "Задача");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.ПланыСчетов, "ПланСчетов");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.ПланыОбмена, "ПланОбмена");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.ПланыВидовХарактеристик, "ПланВидовХарактеристик");
	ДобавитьКоллекциюМетаданныхВСоответствиеСсылочныхТипов(Соответствие, Метаданные.ПланыВидовРасчета, "ПланВидовРасчета");

	Возврат Соответствие;
КонецФункции

#КонецОбласти


#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Функция ТекущиеПараметрыРедактораMonaco() Экспорт
	ПараметрыИзХранилища =  UT_Common.ХранилищеОбщихНастроекЗагрузить(
		UT_CommonClientServer.SettingsDataKeyInSettingsStorage(), "ПараметрыРедактораMonaco",
		UT_CodeEditorClientServer.ПараметрыРедактораMonacoПоУмолчанию());

	ПараметрыПоУмолчанию = UT_CodeEditorClientServer.ПараметрыРедактораMonacoПоУмолчанию();
	ЗаполнитьЗначенияСвойств(ПараметрыПоУмолчанию, ПараметрыИзХранилища);

	Возврат ПараметрыПоУмолчанию;
КонецФункции

Функция ДоступныеИсточникиИсходногоКода() Экспорт
	Массив = Новый СписокЗначений();
	
	Массив.Добавить("ОсновнаяКонфигурация", "Основная конфигурация");
	
	МассивРасширений = РасширенияКонфигурации.Получить();
	Для Каждого ТекРасширение Из МассивРасширений Цикл
		Массив.Добавить(ТекРасширение.Имя, ТекРасширение.Синоним);
	КонецЦикла;
	
	Возврат Массив;
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

#КонецОбласти