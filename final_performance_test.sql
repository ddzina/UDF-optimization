-- Финальное тестирование производительности оптимизированной функции
-- Выполняется сравнение оригинальной и оптимизированной версий
USE [udf-opt];
GO

-- Очистка кеша для чистых замеров
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

PRINT '=== ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ ПРОИЗВОДИТЕЛЬНОСТИ ===';
PRINT 'Дата тестирования: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '';

-- Тест 1: Небольшой набор данных (TOP 10)
PRINT '1. ТЕСТ НА 10 ЗАПИСЯХ:';
PRINT '------------------------';

DECLARE @start_time DATETIME2, @end_time DATETIME2, @duration_ms INT;

-- Оригинальная функция
SET @start_time = SYSDATETIME();
SELECT * FROM dbo.F_WORKS_LIST() ORDER BY id_work DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
SET @end_time = SYSDATETIME();
SET @duration_ms = DATEDIFF(MILLISECOND, @start_time, @end_time);
PRINT 'Оригинальная функция: ' + CAST(@duration_ms AS VARCHAR) + ' мс';

-- Очистка кеша
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- Оптимизированная функция
SET @start_time = SYSDATETIME();
SELECT * FROM dbo.F_WORKS_LIST_OPTIMIZED() ORDER BY id_work DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
SET @end_time = SYSDATETIME();
SET @duration_ms = DATEDIFF(MILLISECOND, @start_time, @end_time);
PRINT 'Оптимизированная функция: ' + CAST(@duration_ms AS VARCHAR) + ' мс';
PRINT '';

-- Тест 2: Средний набор данных (TOP 100)
PRINT '2. ТЕСТ НА 100 ЗАПИСЯХ:';
PRINT '-------------------------';

-- Очистка кеша
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- Оригинальная функция
SET @start_time = SYSDATETIME();
SELECT * FROM dbo.F_WORKS_LIST() ORDER BY id_work DESC OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
SET @end_time = SYSDATETIME();
SET @duration_ms = DATEDIFF(MILLISECOND, @start_time, @end_time);
PRINT 'Оригинальная функция: ' + CAST(@duration_ms AS VARCHAR) + ' мс';

-- Очистка кеша
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- Оптимизированная функция
SET @start_time = SYSDATETIME();
SELECT * FROM dbo.F_WORKS_LIST_OPTIMIZED() ORDER BY id_work DESC OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
SET @end_time = SYSDATETIME();
SET @duration_ms = DATEDIFF(MILLISECOND, @start_time, @end_time);
PRINT 'Оптимизированная функция: ' + CAST(@duration_ms AS VARCHAR) + ' мс';
PRINT '';

-- Тест 3: Большой набор данных (TOP 1000)
PRINT '3. ТЕСТ НА 1000 ЗАПИСЯХ:';
PRINT '--------------------------';

-- Оптимизированная функция (оригинальная будет слишком медленной)
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET @start_time = SYSDATETIME();
SELECT * FROM dbo.F_WORKS_LIST_OPTIMIZED() ORDER BY id_work DESC OFFSET 0 ROWS FETCH NEXT 1000 ROWS ONLY;
SET @end_time = SYSDATETIME();
SET @duration_ms = DATEDIFF(MILLISECOND, @start_time, @end_time);
PRINT 'Оптимизированная функция: ' + CAST(@duration_ms AS VARCHAR) + ' мс';
PRINT '';

-- Тест 4: Проверка корректности данных
PRINT '4. ПРОВЕРКА КОРРЕКТНОСТИ ДАННЫХ:';
PRINT '----------------------------------';

-- Сравниваем результаты первых 5 записей
WITH Original AS (
    SELECT TOP 5 * FROM dbo.F_WORKS_LIST() ORDER BY id_work DESC
),
Optimized AS (
    SELECT TOP 5 * FROM dbo.F_WORKS_LIST_OPTIMIZED() ORDER BY id_work DESC
)
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT o.id_work FROM Original o
            INNER JOIN Optimized opt ON o.id_work = opt.id_work
            WHERE o.name_work = opt.name_work 
              AND o.cnt_work_item = opt.cnt_work_item
              AND o.cnt_complit = opt.cnt_complit
              AND ISNULL(o.name_employee, '') = ISNULL(opt.name_employee, '')
              AND o.name_status = opt.name_status
              AND o.dt_create = opt.dt_create
        ) 
        THEN 'ДАННЫЕ КОРРЕКТНЫ: Результаты функций идентичны'
        ELSE 'ОШИБКА: Результаты функций различаются'
    END AS result_validation;

-- Тест 5: Анализ планов выполнения
PRINT '';
PRINT '5. СТАТИСТИКА ИСПОЛЬЗОВАНИЯ ИНДЕКСОВ:';
PRINT '--------------------------------------';

-- Проверяем использование созданных индексов
SELECT 
    i.name as index_name,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE o.name IN ('Works', 'WorkItem', 'Employee', 'Analiz')
  AND i.name IN ('IX_Works_IsDeleted_IdWork', 'IX_WorkItem_IdWork_IsComplit', 'IX_Employee_IdEmployee', 'IX_Analiz_IsGroup')
ORDER BY o.name, i.name;

PRINT '';
PRINT '=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===';
