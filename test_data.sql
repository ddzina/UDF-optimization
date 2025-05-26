-- Цель: Сгенерировать 50 000 заказов (Works) со средним количеством элементов в заказе (WorkItem) равным 3.

-- Шаг 1: Заполнение справочных таблиц (если они пустые)
-- Добавьте свои значения или измените их
IF NOT EXISTS (SELECT 1 FROM dbo.WorkStatus)
BEGIN
    INSERT INTO dbo.WorkStatus (StatusName) VALUES ('Новый'), ('В работе'), ('Завершен');
END

IF NOT EXISTS (SELECT 1 FROM dbo.SelectType)
BEGIN
    INSERT INTO dbo.SelectType (SelectType) VALUES ('Обычный'), ('Срочный');
END

-- Заполнение таблицы Employee (если она пустая)
-- Важно: WorkItem ссылается на Employee
IF NOT EXISTS (SELECT 1 FROM dbo.Employee)
BEGIN
    INSERT INTO dbo.Employee (Login_Name, Name, Patronymic, Surname, Archived, IS_Role, Role)
    VALUES ('user_first', 'Петр', 'Иванович', 'Степанов', 0, 0, 0);
END

-- Заполнение таблицы Organization (если она пустая)
-- Важно: Works ссылается на Organization
IF NOT EXISTS (SELECT 1 FROM dbo.Organization)
BEGIN
    INSERT INTO dbo.Organization (ORG_NAME) VALUES ('Поликлиника №1');
    INSERT INTO dbo.Organization (ORG_NAME) VALUES ('Клиника "Здоровье"');
END

-- Заполнение таблицы Analiz (если она пустая)
-- Важно: WorkItem ссылается на Analiz
IF NOT EXISTS (SELECT 1 FROM dbo.Analiz)
BEGIN
    INSERT INTO dbo.Analiz (FULL_NAME, Price) VALUES ('Анализ 1', 100.00);
    INSERT INTO dbo.Analiz (FULL_NAME, Price) VALUES ('Анализ 2', 150.00);
    INSERT INTO dbo.Analiz (FULL_NAME, Price) VALUES ('Анализ 3', 200.00);
    -- Добавьте другие анализы, если нужно
END

-- Шаг 2: Объявление переменных
DECLARE @NumWorks INT = 50000;       -- Количество заказов (Works)
DECLARE @AvgItemsPerWork INT = 3;   -- Среднее количество элементов в заказе
DECLARE @CounterWorks INT = 1;      -- Счетчик заказов

-- Шаг 3: Генерация данных для таблицы Works
WHILE @CounterWorks <= @NumWorks
BEGIN
    INSERT INTO dbo.Works (IS_Complit, CREATE_Date, Id_Employee, ID_ORGANIZATION, FIO, Is_Del, StatusId)
    SELECT
        CAST(ROUND(RAND(),0) AS BIT),
        GETDATE(),
        (SELECT TOP 1 Id_Employee FROM dbo.Employee ORDER BY NEWID()),
        (SELECT TOP 1 ID_ORGANIZATION FROM dbo.Organization ORDER BY NEWID()),
        'Клиент ' + CAST(@CounterWorks AS VARCHAR(10)),
        0,
        (SELECT TOP 1 StatusID FROM dbo.WorkStatus ORDER BY NEWID());

    -- Шаг 4: Генерация случайного количества элементов WorkItem для текущего заказа
    DECLARE @NumItemsForWork INT = ROUND(@AvgItemsPerWork * (0.5 + RAND()), 0); -- Случайное количество около среднего

    DECLARE @CounterItems INT = 1;
    DECLARE @CurrentWorkId INT = SCOPE_IDENTITY(); -- ID только что созданного Works

    WHILE @CounterItems <= @NumItemsForWork
    BEGIN
        INSERT INTO dbo.WorkItem (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType)
        SELECT
            GETDATE(),
            CAST(ROUND(RAND(),0) AS BIT),
            (SELECT TOP 1 Id_Employee FROM dbo.Employee ORDER BY NEWID()),
            (SELECT TOP 1 ID_ANALIZ FROM dbo.Analiz ORDER BY NEWID()),
            @CurrentWorkId,
            CAST(ROUND(RAND(),0) AS BIT),
            CAST(ROUND(RAND(),0) AS BIT),
            1,
            (SELECT TOP 1 Price FROM dbo.Analiz ORDER BY NEWID()),
            (SELECT TOP 1 Id_SelectType FROM dbo.SelectType ORDER BY NEWID());

        SET @CounterItems = @CounterItems + 1;
    END

    SET @CounterWorks = @CounterWorks + 1;
END
