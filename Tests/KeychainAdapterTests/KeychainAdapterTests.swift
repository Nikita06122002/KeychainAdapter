import XCTest
@testable import KeychainAdapter

final class KeychainAdapterWrapperTests: XCTestCase {

    private var keychain: KeychainAdapter!

    override func setUp() {
        super.setUp()
        // Создаем новый экземпляр KeychainAdapterWrapper с уникальным serviceKey для тестов
        keychain = KeychainAdapter(serviceKey: "com.test.keychain")
    }

    override func tearDown() {
        // Чистим ключи после каждого теста
        try? keychain.delete(forKey: "testKey")
        super.tearDown()
    }

    /// Тестируем метод сохранения строки в Keychain
    func testSaveAndGetString() throws {
        let testString = "Hello, Keychain!"
        let key = "testKey"
        
        // Сохраняем строку
        let saveResult = try keychain.save(testString, forKey: key)
        XCTAssertTrue(saveResult, "Строка должна быть успешно сохранена в Keychain")
        
        // Получаем строку
        let retrievedString = try keychain.get(forKey: key)
        XCTAssertEqual(retrievedString, testString, "Полученное значение должно соответствовать сохраненному")
    }

    /// Тестируем обновление строки в Keychain
    func testUpdateString() throws {
        let initialString = "Initial String"
        let updatedString = "Updated String"
        let key = "testKey"
        
        // Сохраняем начальное значение
        try keychain.save(initialString, forKey: key)
        
        // Обновляем значение
        let updateResult = try keychain.update(updatedString, forKey: key)
        XCTAssertTrue(updateResult, "Обновление значения должно пройти успешно")
        
        // Проверяем, что значение обновилось
        let retrievedString = try keychain.get(forKey: key)
        XCTAssertEqual(retrievedString, updatedString, "Значение должно быть обновлено в Keychain")
    }

    /// Тестируем удаление значения из Keychain
    func testDeleteKeychainValue() throws {
        let testString = "Value to delete"
        let key = "testKey"
        
        // Сохраняем значение
        try keychain.save(testString, forKey: key)
        
        // Удаляем значение
        try keychain.delete(forKey: key)
        
        // Проверяем, что значение удалено
        let retrievedString = try keychain.get(forKey: key)
        XCTAssertNil(retrievedString, "Значение должно быть удалено из Keychain")
    }

    /// Тестируем проверку существования значения
    func testGetBoolForKey() throws {
        let testString = "Bool check"
        let key = "testKey"
        
        // Проверяем, что ключ отсутствует
        let doesNotExist = try keychain.getBool(forKey: key)
        XCTAssertFalse(doesNotExist, "Ключ не должен существовать в Keychain до его сохранения")
        
        // Сохраняем значение
        try keychain.save(testString, forKey: key)
        
        // Проверяем, что ключ теперь существует
        let doesExist = try keychain.getBool(forKey: key)
        XCTAssertTrue(doesExist, "Ключ должен существовать после его сохранения в Keychain")
    }

    /// Тестируем валидацию пустых значений
    func testEmptyKeyThrowsError() {
        XCTAssertThrowsError(try keychain.save("value", forKey: "")) { error in
            XCTAssertEqual(error as? KeychainAdapter.KeychainAdapterError, .keyIsEmpty, "Должна быть ошибка при передаче пустого ключа")
        }
    }

    func testEmptyValueThrowsError() {
        XCTAssertThrowsError(try keychain.save("", forKey: "testKey")) { error in
            XCTAssertEqual(error as? KeychainAdapter.KeychainAdapterError, .valueIsEmpty, "Должна быть ошибка при передаче пустого значения")
        }
    }
}
