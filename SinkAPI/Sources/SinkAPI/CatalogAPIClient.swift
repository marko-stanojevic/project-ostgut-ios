import Foundation

extension APIClient {
    // MARK: - Anonymous session

    public func createAnonymousSession(existingToken: String? = nil) async throws -> AnonymousSessionToken {
        var request = URLRequest(url: serverURL.appending(path: "/v1/anonymous-sessions"))
        request.httpMethod = "POST"
        if let token = existingToken {
            request.setValue(token, forHTTPHeaderField: "X-Anonymous-Session")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201
        else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw CatalogAPIError.httpError(statusCode: status, message: nil)
        }
        return try catalogJSONDecoder.decode(AnonymousSessionJSON.self, from: data).toModel()
    }

    // MARK: - Catalog list

    public func fetchCatalog(
        limit: Int = 50,
        offset: Int = 0,
        anonymousSessionToken: String? = nil
    ) async throws -> CatalogPage {
        guard var components = URLComponents(
            url: serverURL.appending(path: "/v1/catalog"),
            resolvingAgainstBaseURL: true
        ) else {
            throw CatalogAPIError.invalidResponse("bad catalog URL")
        }
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "sort", value: "reliable")
        ]
        guard let url = components.url else {
            throw CatalogAPIError.invalidResponse("bad catalog URL components")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        await authorizeRequest(&request, anonymousSessionToken: anonymousSessionToken)

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decodeCatalogPage(data: data, response: response)
    }

    // MARK: - Catalog detail

    public func fetchCatalogDetail(id: String) async throws -> CatalogDetail {
        let url = serverURL.appending(path: "/v1/catalog/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogAPIError.invalidResponse("non-HTTP response")
        }
        if http.statusCode == 404 { throw CatalogAPIError.notFound }
        guard http.statusCode == 200 else {
            throw CatalogAPIError.httpError(statusCode: http.statusCode, message: nil)
        }
        return try catalogJSONDecoder.decode(CatalogDetailJSON.self, from: data).toModel()
    }

    // MARK: - Search

    public func search(
        query: String,
        limit: Int = 20,
        offset: Int = 0,
        anonymousSessionToken: String? = nil
    ) async throws -> CatalogPage {
        guard var components = URLComponents(
            url: serverURL.appending(path: "/v1/search"),
            resolvingAgainstBaseURL: true
        ) else {
            throw CatalogAPIError.invalidResponse("bad search URL")
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else {
            throw CatalogAPIError.invalidResponse("bad search URL components")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        await authorizeRequest(&request, anonymousSessionToken: anonymousSessionToken)

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decodeCatalogPage(data: data, response: response)
    }

    // MARK: - Playback URL resolution

    public func fetchPlayback(id: String) async throws -> CatalogPlayback {
        let url = serverURL.appending(path: "/v1/catalog/\(id)/playback")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        await authorizeRequest(&request, anonymousSessionToken: nil)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CatalogAPIError.invalidResponse("non-HTTP response")
        }
        if http.statusCode == 404 { throw CatalogAPIError.notFound }
        guard http.statusCode == 200 else {
            throw CatalogAPIError.httpError(statusCode: http.statusCode, message: nil)
        }
        return try catalogJSONDecoder.decode(CatalogPlaybackJSON.self, from: data).toModel()
    }

    // MARK: - Helpers

    private func decodeCatalogPage(data: Data, response: URLResponse) throws -> CatalogPage {
        guard let http = response as? HTTPURLResponse else {
            throw CatalogAPIError.invalidResponse("non-HTTP response")
        }
        guard http.statusCode == 200 else {
            throw CatalogAPIError.httpError(statusCode: http.statusCode, message: nil)
        }
        return try catalogJSONDecoder.decode(PaginatedCatalogCardCollectionJSON.self, from: data).toModel()
    }
}
