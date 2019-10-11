package why;

import why.auth.Status;
import tink.state.*;

using tink.CoreApi;

interface Delegate<SignUpInfo, Credentials, Profile, ProfilePatch> {
	var status(default, null):Observable<Status<User<Profile, ProfilePatch>>>;
	var profile(default, null):Observable<Option<Profile>>;
	function signUp(info:SignUpInfo):Promise<Noise>;
	function signIn(credentials:Credentials):Promise<Noise>;
	function signOut():Promise<Noise>;
	
	function forgetPassword(id:String):Promise<Noise>;
	function resetPassword(id:String, code:String, password:String):Promise<Noise>;
	function confirmSignUp(id:String, code:String):Promise<Noise>;
}

interface User<Profile, ProfilePatch> {
	var profile(default, null):Observable<Profile>;
	function getToken():Promise<String>;
	function updateProfile(patch:ProfilePatch):Promise<Noise>;
	function changePassword(oldPassword:String, newPassword:String):Promise<Noise>;
}

// TODO: abstract class
class DelegateBase<SignUpInfo, Credentials, Profile, ProfilePatch> implements Delegate<SignUpInfo, Credentials, Profile, ProfilePatch> {
	
	public var status(default, null):Observable<Status<User<Profile, ProfilePatch>>>;
	public var profile(default, null):Observable<Option<Profile>>;
	
	function new(status) {
		this.status = status;
		this.profile = Observable.create(() -> {
			var s = status.measure();
			switch s.value {
				case SignedIn(user):
					var p = user.profile.measure();
					new Measurement(Some(p.value), s.becameInvalid.first(p.becameInvalid));
				case _:
					new Measurement(None, s.becameInvalid);
			}
		});
	}
	
	public function signUp(info:SignUpInfo):Promise<Noise> throw 'abstract';
	public function signIn(credentials:Credentials):Promise<Noise> throw 'abstract';
	public function signOut():Promise<Noise> throw 'abstract';
	public function forgetPassword(id:String):Promise<Noise> throw 'abstract';
	public function resetPassword(id:String, code:String, password:String):Promise<Noise> throw 'abstract';
	public function confirmSignUp(id:String, code:String):Promise<Noise> throw 'abstract';
}