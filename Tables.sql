CREATE DATABASE IF NOT EXISTS Nomenclature;
USE nomenclature;

-- Таблица Номенклатура
CREATE TABLE Nomenclature (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Type ENUM('Запчасть', 'Комплект') NOT NULL,
    AssemblyTime INT NOT NULL -- Время сборки в минутах
);

-- Таблица Место сборки
CREATE TABLE AssemblySite (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Location VARCHAR(255) NOT NULL
);

-- Таблица Заказы
CREATE TABLE `Order` (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    IsCancelled TINYINT(1) DEFAULT 0
);

-- Таблица Номенклатуры заказов
CREATE TABLE OrderNomenclature (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    NomenclatureID INT NOT NULL,
    Quantity INT NOT NULL,
    Status ENUM('Зарезервировано', 'Произведено', 'Отменено') NOT NULL,
    ReserveUntil DATETIME NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES `Order`(ID) ON DELETE CASCADE,
    FOREIGN KEY (NomenclatureID) REFERENCES Nomenclature(ID) ON DELETE CASCADE
);

-- Таблица Задачи на сборку
CREATE TABLE AssemblyTask (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NomenclatureID INT NOT NULL,
    AssemblySiteID INT NOT NULL,
    DueDate DATETIME NOT NULL,
    CompletedDate DATETIME NULL,
    FOREIGN KEY (NomenclatureID) REFERENCES Nomenclature(ID),
    FOREIGN KEY (AssemblySiteID) REFERENCES AssemblySite(ID)
);

-- Таблица Инвентаризация
CREATE TABLE Inventory (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    AssemblySiteID INT NOT NULL,
    NomenclatureID INT NOT NULL,
    Quantity INT NOT NULL,
    Reserved BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (AssemblySiteID) REFERENCES AssemblySite(ID),
    FOREIGN KEY (NomenclatureID) REFERENCES Nomenclature(ID)
);

-- Процедура добавления заказа
-- АААААААА! в квардрате
CREATE PROCEDURE AddOrder(IN pOrderDate DATETIME, IN pNomenclatureID INT, IN pQuantity INT) -- Error: AssemblyTime is NULL or 0 for NomenclatureID: {id}. Как решать, хз. Думаю 
BEGIN
    DECLARE assemblyTime INT DEFAULT 0;  -- Установка значения по умолчанию
    DECLARE errorMessage TEXT;

    -- Получаем время сборки для выбранной номенклатуры
    SELECT AssemblyTime INTO assemblyTime
    FROM Nomenclature
    WHERE ID = pNomenclatureID
    LIMIT 1;

    -- Проверка значения assemblyTime
    IF assemblyTime IS NULL OR assemblyTime = 0 THEN
        SET errorMessage = CONCAT('AssemblyTime is NULL or 0 for NomenclatureID: ', pNomenclatureID);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = errorMessage;
    END IF;

    -- Рассчитываем дату завершения заказа (DueDate) на основе времени сборки
    SET @dueDate = DATE_ADD(pOrderDate, INTERVAL assemblyTime DAY);

    -- Проверка, что dueDate рассчитан корректно
    IF @dueDate IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DueDate calculation failed.';
    END IF;

    -- Добавляем заказ в таблицу Order
    INSERT INTO `Order` (OrderDate, DueDate) VALUES (pOrderDate, @dueDate);

    -- Получаем последний ID заказа для использования в дальнейшей обработке
    SET @lastOrderID = LAST_INSERT_ID();

    -- Добавляем позицию заказа в таблицу OrderNomenclature
    INSERT INTO OrderNomenclature (OrderID, NomenclatureID, Quantity, Status)
    VALUES (@lastOrderID, pNomenclatureID, pQuantity, 'Зарезервировано');
END;

CALL AddOrder(NOW(), 2, 5);
SELECT * FROM Nomenclature WHERE AssemblyTime IS NULL;
SELECT AssemblyTime FROM Nomenclature WHERE ID = 1;

-- Процедура проверки инвентаря и резервирования с учетом сроков
CREATE PROCEDURE CheckInventory(
    IN pNomenclatureID INT, 
    IN pQuantity INT, 
    IN pReserveUntil DATETIME, 
    OUT pAvailable INT
)
BEGIN
    SELECT SUM(Quantity) INTO pAvailable 
    FROM Inventory
    WHERE NomenclatureID = pNomenclatureID AND Reserved = FALSE;
    IF pAvailable >= pQuantity THEN
        -- Резервируем необходимые товары и устанавливаем срок резервирования
        UPDATE Inventory
        SET Reserved = TRUE
        WHERE NomenclatureID = pNomenclatureID AND Reserved = FALSE
        LIMIT pQuantity;
        -- Обновляем срок резервирования в OrderNomenclature
        INSERT INTO OrderNomenclature (OrderID, NomenclatureID, Quantity, Status, ReserveUntil)
        VALUES (LAST_INSERT_ID(), pNomenclatureID, pQuantity, 'Зарезервировано', pReserveUntil);
    END IF;
END;

-- АААААА!!!!! 
---Процедура реализации товара со склада и производство нового, если не хватает
CREATE PROCEDURE SellOrProduce(
    IN pOrderID INT, 
    IN pNomenclatureID INT, 
    IN pQuantity INT, 
    IN pAssemblySiteID INT
)
BEGIN
    DECLARE stockAvailable INT DEFAULT 0;
    DECLARE remainingToProduce INT DEFAULT pQuantity;
    -- Проверяем склад
    SELECT SUM(Quantity) INTO stockAvailable
    FROM Inventory
    WHERE NomenclatureID = pNomenclatureID AND Reserved = FALSE;
    -- Если товара на складе достаточно, уменьшаем количество на складе
    IF stockAvailable >= pQuantity THEN
        UPDATE Inventory
        SET Quantity = Quantity - pQuantity
        WHERE NomenclatureID = pNomenclatureID AND Reserved = FALSE
        LIMIT 1;
        -- Обновляем статус номенклатуры в заказе на "Произведено"
        UPDATE OrderNomenclature
        SET Status = 'Произведено'
        WHERE OrderID = pOrderID AND NomenclatureID = pNomenclatureID;
    ELSE
        -- Если товара не хватает, сначала используем то, что есть
        IF stockAvailable > 0 THEN
            UPDATE Inventory
            SET Quantity = 0
            WHERE NomenclatureID = pNomenclatureID AND Reserved = FALSE;

            SET remainingToProduce = pQuantity - stockAvailable;
        END IF;
        -- Планируем сборку недостающего товара
        INSERT INTO AssemblyTask (NomenclatureID, AssemblySiteID, DueDate)
        VALUES (pNomenclatureID, pAssemblySiteID, NOW() + INTERVAL (SELECT AssemblyTime FROM Nomenclature WHERE ID = pNomenclatureID) MINUTE);
        -- Обновляем статус номенклатуры в заказе на "Зарезервировано", пока не произведено
        UPDATE OrderNomenclature
        SET Status = 'Зарезервировано'
        WHERE OrderID = pOrderID AND NomenclatureID = pNomenclatureID;
    END IF;
END;

-- Триггер на отмену заказа
CREATE TRIGGER AfterOrderCancelled
AFTER UPDATE ON `Order`
FOR EACH ROW
BEGIN
    IF NEW.IsCancelled = TRUE THEN
        -- Снимаем резерв с номенклатуры при отмене заказа
        UPDATE Inventory
        SET Reserved = FALSE
        WHERE NomenclatureID IN (
            SELECT NomenclatureID 
            FROM OrderNomenclature 
            WHERE OrderID = NEW.ID
        )
        AND Reserved = TRUE;
    END IF;
END;

-- Процедура отмены заказа
CREATE PROCEDURE CancelOrder(IN pOrderID INT)
BEGIN
    -- Обновляем статус заказа на "отменен"
    UPDATE `Order`
    SET IsCancelled = TRUE
    WHERE ID = pOrderID;
    -- Снимаем резерв с номенклатуры, связанной с этим заказом
    UPDATE Inventory
    SET Reserved = FALSE
    WHERE NomenclatureID IN (
        SELECT NomenclatureID 
        FROM OrderNomenclature 
        WHERE OrderID = pOrderID
    )
    AND Reserved = TRUE;
END;

SELECT a.ID, n.Name, a.DueDate, a.CompletedDate
FROM AssemblyTask a
JOIN Nomenclature n ON a.NomenclatureID = n.ID
WHERE a.AssemblySiteID = 1;

-- Заполняем таблицу Nomenclature
INSERT INTO Nomenclature (Name, Type, AssemblyTime) VALUES
('Запчасть A', 'Запчасть', 10),
('Запчасть B', 'Запчасть', 15),
('Комплект X', 'Комплект', 30),
('Комплект Y', 'Комплект', 45);

-- Заполняем таблицу AssemblySite
INSERT INTO AssemblySite (Name, Location) VALUES
('Сборочная площадка 1', 'Локация 1'),
('Сборочная площадка 2', 'Локация 2'),
('Сборочная площадка 3', 'Локация 3');

-- Заполняем таблицу Order
INSERT INTO `Order` (OrderDate, IsCancelled) VALUES
('2024-09-01 08:00:00', FALSE),
('2024-09-03 10:00:00', TRUE);


-- Заполняем таблицу OrderNomenclature
INSERT INTO OrderNomenclature (OrderID, NomenclatureID, Quantity, Status, ReserveUntil) VALUES
(1, 1, 10, 'Зарезервировано'),
(1, 3, 2, 'Произведено'),
(2, 2, 5, 'Зарезервировано'),
(2, 4, 1, 'Произведено'),
(3, 1, 3, 'Отменено');

-- Заполняем таблицу AssemblyTask
INSERT INTO AssemblyTask (NomenclatureID, AssemblySiteID, DueDate, CompletedDate) VALUES
(1, 1, '2024-09-05 17:00:00', NULL),
(2, 2, '2024-09-06 17:00:00', '2024-09-06 15:00:00'),
(3, 3, '2024-09-10 17:00:00', NULL),
(4, 1, '2024-09-11 17:00:00', NULL);

-- Заполняем таблицу Inventory
INSERT INTO Inventory (AssemblySiteID, NomenclatureID, Quantity, Reserved) VALUES
(1, 1, 20, FALSE),
(1, 3, 5, TRUE),
(2, 2, 10, FALSE),
(3, 4, 7, TRUE),
(2, 1, 8, FALSE);
