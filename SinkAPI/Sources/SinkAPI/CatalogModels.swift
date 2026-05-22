import Foundation

// MARK: - Catalog types

public struct CatalogCard: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let slug: String
    public let kind: String
    public let country: String
    public let genreTags: [String]
    public let icon: CatalogIcon?
    public let staffPick: Bool
    public let featured: Bool
    public let isFavorited: Bool?

    public init(
        id: String,
        name: String,
        slug: String,
        kind: String,
        country: String,
        genreTags: [String],
        icon: CatalogIcon?,
        staffPick: Bool,
        featured: Bool,
        isFavorited: Bool?
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.kind = kind
        self.country = country
        self.genreTags = genreTags
        self.icon = icon
        self.staffPick = staffPick
        self.featured = featured
        self.isFavorited = isFavorited
    }
}

public struct CatalogDetail: Sendable {
    public let id: String
    public let name: String
    public let slug: String
    public let kind: String
    public let country: String
    public let city: String
    public let language: String
    public let overview: String
    public let editorialReview: String?
    public let homepage: String
    public let genreTags: [String]
    public let formatTags: [String]
    public let icon: CatalogIcon?
    public let staffPick: Bool
    public let featured: Bool
    public let isFavorited: Bool?

    public init(
        id: String,
        name: String,
        slug: String,
        kind: String,
        country: String,
        city: String,
        language: String,
        overview: String,
        editorialReview: String?,
        homepage: String,
        genreTags: [String],
        formatTags: [String],
        icon: CatalogIcon?,
        staffPick: Bool,
        featured: Bool,
        isFavorited: Bool?
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.kind = kind
        self.country = country
        self.city = city
        self.language = language
        self.overview = overview
        self.editorialReview = editorialReview
        self.homepage = homepage
        self.genreTags = genreTags
        self.formatTags = formatTags
        self.icon = icon
        self.staffPick = staffPick
        self.featured = featured
        self.isFavorited = isFavorited
    }
}

public struct CatalogIcon: Sendable {
    public let url: String
    public let width: Int?
    public let height: Int?
    public let variants: [String: String]

    public init(url: String, width: Int?, height: Int?, variants: [String: String]) {
        self.url = url
        self.width = width
        self.height = height
        self.variants = variants
    }
}

public struct CatalogPage: Sendable {
    public let entries: [CatalogCard]
    public let total: Int
    public let limit: Int
    public let offset: Int

    public var hasMore: Bool { offset + entries.count < total }

    public init(entries: [CatalogCard], total: Int, limit: Int, offset: Int) {
        self.entries = entries
        self.total = total
        self.limit = limit
        self.offset = offset
    }
}

public struct AnonymousSessionToken: Sendable {
    public let token: String
    public let expiresAt: Date

    public init(token: String, expiresAt: Date) {
        self.token = token
        self.expiresAt = expiresAt
    }
}

// MARK: - Internal decoders

private let iso8601d = ISO8601DateFormatter()

// Decodes JSON responses with snake_case → camelCase key conversion.
let catalogJSONDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

struct CatalogCardJSON: Decodable {
    let id: String
    let name: String
    let slug: String
    let kind: String
    let country: String
    let genreTags: [String]
    let icon: CatalogIconJSON?
    let staffPick: Bool
    let featured: Bool
    let isFavorited: Bool?

    func toModel() -> CatalogCard {
        CatalogCard(
            id: id,
            name: name,
            slug: slug,
            kind: kind,
            country: country,
            genreTags: genreTags,
            icon: icon?.toModel(),
            staffPick: staffPick,
            featured: featured,
            isFavorited: isFavorited
        )
    }
}

struct CatalogIconJSON: Decodable {
    let url: String
    let width: Int?
    let height: Int?
    let variants: [String: String]?

    func toModel() -> CatalogIcon {
        CatalogIcon(url: url, width: width, height: height, variants: variants ?? [:])
    }
}

struct PaginatedCatalogCardCollectionJSON: Decodable {
    let data: [CatalogCardJSON]
    let total: Int
    let limit: Int
    let offset: Int

    func toModel() -> CatalogPage {
        CatalogPage(entries: data.map { $0.toModel() }, total: total, limit: limit, offset: offset)
    }
}

struct CatalogDetailJSON: Decodable {
    let id: String
    let name: String
    let slug: String
    let kind: String
    let country: String
    let city: String?
    let language: String?
    let overview: String
    let editorialReview: String?
    let homepage: String?
    let genreTags: [String]?
    let formatTags: [String]?
    let icon: CatalogIconJSON?
    let staffPick: Bool
    let featured: Bool
    let isFavorited: Bool?

    func toModel() -> CatalogDetail {
        CatalogDetail(
            id: id,
            name: name,
            slug: slug,
            kind: kind,
            country: country,
            city: city ?? "",
            language: language ?? "",
            overview: overview,
            editorialReview: editorialReview,
            homepage: homepage ?? "",
            genreTags: genreTags ?? [],
            formatTags: formatTags ?? [],
            icon: icon?.toModel(),
            staffPick: staffPick,
            featured: featured,
            isFavorited: isFavorited
        )
    }
}

struct AnonymousSessionJSON: Decodable {
    let token: String
    let expiresAt: String

    func toModel() throws -> AnonymousSessionToken {
        guard let date = iso8601d.date(from: expiresAt) else {
            throw CatalogAPIError.invalidResponse("unparseable expires_at")
        }
        return AnonymousSessionToken(token: token, expiresAt: date)
    }
}

// MARK: - Errors

public enum CatalogAPIError: Error, Sendable {
    case httpError(statusCode: Int, message: String?)
    case invalidResponse(String)
    case notFound
}
