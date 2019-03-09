package why.auth;

import tink.state.*;

using tink.CoreApi;

private typedef SignInInfo = {
	username:String,
	password:String,
}

private typedef Config = {
	poolId:String,
	clientId:String,
}

private typedef UserInfo = Dynamic;

class CognitoDelegate implements Delegate<SignInInfo, UserInfo> {
	
	public var status(default, null):Observable<Status<UserInfo>>;
	
	var state:State<Status<UserInfo>>;
	var config:Config;
	
	public function new(config) {
		
		this.state = new State<Status<UserInfo>>(Initializing);
		this.status = state.observe();
		this.config = config;
	}
	
	public function signIn(credentials:SignInInfo):Promise<UserInfo> {
		
		return Future.async(function(cb) {
			
			var details = new AuthenticationDetails({
				Username: credentials.username,
				Password: credentials.password,
			});
			
			var pool = new CognitoUserPool({
				UserPoolId: config.poolId,
				ClientId: config.clientId,
			});
			
			var user = new CognitoUser({
				Username: credentials.username,
				Pool: pool,
			});
			
			
			var obj;
			
			obj = {
				onSuccess: function(result) {
					user.getSession(function(err, session) {
						// var token = session.getIdToken().getJwtToken();
						state.set(SignedIn(session));
						cb(Success(session));
					});
				},
				onFailure: function(err:js.Error) {
					var e = Error.ofJsError(err);
					state.set(Errored(e));
					cb(Failure(e));
				},
				newPasswordRequired: function(userAttrs, requiredAttrs) {
					user.completeNewPasswordChallenge(credentials.password, {}, obj);
				}
			}
			
			user.authenticateUser(details, obj);
		});
	}
	
	public function signOut():Promise<Noise> {
		return new Error(NotImplemented, 'not implemented');
		// return Promise.ofJsPromise(Auth.signOut());
	}
	
	public function getToken():Promise<Option<String>> {
		return status.getNext(null, function(s) return switch s {
			case SignedIn(session): Some(session);
			case _: None;
		}).next(function(session) return Some(session.idToken.jwtToken));
	}
}


@:jsRequire('amazon-cognito-identity-js-node', 'AuthenticationDetails')
private extern class AuthenticationDetails {
	function new(config:{});
}
@:jsRequire('amazon-cognito-identity-js-node', 'CognitoUserPool')
private extern class CognitoUserPool {
	function new(config:{});
}
@:jsRequire('amazon-cognito-identity-js-node', 'CognitoUser')
private extern class CognitoUser {
	function new(config:{});
	function authenticateUser(details:AuthenticationDetails, config:{}):Void;
	function completeNewPasswordChallenge(p:String, o:{}, cb:{}):Void;
	function getSession(cb:js.Error->Dynamic->Void):Void;
}