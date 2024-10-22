# KeychainAdapter

**KeychainAdapter** is a lightweight, thread-safe wrapper for interacting with the iOS Keychain. It simplifies the secure storage of sensitive data like user credentials, tokens, and other important information that needs to be stored securely on the device.

## Features

- Thread-safe operations using `NSLock`.
- Simple API for common Keychain interactions: save, retrieve, update, and delete.
- Custom error handling for Keychain-related issues.
- Support for saving and retrieving `Bool` values.
- Flexible configuration with customizable service key.

## Usage

### Creating an instance

To create an instance of `KeychainAdapterWrapper`, provide a unique service key to identify the service in the Keychain.

```swift
import KeychainAdapter

let keychain = KeychainAdapterWrapper(serviceKey: "com.example.myapp")
```
### Saving a value

To save a string value in the Keychain, use the `save` method:

```swift
do {
    try keychain.save("mySecretValue", forKey: "userToken")
} catch {
    print("Failed to save in Keychain: \(error)")
}
```
### Retrieving a value

To retrieve a value from the Keychain, use the `get` method:

```swift
do {
    if let token = try keychain.get(forKey: "userToken") {
        print("Token: \(token)")
    }
} catch {
    print("Failed to retrieve from Keychain: \(error)")
}
```

### Updating a value

To update an existing value in the Keychain, use the `update` method:

```swift
do {
    try keychain.update("newSecretValue", forKey: "userToken")
} catch {
    print("Failed to update in Keychain: \(error)")
}
```

### Deleting a value

To delete a value from the Keychain, use the `delete` method:

```swift
do {
    try keychain.delete(forKey: "userToken")
} catch {
    print("Failed to delete from Keychain: \(error)")
}
```

### Checking if a value exists

To check if a value exists for a given key, use the `getBool(forKey:)` method:

```swift
do {
    let exists = try keychain.getBool(forKey: "userToken")
    print("Token exists: \(exists)")
} catch {
    print("Error checking Keychain: \(error)")
}
```
