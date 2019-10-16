package why.auth;

import haxe.Constraints;
import tink.state.*;
import why.Delegate;
import js.Browser.*;

using tink.CoreApi;

class Auth0Delegate extends DelegateBase<Credentials, Credentials, Auth0Profile, Auth0ProfilePatch> {
	var auth:WebAuth;
	var state:State<Status<User<Auth0Profile, Auth0ProfilePatch>>>;
	
	public function new(opt) {
		super(state = new State<Status<User<Auth0Profile, Auth0ProfilePatch>>>(Initializing));
		
		auth = new WebAuth({
			domain: opt.domain,
			clientID: opt.clientId,
			redirectUri: window.location.href,
			responseType: 'id_token',
			scope: 'openid email profile'
		});
		
		switch window.location.hash {
			case '':
				update();
			case hash:
				auth.parseHash({hash: hash}, function(err, data) {
					window.location.hash = '';
					update();
				});
		}
	}
	
	function update() {
		auth.checkSession({}, function(err, data) {
			console.log(data);
			if(err != null) {
				state.set(err.code == 'login_required' ? SignedOut : Errored(error(err)));
			} else {
				state.set(SignedIn(new Auth0User(data.idToken, data.idTokenPayload)));
			}
		});
	}
	
	override function signUp(credentials:Credentials):Promise<Noise> {
		return new Promise(function(resolve, reject) {
			auth.signupAndAuthorize({
				connection: 'Username-Password-Authentication',
				email: credentials.email,
				password: credentials.password,
			}, function(err, data) {
				if(err != null) {
					reject(error(err));
				} else {
					update();
					resolve(Noise);
				}
			});
		});
	}
	
	override function signIn(credentials:Credentials):Promise<Noise> {
		return new Promise(function(resolve, reject) {
			// never resolves because if successful the page will be redirected
			auth.login({
				realm: 'Username-Password-Authentication',
				email: credentials.email,
				password: credentials.password,
			}, function(err) if(err != null) reject(error(err)));
		});
	}
	
	override function signOut():Promise<Noise> {
		return new Promise(function(resolve, reject) {
			auth.logout({
				returnTo: window.location.origin,
			});
		});
	}
	
	override function forgetPassword(id:String):Promise<Noise> {
		return new Error(NotImplemented, 'Auth0Delegate#forgetPassword is not implemented');
	}
	
	override function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return new Error(NotImplemented, 'Auth0Delegate#resetPassword is not implemented');
	}
	
	override function confirmSignUp(id:String, code:String):Promise<Noise> {
		// the verification link will do the job
		return new Error('Auth0 does not support this API');
	}
	
	inline function error(err:Dynamic) {
		return Error.withData(500, err.description, err);
	}
	
}

private typedef Credentials = {
	email:String, 
	password:String,
}

class Auth0User implements User<Auth0Profile, Auth0ProfilePatch> {
	public var profile(default, null):Observable<Auth0Profile>;
	
	var token:String;
	
	public function new(token, payload) {
		this.token = token;
		profile = new State(payload); // TODO: update when needed
	}
	
	public function getToken():Promise<String> {
		return token;
	}
	
	public function updateProfile(patch:Auth0ProfilePatch):Promise<Noise> {
		return new Error(NotImplemented, 'Auth0User#updateProfile is not implemented');
	}
	
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> {
		return new Error(NotImplemented, 'Auth0User#changePassword is not implemented');
	}
	
}

typedef Auth0Profile = {
	sub:String,
	email:String,
	email_verified:Bool,
}
typedef Auth0ProfilePatch = {}

@:native('auth0.WebAuth')
extern class WebAuth {
	function new(opt:{});
	function parseHash(opt:{}, callback:Function):Void;
	function checkSession(opt:{}, callback:Function):Void;
	function signupAndAuthorize(opt:{}, callback:Function):Void;
	function login(opt:{}, callback:Function):Void;
	function logout(opt:{}):Void;
}
extern class Authentication {
	function userInfo(token:String, callback:Function):Void;
	
}