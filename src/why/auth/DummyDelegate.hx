package why.auth;

import tink.state.*;
import why.Delegate;

using tink.CoreApi;

class DummyDelegate<SignUpInfo, Credentials, Profile, ProfilePatch> implements Delegate<SignUpInfo, Credentials, Profile, ProfilePatch> {
	public var status(default, null):Observable<Status<User<Profile, ProfilePatch>>>;
	
	var state:State<Status<User<Profile, ProfilePatch>>>;
	var credentials:Credentials;
	var getInfo:Credentials->Profile;
	var _getToken:Credentials->Promise<String>;
	
	public function new(getInfo, getToken, ?init) {
		this.credentials = init;
		this.getInfo = getInfo;
		this._getToken = getToken;
		state = new State<Status<User<Profile, ProfilePatch>>>(Initializing);
		status = state.observe();
		update();
	}
	
	function update() {
		state.set(credentials == null ? SignedOut : SignedIn(new DummyUser(function() return _getToken(credentials), getInfo(credentials))));
	}
	
	public function signUp(info:SignUpInfo):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#signUp is not implemented');
	}
	
	public function signIn(credentials:Credentials):Promise<Noise> {
		this.credentials = credentials;
		update();
		return Promise.NOISE;
	}
	
	public function signOut():Promise<Noise> {
		credentials = null;
		update();
		return Promise.NOISE;
	}
	
	public function getToken():Promise<Option<String>> {
		return credentials == null ? None : _getToken(credentials).next(Some);
	}
	
	public function forgetPassword(id:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#forgetPassword is not implemented');
	}
	
	public function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#resetPassword is not implemented');
	}
	
	public function confirmSignUp(id:String, code:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#confirmSignUp is not implemented');
	}
}

class DummyUser<Profile, ProfilePatch> implements User<Profile, ProfilePatch> {
	public var profile(default, null):Observable<Profile>;
	var _getToken:Void->Promise<String>;
	
	public function new(getToken, initProfile) {
		profile = new State(initProfile);
		_getToken = getToken;
	}
	
	public function getToken():Promise<String> {
		return _getToken();
	}
	
	public function updateProfile(patch:ProfilePatch):Promise<Noise> {
		return new Error(NotImplemented, 'DummyUser#confirmSignUp is not implemented');
	}
	
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyUser#confirmSignUp is not implemented');
	}
	
}