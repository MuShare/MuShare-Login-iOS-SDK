//
//  Pluto+Login.swift
//  Pluto
//
//  Created by Meng Li on 2019/11/01.
//  Copyright © 2018 MuShare. All rights reserved.
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

import Alamofire

extension Pluto {
    
    public func registerByEmail(address: String, password: String, name: String, success: @escaping () -> Void, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/register"),
            method: .post,
            parameters: [
                "mail": address,
                "password": password,
                "name": name
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON {
            let response = PlutoResponse($0)
            if response.statusOK() {
                success()
            } else {
                error?(response.errorCode())
            }
        }
    }
    
    public func resendValidationEmail(address: String, success: @escaping () -> Void, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/register/verify/mail"),
            method: .post,
            parameters: [
                "mail": address
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON {
            let response = PlutoResponse($0)
            if response.statusOK() {
                success()
            } else {
                error?(response.errorCode())
            }
        }
    }
    
    public func loginWithAccount(account: String, password: String, success: (() -> Void)? = nil, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/login/account"),
            method: .post,
            parameters: [
                "account": account,
                "password": password,
                "device_id": deviceId,
                "app_id": appId
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON { [weak self] in
            guard let `self` = self else {
                error?(PlutoError.unknown)
                return
            }
            self.handleLogin(response: PlutoResponse($0), success: success, error: error)
        }
    }
    public func loginWithGoogle(idToken: String, success: (() -> Void)? = nil, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/login/google/mobile"),
            method: .post,
            parameters: [
                "id_token": idToken,
                "device_id": deviceId,
                "app_id": appId
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON { [weak self] in
            guard let `self` = self else {
                error?(PlutoError.unknown)
                return
            }
            self.handleLogin(response: PlutoResponse($0), success: success, error: error)
        }
    }
    
    public func loginWithApple(authCode: String, name: String, success: (() -> Void)? = nil, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/login/apple/mobile"),
            method: .post,
            parameters: [
                "code": authCode,
                "name": name,
                "device_id": deviceId,
                "app_id": appId
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON { [weak self] in
            guard let `self` = self else {
                error?(PlutoError.unknown)
                return
            }
            self.handleLogin(response: PlutoResponse($0), success: success, error: error)
        }
    }
    
    public func resetPassword(address: String, success: @escaping () -> Void, error: ErrorCompletion? = nil) {
        AF.request(
            url(from: "/v1/user/password/reset/mail"),
            method: .post,
            parameters: [
                "mail": address
            ],
            encoding: JSONEncoding.default,
            headers: commonHeaders
        ).responseJSON {
            let response = PlutoResponse($0)
            if response.statusOK() {
                success()
            } else {
                error?(response.errorCode())
            }
        }
    }
    
    public func logout() {
        DefaultsManager.shared.clear()
        state = .notSignin
    }
    
    private func handleLogin(response: PlutoResponse, success: (() -> Void)?, error: ErrorCompletion?) {
        if response.statusOK() {
            let body = response.getBody()
            guard
                let refreshToken = body["refresh_token"].string,
                let accessToken = body["access_token"].string
            else {
                error?(PlutoError.parseError)
                return
            }
            DefaultsManager.shared.refreshToken = refreshToken
            guard DefaultsManager.shared.updateJwt(accessToken) else {
                error?(PlutoError.parseError)
                return
            }
            state = .signin
            success?()
        } else {
            error?(response.errorCode())
        }
    }
    
    public func binding(type: LoginType, authString: String, success: (() -> Void)? = nil, error: ErrorCompletion? = nil) {
        var parameters = [
            "type": type.identifier
        ]
        switch type {
        case .mail:
            parameters["mail"] = authString
        case .apple:
            parameters["code"] = authString
        case .google:
            parameters["id_token"] = authString
        }
        let requestUrl = url(from: "/v1/user/binding")
        getHeaders {
            AF.request(
                requestUrl,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: $0
            ).responseJSON {
                let response = PlutoResponse($0)
                if response.statusOK() {
                    success?()
                } else {
                    error?(response.errorCode())
                }
            }
        }
    }
    
    public func unbinding(type: LoginType, success: (() -> Void)? = nil, error: ErrorCompletion? = nil) {
        guard let bindings = avialiableBindings else {
            error?(PlutoError.notSignin)
            return
        }
        guard bindings.count > 1 else {
            error?(PlutoError.unbundNotAllow)
            return
        }
        let requestUrl = url(from: "/v1/user/unbinding")
        getHeaders {
            AF.request(
                requestUrl,
                method: .post,
                parameters: [
                    "type": type.identifier
                ],
                encoding: JSONEncoding.default,
                headers: $0
            ).responseJSON {
                let response = PlutoResponse($0)
                if response.statusOK() {
                    success?()
                } else {
                    error?(response.errorCode())
                }
            }
        }
    }
    
    public var avialiableLoginTypes: [Pluto.LoginType] {
        [.mail, .google, .apple]
        // TODO: Wechat login should be removed if wechat is not installed.
    }
    
    public var avialiableBindings: [PlutoUser.Binding]? {
        DefaultsManager.shared.user?.bindings.filter {
            avialiableLoginTypes.contains($0.loginType)
        }
    }
}
