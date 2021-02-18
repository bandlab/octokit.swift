import RequestKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Review {
    public let body: String
    public let commitID: String
    public let id: Int
    public let state: State
    public let submittedAt: Date
    public let user: User
}

extension Review: Codable {
    enum CodingKeys: String, CodingKey {
        case body
        case commitID = "commit_id"
        case id
        case state = "state"
        case submittedAt = "submitted_at"
        case user
    }
}

extension Review {
    public enum State: String, Codable, Equatable {
        case approved = "APPROVED"
        case commented = "COMMENTED"
        case changesRequested = "CHANGES_REQUESTED"
        case dismissed = "DISMISSED"
        case pending = "PENDING"
    }
}

extension Octokit {
    @discardableResult
    public func listReviews(_ session: RequestKitURLSession = URLSession.shared,
                             owner: String,
                             repository: String,
                             pullRequestNumber: Int,
                             page: Int = 1,
                             perPage: Int = 100,
                             completion: @escaping (_ response: Response<[Review]>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = ReviewsRouter.listReviews(configuration, owner, repository, pullRequestNumber, page, perPage)
        return router.load(session, dateDecodingStrategy: .formatted(Time.rfc3339DateFormatter), expectedResultType: [Review].self) { pullRequests, error in
            if let error = error {
                completion(Response.failure(error))
            } else {
                if let pullRequests = pullRequests {
                    completion(Response.success(pullRequests))
                }
            }
        }
    }
}

enum ReviewsRouter: JSONPostRouter {
    case listReviews(Configuration, String, String, Int, Int, Int)

    var method: HTTPMethod {
        switch self {
        case .listReviews:
            return .GET
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        default:
            return .url
        }
    }

    var configuration: Configuration {
        switch self {
        case let .listReviews(config, _, _, _, _, _):
            return config
        }
    }

    var params: [String: Any] {
        switch self {
        case .listReviews(_, _, _, _, let page, let perPage):
            return ["page": String(page), "per_page": String(perPage)]
        }
    }

    var path: String {
        switch self {
        case let .listReviews(_, owner, repository, pullRequestNumber, _, _):
            return "/repos/\(owner)/\(repository)/pulls/\(pullRequestNumber)/reviews"
        }
    }
}
