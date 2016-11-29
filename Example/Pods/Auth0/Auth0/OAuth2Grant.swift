// OAuth2Grant.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

protocol OAuth2Grant {
    var defaults: [String: String] { get }
    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> ())
    func values(fromComponents components: URLComponents) -> [String: String]
}

struct ImplicitGrant: OAuth2Grant {

    let defaults: [String : String] = ["response_type": "token"]

    func credentials(from values: [String : String], callback: @escaping (Result<Credentials>) -> ()) {
        guard let credentials = Credentials(json: values as [String : Any]) else {
            let data = try! JSONSerialization.data(withJSONObject: values, options: [])
            let string = String(data: data, encoding: .utf8)
            callback(.failure(error: AuthenticationError(string: string)))
            return
        }
        callback(.success(result: credentials))
    }

    func values(fromComponents components: URLComponents) -> [String : String] {
        return components.a0_fragmentValues
    }
}

struct PKCE: OAuth2Grant {

    let authentication: Authentication
    let redirectURL: URL
    let defaults: [String : String]
    let verifier: String

    init(authentication: Authentication, redirectURL: URL, generator: A0SHA256ChallengeGenerator = A0SHA256ChallengeGenerator()) {
        self.init(authentication: authentication, redirectURL: redirectURL, verifier: generator.verifier, challenge: generator.challenge, method: generator.method)
    }

    init(authentication: Authentication, redirectURL: URL, verifier: String, challenge: String, method: String) {
        self.authentication = authentication
        self.redirectURL = redirectURL
        self.defaults = [
            "response_type": "code",
            "code_challenge": challenge,
            "code_challenge_method": method,
        ]
        self.verifier = verifier
    }

    func credentials(from values: [String: String], callback: @escaping (Result<Credentials>) -> ()) {
        guard
            let code = values["code"]
            else {
                let data = try! JSONSerialization.data(withJSONObject: values, options: [])
                let string = String(data: data, encoding: .utf8)
                return callback(.failure(error: AuthenticationError(string: string)))
            }
        let clientId = self.authentication.clientId
        self.authentication
            .tokenExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectURL.absoluteString)
            .start { result in
                // FIXME: Special case for PKCE when the correct method for token endpoint authentication is not set (it should be None)
                if case .failure(let cause as AuthenticationError) = result , cause.description == "Unauthorized" {
                    let error = WebAuthError.pkceNotAllowed("Please go to 'https://manage.auth0.com/#/applications/\(clientId)/settings' and make sure 'Client Type' is 'Native' to enable PKCE.")
                    callback(Result.failure(error: error))
                } else {
                    callback(result)
                }
            }
    }

    func values(fromComponents components: URLComponents) -> [String : String] {
        var items = components.a0_fragmentValues
        components.a0_queryValues.forEach { items[$0] = $1 }
        return items
    }
}
