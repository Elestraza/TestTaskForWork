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
CREATE PROCEDURE AddOrder(IN pOrderDate DATETIME, IN pNomenclatureID INT, IN pQuantity INT) 
BEGIN
    DECLARE assemblyTime INT DEFAULT 0;
    DECLARE errorMessage TEXT;
    DECLARE dueDate DATETIME;

    -- Получаем AssemblyTime
    SELECT N.AssemblyTime INTO assemblyTime
    FROM nomenclature.Nomenclature N
    WHERE N.ID = pNomenclatureID
    LIMIT 1;

    -- Проверка значения assemblyTime
    IF assemblyTime IS NULL THEN
        SET errorMessage = CONCAT('NomenclatureID: ', pNomenclatureID, ' does not exist or AssemblyTime is NULL');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = errorMessage;
    ELSEIF assemblyTime = 0 THEN
        SET errorMessage = CONCAT('AssemblyTime is 0 for NomenclatureID: ', pNomenclatureID);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = errorMessage;
    END IF;

    -- Рассчитываем DueDate
    SET dueDate = DATE_ADD(pOrderDate, INTERVAL assemblyTime MINUTE);

    -- Проверка DueDate
    IF dueDate IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DueDate calculation failed.';
    END IF;

    -- Вставляем заказ
    INSERT INTO nomenclature.`Order` (OrderDate, DueDate) VALUES (pOrderDate, dueDate);

    -- Получаем последний ID заказа
    SET @lastOrderID = LAST_INSERT_ID();

    -- Вставляем OrderNomenclature
    INSERT INTO nomenclature.OrderNomenclature (OrderID, NomenclatureID, Quantity, Status, ReserveUntil)
    VALUES (@lastOrderID, pNomenclatureID, pQuantity, 'Зарезервировано', dueDate);
END;

CREATE PROCEDURE TestAssemblyTime(IN pNomenclatureID INT)
BEGIN
    SELECT AssemblyTime 
    FROM Nomenclature 
    WHERE ID = pNomenclatureID;
END;

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
