import Foundation

extension APIClient {
    public func fetchUserAccess() async throws -> UserAccess {
        let url = serverURL.appending(path: "/v1/users/me/access")
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
        return try catalogJSONDecoder.decode(UserAccessJSON.self, from: data).toModel()
    }
}
