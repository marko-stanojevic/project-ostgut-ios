import Foundation

extension APIClient {
    public func fetchPlayerPreferences() async throws -> PlayerPreferences {
        let url = serverURL.appending(path: "/v1/users/me/player-preferences")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        await authorizeRequest(&request, anonymousSessionToken: nil)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogAPIError.invalidResponse("non-HTTP response")
        }
        guard http.statusCode == 200 else {
            throw CatalogAPIError.httpError(statusCode: http.statusCode, message: nil)
        }
        return try catalogJSONDecoder.decode(PlayerPreferencesJSON.self, from: data).toModel()
    }

    public func updatePlayerPreferences(_ prefs: PlayerPreferences) async throws -> PlayerPreferencesWriteResult {
        let url = serverURL.appending(path: "/v1/users/me/player-preferences")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await authorizeRequest(&request, anonymousSessionToken: nil)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(PlayerPreferencesUpdateBody(from: prefs))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogAPIError.invalidResponse("non-HTTP response")
        }
        guard http.statusCode == 200 else {
            throw CatalogAPIError.httpError(statusCode: http.statusCode, message: nil)
        }
        return try catalogJSONDecoder.decode(PlayerPreferencesWriteResultJSON.self, from: data).toModel()
    }
}
