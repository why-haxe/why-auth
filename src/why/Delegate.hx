package why;

import why.auth.Status;
import tink.state.*;

using tink.CoreApi;

interface Delegate<SignUpInfo, Credentials, Profile, ProfilePatch> {
	var status(default, null):Observable<Status<User<Profile, ProfilePatch>>>;
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