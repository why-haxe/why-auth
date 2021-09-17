package why.auth;

import tink.state.*;
import why.Delegate;

using tink.CoreApi;

class DummyDelegate<SignUpInfo, Credentials, Profile, ProfilePatch> extends DelegateBase<SignUpInfo, Credentials, Profile, ProfilePatch> {
	var state:State<Status<User<Profile, ProfilePatch>>>;
	var credentials:Credentials;
	var getInfo:Credentials->Profile;
	var _getToken:Credentials->Promise<String>;
	
	public function new(getInfo, getToken, ?init) {
		super(state = new State<Status<User<Profile, ProfilePatch>>>(Initializing));
		
		this.credentials = init;
		this.getInfo = getInfo;
		this._getToken = getToken;
		update();
	}
	
	function update() {
		state.set(credentials == null ? SignedOut : SignedIn(new DummyUser(function() return _getToken(credentials), getInfo(credentials))));
	}
	
	override function signUp(info:SignUpInfo):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#signUp is not implemented');
	}
	
	override function signIn(credentials:Credentials):Promise<Noise> {
		this.credentials = credentials;
		update();
		return Promise.NOISE;
	}
	
	override function signOut():Promise<Noise> {
		credentials = null;
		update();
		return Promise.NOISE;
	}
	
	override function forgetPassword(id:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#forgetPassword is not implemented');
	}
	
	override function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#resetPassword is not implemented');
	}
	
	override function confirmSignUp(id:String, code:String):Promise<Noise> {
		return new Error(NotImplemented, 'DummyDelegate#confirmSignUp is not implemented');
	}
}

class DummyUser<Profile, ProfilePatch> implements User<Profile, ProfilePatch> {
	public final profile:Observable<Profile>;
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