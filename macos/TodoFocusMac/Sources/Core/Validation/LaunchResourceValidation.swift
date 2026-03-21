import Foundation

private let maxLaunchResources = 12
private let maxLaunchResourcesPayloadLength = 16_000
private let allowedDeepLinkSchemes: Set<String> = ["obsidian", "notion", "raycast"]

enum LaunchResourceValidationError: Error, Equatable {
    case invalidType
    case invalidLabel
    case invalidValue
    case invalidURL
    case invalidFilePath
    case invalidAppTarget
}

enum LaunchResourceSerializationResult: Equatable {
    case ok(String)
    case payloadTooLarge
}

func validateLaunchResource(_ input: LaunchResource) -> Result<LaunchResource, LaunchResourceValidationError> {
    sanitizeLaunchResource(
        id: input.id,
        typeRawValue: input.type.rawValue,
        label: input.label,
        value: input.value,
        createdAtRawValue: formatISODate(input.createdAt)
    )
}

func parseLaunchResources(raw: String?) -> [LaunchResource] {
    guard let raw else { return [] }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    guard trimmed.count <= maxLaunchResourcesPayloadLength else { return [] }
    guard let data = trimmed.data(using: .utf8) else { return [] }

    guard let object = try? JSONSerialization.jsonObject(with: data),
          let decoded = object as? [Any] else {
        return []
    }

    var output: [LaunchResource] = []
    output.reserveCapacity(min(decoded.count, maxLaunchResources))

    for item in decoded {
        if output.count >= maxLaunchResources {
            break
        }

        guard let dictionary = item as? [String: Any] else {
            continue
        }

        if case let .success(sanitized) = sanitizeLaunchResource(
            id: dictionary["id"] as? String,
            typeRawValue: dictionary["type"] as? String,
            label: dictionary["label"] as? String,
            value: dictionary["value"] as? String,
            createdAtRawValue: dictionary["createdAt"] as? String
        ) {
            output.append(sanitized)
        }
    }

    return output
}

func trySerializeLaunchResources(_ items: [LaunchResource]) -> LaunchResourceSerializationResult {
    var sanitized: [LaunchResource] = []
    sanitized.reserveCapacity(min(items.count, maxLaunchResources))

    for item in items {
        if sanitized.count >= maxLaunchResources {
            break
        }

        if case let .success(value) = validateLaunchResource(item) {
            sanitized.append(value)
        }
    }

    guard let serialized = serializeResources(sanitized) else {
        return .ok("[]")
    }

    if serialized.count > maxLaunchResourcesPayloadLength {
        return .payloadTooLarge
    }

    return .ok(serialized)
}

private func sanitizeLaunchResource(
    id: String?,
    typeRawValue: String?,
    label: String?,
    value: String?,
    createdAtRawValue: String?
) -> Result<LaunchResource, LaunchResourceValidationError> {
    guard let typeRawValue else {
        return .failure(.invalidType)
    }

    guard let type = LaunchResourceType(rawValue: typeRawValue.lowercased()) else {
        return .failure(.invalidType)
    }

    let trimmedLabel = (label ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard (1...80).contains(trimmedLabel.count) else {
        return .failure(.invalidLabel)
    }

    let trimmedValue = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedValue.isEmpty else {
        return .failure(.invalidValue)
    }

    switch type {
    case .url:
        guard isValidHTTPURL(trimmedValue) else {
            return .failure(.invalidURL)
        }
    case .file:
        guard isValidAbsoluteFilePath(trimmedValue) else {
            return .failure(.invalidFilePath)
        }
    case .app:
        guard isValidAppTarget(trimmedValue) else {
            return .failure(.invalidAppTarget)
        }
    }

    let trimmedID = (id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let resolvedID = trimmedID.isEmpty
        ? createDeterministicID(type: type, label: trimmedLabel, value: trimmedValue)
        : trimmedID

    let createdAt = parseISODate(createdAtRawValue) ?? Date(timeIntervalSince1970: 0)

    return .success(
        LaunchResource(
            id: resolvedID,
            type: type,
            label: trimmedLabel,
            value: trimmedValue,
            createdAt: createdAt
        )
    )
}

private func createDeterministicID(type: LaunchResourceType, label: String, value: String) -> String {
    let source = "\(type.rawValue)|\(label)|\(value)"
    var hash: UInt32 = 0

    for scalar in source.unicodeScalars {
        hash = (hash &* 31) &+ UInt32(scalar.value)
    }

    return "lr_\(String(hash, radix: 36))"
}

private func serializeResources(_ items: [LaunchResource]) -> String? {
    let payload: [[String: Any]] = items.map { item in
        [
            "id": item.id,
            "type": item.type.rawValue,
            "label": item.label,
            "value": item.value,
            "createdAt": formatISODate(item.createdAt)
        ]
    }

    guard let data = try? JSONSerialization.data(withJSONObject: payload),
          let serialized = String(data: data, encoding: .utf8) else {
        return nil
    }

    return serialized
}

private func parseISODate(_ raw: String?) -> Date? {
    guard let raw else { return nil }
    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    fractionalFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    if let date = fractionalFormatter.date(from: raw) {
        return date
    }

    let plainFormatter = ISO8601DateFormatter()
    plainFormatter.formatOptions = [.withInternetDateTime]
    plainFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return plainFormatter.date(from: raw)
}

private func formatISODate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}

private func isValidHTTPURL(_ value: String) -> Bool {
    guard let components = URLComponents(string: value),
          let scheme = components.scheme?.lowercased(),
          let host = components.host,
          !host.isEmpty else {
        return false
    }

    return scheme == "http" || scheme == "https"
}

private func hasTraversalPattern(_ value: String) -> Bool {
    return value.range(of: #"(^|[\\/])\.\.([\\/]|$)"#, options: .regularExpression) != nil
}

private func isValidAbsoluteFilePath(_ value: String) -> Bool {
    guard value.hasPrefix("/") else { return false }
    guard value.count > 1 else { return false }
    guard !hasTraversalPattern(value) else { return false }
    return true
}

private func isValidAppTarget(_ value: String) -> Bool {
    if value.hasPrefix("/") {
        guard !hasTraversalPattern(value) else { return false }
        return value.hasSuffix(".app") || value.contains(".app/")
    }

    guard let components = URLComponents(string: value),
          let scheme = components.scheme?.lowercased() else {
        return false
    }

    return allowedDeepLinkSchemes.contains(scheme)
}
