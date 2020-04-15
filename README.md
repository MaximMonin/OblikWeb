# OblikWeb
OblikWeb Pilot project. From https://code.google.com/archive/p/oblikweb/

Web Interface for Oblik ERP/WMS. Build on Flex and OpenEdge Webservices. SOA Architecture. State free model with context managment. Most Information is given using Russian language.

Веб интерфейс для Облик ERP/Облик WMS. Проект выполняется с использованием технологий Adobe Flex и Progress Openedge Webservices. За основу взята SOA архитектура.

Большинство материалов на русском языке. Проект использует state free модель по работе с БД (нет реального соединения и использования ресурсов в момент простоя). Вместо глобальных переменных используется БД контекст менеджмента.

На текущий момент доступ к рабочей БД сделан упрощенный, с запоминанием первого успешного входа, поэтому вводить логин/пароль для работы с БД почти никогда не нужно.

At the moment 7 services implemented:

Console.
1.1 Login to web db, display services (progress openedge db) available.

1.2 Login to one/many Oblik work DB.

1.3 Display Oblik User menu (positions/applications) available to user.

1.4 Run Oblik External module from menu or fast menu.

1.5 Context management and security based on context key implemented.

1.6 Multilanguage Support

Dbview service. Приложение (application) Администратор приложений, Модуль (module) База данных. 
2.1 Displays Db table list.

2.2 Displays Fields/indexes/triggers/table relations available for selected table.

2.3 View Contents of any table (first N records).

2.4 Request time (in ms) available.

2.5 Multilanguage support.

Document Service.
3.1 Displays document list of any document type selected.

3.2 Universal document viewer (Double click). Read form from Database and Render it, display data inside fields/tables.

3.3 Gets dynamic Context Menu for document selected.

3.4 Universal Document Editor ("Редактировать"(Edit)/"Создать новый" (New Doc)/"Создать новый связанный" (New Related Doc) from Context Menu).

Read Document structure (fields and tables) from Database and render Editor Form.

Create Remote Object on server side, locks document and cache document data.

Sends event (NewDocument/OnIntegrity) before opening and change cached data.

Get cache Data and Render it inside fields and tables of Editor form.

Supports field editing for 190+ datatypes implemented. Mostly you select records from database dictionary by typing some value (like google search) or press (down button) to display whole or first 1000 records of dictionary.

Support of OnGetContext event - Field selection depends on values of others document fields.

OnModify/OnSelect events are sending to remote server side object.

Server side object executes business logic OnMofify/OnAfterSelect and returns set of fields changed by trigger. Client renders changes in Editor Form. Also server returns sets of fields disabled/enabled by business logic. Client changes fields atributes (ReadOnly + Enabled).

Supports table editing (new line/insert line/delete line)

Supports Save Document/PrintForm/Delete Document. Events are sending to server side object. It executes OnBeforeClose/OnCloseDocument/OnAfterClose/OnBeforePrint/OnPrint/OnDeleteDocument business logic events on server side. Modified Cache document saving to Database, generates accounting records depending of business logic/generates print form.

Print form preview. Supports Excel/csv print form/report preview in the form of grids. Supports text files print preview + printing directly from application. Downloaded files can be saved to disk.

3.5 Attach files to document (Прикрепленные файлы - "Прикрепить новый файл") - file uploading process starting. File saves in Database.

3.6 Download attached files. Download process started. User saves file on local machine. Upload/download processes are multi-threads, they run in background. User can do its work w/o any waiting.

3.7 View Related Document info. Display accounting records/document relation records/audit records/protocol records/errors/etc...

3.8 Extended document list search. User can select any document field and sets its value to filter data.

3.9 Multilanguage support.

Report Service. Service is build on the kernel of Document Editor. It enables to fill out report entry form and run report to get output file (mostly excel format). Service supports multi-threads. It is possible to build as many reports as you want in parallel. Unlike to Document Editor it doesnt keep persistent connection to server. Instead it recreates report form cache with every WS call and then proceeds just like remote persistent object. File cache dump is used for this goal.

Business procedure Service. It uses the same flash module as report service. Service can run server side procedures and make db transactions.

User Administrator. Add web users, assign services to users, change user's profiles. Service works inside Console.swf. Demo user can access it in readonly mode.

Web System Administartor.

7.1 Manage Service types list, Manage Databases list - data sources for services.

7.2 Register new services, giving to user right to use service. Advanced User managment, system admin can ban users. Demo user can access this service in readonly mode.

3 table editing templates supported. 1. Table browse (readonly) + Separate window for record editing (User Management). 2. Table browse editing (for small tables like Databases list/Service Types). 3. Table browse (read only) + edit record template in one window (service list editor).

7.3 View session/context Database. Reports user sessions, context threads, context params used. Multilanguage support + advanced security implemented on client and server sides for this service.

Few opensource project used: http://code.google.com/p/flexlib/ - SuperTabNavigator class - for displaying windows in the form of tabs.

AutoComplete (http://code.google.com/p/flex-autocomplete/) - for selection from database.

as3xls (http://code.google.com/p/as3xls/) - for parsing xls95/cvs files.

flexreport (http://code.google.com/p/flexreport/) - for text files print preview/printing.

All open source projects were modified a bit. Changed sources can be found in Common library http://code.google.com/p/oblikweb/source/browse/?repo=webservices#hg/commonlibs/webapp

Project Information
License: Apache License 2.0
3 stars
hg-based source control
